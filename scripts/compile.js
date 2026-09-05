#!/usr/bin/env node
// Offline compile gate: verifies every task's starter, tests and — when the
// task carries one — solution are valid AL by compiling them with the real AL
// compiler against the pinned symbol set in compiler/symbols/. A catalog that
// keeps its reference solutions in a private sibling has no solution/ here;
// then only the starter pairing is gated. Mirrors the platform's compile step:
//
//   1. the submission (starter or solution) is compiled as its own app
//      (app.json generated per compile, platform/application pinned);
//   2. the tests are compiled as a second app that depends on the compiled
//      submission .app — a second /packagecachepath, like the platform's
//      test/.alpackages folder.
//
// Success per compile = exit 0 AND out.app exists AND zero error-severity
// compiler diagnostics in the SARIF errorlog. Analyzer (cop) findings are
// surfaced but never fatal, matching platform semantics.
//
// Targets compile concurrently; each target's report is printed as one block
// when it finishes. Under GitHub Actions, diagnostics are also emitted as
// ::error/::warning annotations pointing at the real repo files.
//
// Usage:  node scripts/compile.js [task-id ...]   (default: all tasks + template)
// Env:    AL_EXE_PATH (compiler binary; default: `al` on PATH)
//         COMPILE_TIMEOUT_MS (per compile; default 120000)
//         COMPILE_CONCURRENCY (parallel targets; default: every core, max 4 —
//                              each al process holds ~1-1.5 GB of symbols, so
//                              memory, not cores, is the real ceiling)
'use strict';

const { execFile, spawnSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const util = require('util');
const zlib = require('zlib');

const execFileAsync = util.promisify(execFile);

const ROOT = path.resolve(__dirname, '..');
const TASKS_DIR = path.join(ROOT, 'tasks');
const SYMBOLS_DIR = path.join(ROOT, 'compiler', 'symbols');
const RULESET_PATH = path.join(ROOT, 'compiler', 'ruleset.json');
const COMPILE_TIMEOUT_MS = Number(process.env.COMPILE_TIMEOUT_MS) || 120000;
const COMPILE_CONCURRENCY = Number(process.env.COMPILE_CONCURRENCY)
  || Math.min(4, Math.max(1, os.availableParallelism ? os.availableParallelism() : 2));

// The platform's pinned BC version (symbols in compiler/symbols/ must match).
// BC 28 -> AL runtime 17.0, target Cloud. compiler/README.md lists every pin
// that has to move together when the BC version changes.
const PLATFORM_VERSION = '28.0.0.0';
const RUNTIME = '17.0';
const PUBLISHER = 'ALPractice';

// Resolved through app.json's platform/application properties (Application is
// the meta package that propagates Base Application, System Application and
// Business Foundation) — everything else in the cache becomes an explicit
// dependency of the test app.
const IMPLICIT_APPS = new Set(['System', 'Application', 'Base Application', 'System Application', 'Business Foundation']);

// IDs the generated manifests accept: the customization range.
const ID_RANGE = { from: 50000, to: 99999 };

const ANALYZER_DLLS = {
  CodeCop: 'Microsoft.Dynamics.Nav.CodeCop.dll',
  UICop: 'Microsoft.Dynamics.Nav.UICop.dll',
  PerTenantExtensionCop: 'Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll',
  AppSourceCop: 'Microsoft.Dynamics.Nav.AppSourceCop.dll',
};

// Analyzers are a platform-level choice, not a per-task one — every task's
// compile gate runs the same set. Cop findings are surfaced but never fatal.
const DEFAULT_ANALYZERS = ['CodeCop', 'UICop', 'PerTenantExtensionCop'];

// ---------------------------------------------------------------------------
// Symbol package manifests — a .app is a ZIP with a 40-byte NAVX prefix.
// Plain packages carry NavxManifest.xml; ready-to-run packages instead carry
// readytorunappmanifest.json describing the embedded app.

function readZipEntry(buf, wanted) {
  let eocd = -1;
  for (let i = buf.length - 22; i >= 0; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) return undefined;
  const cdActual = eocd - buf.readUInt32LE(eocd + 12);
  const prefixShift = cdActual - buf.readUInt32LE(eocd + 16);
  let pos = cdActual;
  while (pos < eocd && buf.readUInt32LE(pos) === 0x02014b50) {
    const method = buf.readUInt16LE(pos + 10);
    const compSize = buf.readUInt32LE(pos + 20);
    const nameLen = buf.readUInt16LE(pos + 28);
    const extraLen = buf.readUInt16LE(pos + 30);
    const commentLen = buf.readUInt16LE(pos + 32);
    const name = buf.toString('utf8', pos + 46, pos + 46 + nameLen);
    if (name === wanted) {
      const lh = buf.readUInt32LE(pos + 42) + prefixShift;
      const dataStart = lh + 30 + buf.readUInt16LE(lh + 26) + buf.readUInt16LE(lh + 28);
      const raw = buf.subarray(dataStart, dataStart + compSize);
      return method === 8 ? zlib.inflateRawSync(raw) : Buffer.from(raw);
    }
    pos += 46 + nameLen + extraLen + commentLen;
  }
  return undefined;
}

function readAppIdentity(appPath) {
  const buf = fs.readFileSync(appPath);
  const xml = readZipEntry(buf, 'NavxManifest.xml');
  if (xml) {
    const app = /<App\b[^>]*>/.exec(xml.toString('utf8'));
    if (!app) throw new Error('NavxManifest.xml has no <App> element');
    const attr = (n) => (new RegExp(`\\b${n}="([^"]*)"`).exec(app[0]) || [])[1];
    return { id: attr('Id'), name: attr('Name'), publisher: attr('Publisher'), version: attr('Version') };
  }
  const r2r = readZipEntry(buf, 'readytorunappmanifest.json');
  if (r2r) {
    const m = JSON.parse(r2r.toString('utf8'));
    return { id: m.EmbeddedAppId, name: m.EmbeddedAppName, publisher: m.EmbeddedAppPublisher, version: m.EmbeddedAppVersion };
  }
  throw new Error('no app manifest found');
}

function loadSymbolDependencies() {
  const deps = [];
  for (const f of fs.readdirSync(SYMBOLS_DIR).filter((f) => f.endsWith('.app'))) {
    const identity = readAppIdentity(path.join(SYMBOLS_DIR, f));
    if (!IMPLICIT_APPS.has(identity.name)) deps.push(identity);
  }
  return deps;
}

// ---------------------------------------------------------------------------
// Compiler and analyzer discovery

function findCompiler() {
  const candidates = [process.env.AL_EXE_PATH, 'al', 'AL'].filter(Boolean);
  for (const candidate of candidates) {
    const res = spawnSync(candidate, ['help'], { encoding: 'utf8', timeout: 30000 });
    if (!res.error || res.error.code !== 'ENOENT') return candidate;
  }
  console.error(
    'AL compiler not found. Install it with:\n' +
    `  dotnet tool install --global Microsoft.Dynamics.BusinessCentral.Development.Tools --version ${alToolVersion()}\n` +
    'or point AL_EXE_PATH at the al binary.'
  );
  process.exit(1);
}

function alToolVersion() {
  try {
    return JSON.parse(fs.readFileSync(path.join(ROOT, 'package.json'), 'utf8')).config.alToolVersion;
  } catch {
    return '<version>';
  }
}

// The cop DLLs ship inside the dotnet tool's store folder, next to the
// compiler implementation (not next to the `al` shim).
function findAnalyzerDir() {
  const roots = [path.join(os.homedir(), '.dotnet', 'tools')];
  if (process.env.AL_EXE_PATH) roots.unshift(path.dirname(process.env.AL_EXE_PATH));
  for (const root of roots) {
    const store = path.join(root, '.store', 'microsoft.dynamics.businesscentral.development.tools');
    if (!fs.existsSync(store)) continue;
    for (const version of fs.readdirSync(store).sort().reverse()) {
      const base = path.join(store, version, 'microsoft.dynamics.businesscentral.development.tools', version, 'tools');
      if (!fs.existsSync(base)) continue;
      for (const tfm of fs.readdirSync(base)) {
        const dir = path.join(base, tfm, 'any');
        if (fs.existsSync(path.join(dir, ANALYZER_DLLS.CodeCop))) return dir;
      }
    }
  }
  return undefined;
}

// ---------------------------------------------------------------------------
// Project generation

function writeProject(projectDir, sourceFiles, appJson) {
  const srcDir = path.join(projectDir, 'src');
  fs.mkdirSync(srcDir, { recursive: true });
  for (const file of sourceFiles) {
    fs.copyFileSync(file, path.join(srcDir, path.basename(file)));
  }
  fs.writeFileSync(path.join(projectDir, 'app.json'), JSON.stringify(appJson, null, 2));
}

function makeAppJson(name, idRanges, dependencies) {
  return {
    id: crypto.randomUUID(),
    name,
    publisher: PUBLISHER,
    version: '1.0.0.0',
    platform: PLATFORM_VERSION,
    application: PLATFORM_VERSION,
    idRanges,
    runtime: RUNTIME,
    target: 'Cloud',
    dependencies,
  };
}

// Basename -> repo-relative path (forward slashes), for GitHub annotations
// that must point at the real files, not the temp project copies.
function fileMapOf(sourceFiles) {
  const map = new Map();
  for (const file of sourceFiles) {
    map.set(path.basename(file), path.relative(ROOT, file).split(path.sep).join('/'));
  }
  return map;
}

// ---------------------------------------------------------------------------
// Compiling and diagnostics

// Compiler diagnostics fail the gate; analyzer (cop) findings are surfaced
// but never fatal, matching the platform. The errorlog says which is which
// via properties.category; the ALxxxx rule prefix is the fallback.
function isCompilerDiag(diag) {
  if (diag.category) return diag.category === 'Compiler';
  return !diag.ruleId || /^AL\d/.test(diag.ruleId);
}

function parseErrorlog(errlogPath) {
  const diags = [];
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(errlogPath, 'utf8'));
  } catch {
    return diags;
  }
  const fileOf = (uri) => (uri ? path.basename(decodeURIComponent(uri)) : '');

  // Legacy SARIF v0.2 (AL compiler's /errorlog format): top-level issues[].
  for (const issue of parsed.issues || []) {
    const target = (((issue.locations || [])[0] || {}).analysisTarget || [])[0] || {};
    const props = issue.properties || {};
    diags.push({
      ruleId: issue.ruleId || '',
      level: (props.severity || 'warning').toLowerCase(),
      category: props.category || '',
      message: issue.fullMessage || issue.shortMessage || '',
      file: fileOf(target.uri),
      line: (target.region && target.region.startLine) || 0,
    });
  }
  // SARIF v1/v2: runs[].results[].
  for (const run of parsed.runs || []) {
    for (const r of run.results || []) {
      const loc = (r.locations && r.locations[0]) || {};
      const physical = loc.physicalLocation || loc.resultFile || {};
      const uri = (physical.artifactLocation && physical.artifactLocation.uri) || physical.uri || '';
      const region = physical.region || {};
      diags.push({
        ruleId: r.ruleId || '',
        level: r.level || 'warning',
        category: (r.properties && r.properties.category) || '',
        message: typeof r.message === 'string' ? r.message : (r.message && r.message.text) || '',
        file: fileOf(uri),
        line: region.startLine || 0,
      });
    }
  }
  return diags;
}

async function runCompile(al, projectDir, packageCaches, analyzerPaths) {
  const outApp = path.join(projectDir, 'out.app');
  const errlog = path.join(projectDir, 'errorlog.json');
  const args = [
    'compile',
    `/project:${projectDir}`,
    ...packageCaches.map((c) => `/packagecachepath:${c}`),
    `/out:${outApp}`,
    `/errorlog:${errlog}`,
    ...analyzerPaths.map((a) => `/analyzer:${a}`),
    ...(fs.existsSync(RULESET_PATH) ? [`/ruleset:${RULESET_PATH}`] : []),
  ];

  let status = 0;
  let stdout = '';
  let timedOut = false;
  let spawnError;
  try {
    ({ stdout } = await execFileAsync(al, args, {
      encoding: 'utf8',
      timeout: COMPILE_TIMEOUT_MS,
      killSignal: 'SIGKILL',
      maxBuffer: 32 * 1024 * 1024,
    }));
  } catch (e) {
    stdout = e.stdout || '';
    if (e.killed) {
      timedOut = true;
    } else if (typeof e.code === 'number') {
      status = e.code;
    } else {
      spawnError = e;
    }
  }

  const diags = parseErrorlog(errlog);
  const errors = diags.filter((d) => d.level === 'error' && isCompilerDiag(d));
  const warnings = diags.filter((d) => !(d.level === 'error' && isCompilerDiag(d)));

  let failure;
  if (timedOut) {
    failure = `compiler timed out after ${COMPILE_TIMEOUT_MS} ms`;
  } else if (spawnError) {
    failure = `failed to run compiler: ${spawnError.message}`;
  } else if (status !== 0 || !fs.existsSync(outApp) || errors.length > 0) {
    failure = `exit code ${status}, ${errors.length} error(s)`;
  }
  return { failure, errors, warnings, stdout };
}

// GitHub Actions workflow-command annotations (escaping per the spec).
const escData = (s) => String(s).replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A');
const escProp = (s) => escData(s).replace(/:/g, '%3A').replace(/,/g, '%2C');

function annotation(kind, diag, fileMap) {
  const target = fileMap.get(diag.file);
  const where = target ? `file=${escProp(target)},line=${diag.line || 1},` : '';
  return `::${kind} ${where}title=AL compile gate::${escData(`${diag.ruleId} ${diag.message}`.trim())}`;
}

function reportCompile(out, label, result, fileMap) {
  const annotate = process.env.GITHUB_ACTIONS === 'true';
  // Render every diagnostic structurally, severity from its own level — so an
  // analyzer error (e.g. PTE0004) fails the gate AND still gets a clickable
  // ::error annotation instead of leaking through as a raw compiler stdout line.
  const emit = (d) => {
    const kind = d.level === 'error' ? 'error' : 'warning';
    const prefix = kind === 'error' ? 'error ' : '';
    out.push(`      ${prefix}${d.ruleId} ${d.file}:${d.line || '?'} ${d.message}`);
    if (annotate) out.push(annotation(kind, d, fileMap));
  };

  if (!result.failure) {
    const w = result.warnings.length;
    out.push(`  [${label}] OK${w ? ` (${w} analyzer/warning finding(s))` : ''}`);
    result.warnings.forEach(emit);
    return true;
  }

  out.push(`  [${label}] FAILED — ${result.failure}`);
  result.errors.forEach(emit);
  result.warnings.forEach(emit);
  if (result.errors.length === 0 && result.warnings.length === 0) {
    // No structured diagnostics at all (crash, timeout, bad invocation) — show
    // the compiler's own output instead.
    const tail = result.stdout.trim().split('\n').slice(-15).join('\n      ');
    if (tail) out.push(`      ${tail}`);
  }
  return false;
}

// ---------------------------------------------------------------------------

function alFilesIn(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter((f) => f.endsWith('.al')).map((f) => path.join(dir, f));
}

function starterFilesOf(taskDir) {
  const single = path.join(taskDir, 'starter.al');
  if (fs.existsSync(single)) return [single];
  return alFilesIn(path.join(taskDir, 'starter'));
}

async function compileTarget(ctx, label, taskDir, appNameBase) {
  const out = [`\n${label}`];
  const idRanges = [{ ...ID_RANGE }];

  const analyzerPaths = [];
  for (const name of DEFAULT_ANALYZERS) {
    if (!ANALYZER_DLLS[name]) continue;
    if (!ctx.analyzerDir) {
      warnOnce(ctx, out, 'analyzer DLLs not found under the dotnet tool store — skipping analyzers');
      continue;
    }
    const dll = path.join(ctx.analyzerDir, ANALYZER_DLLS[name]);
    if (fs.existsSync(dll)) {
      analyzerPaths.push(dll);
    } else {
      warnOnce(ctx, out, `analyzer ${name} not found at ${dll} — skipping it`);
    }
  }

  const work = fs.mkdtempSync(path.join(os.tmpdir(), 'tryal-compile-'));
  let ok = true;
  try {
    const solutionFiles = alFilesIn(path.join(taskDir, 'solution'));
    const solutionApp = makeAppJson(appNameBase, idRanges, []);
    const solutionDir = path.join(work, 'solution');
    let solutionResult = null;
    if (solutionFiles.length > 0) {
      writeProject(solutionDir, solutionFiles, solutionApp);
      solutionResult = await runCompile(ctx.al, solutionDir, [SYMBOLS_DIR], analyzerPaths);
      ok = reportCompile(out, 'solution', solutionResult, fileMapOf(solutionFiles)) && ok;
    } else {
      out.push('  [solution] skipped — no solution/ in this checkout');
    }

    const starterFiles = starterFilesOf(taskDir);
    const starterApp = makeAppJson(appNameBase, idRanges, []);
    const starterDir = path.join(work, 'starter');
    let starterResult = null;
    if (starterFiles.length > 0) {
      writeProject(starterDir, starterFiles, starterApp);
      starterResult = await runCompile(ctx.al, starterDir, [SYMBOLS_DIR], analyzerPaths);
      ok = reportCompile(out, 'starter', starterResult, fileMapOf(starterFiles)) && ok;
    }

    // The platform compiles the tests together with whatever is submitted, so
    // they must build against the unchanged starter as well as the solution —
    // a test that binds at compile time to a field the user is asked to add
    // makes the task open broken. Both pairings are gated here.
    const testFiles = alFilesIn(path.join(taskDir, 'tests'));
    const compileTestsAgainst = async (label, app, appDir) => {
      const testDeps = [
        ...ctx.symbolDeps,
        { id: app.id, name: app.name, publisher: app.publisher, version: app.version },
      ];
      const testsDir = path.join(work, `tests-${label}`);
      writeProject(testsDir, testFiles, makeAppJson(`${appNameBase}_Tests`, idRanges, testDeps));
      // Second package cache holds the compiled app the tests depend on —
      // same shape as the platform's test/.alpackages.
      const testsResult = await runCompile(ctx.al, testsDir, [SYMBOLS_DIR, appDir], []);
      return reportCompile(out, `tests vs ${label}`, testsResult, fileMapOf(testFiles));
    };
    if (testFiles.length > 0) {
      if (solutionResult !== null) {
        if (solutionResult.failure) {
          out.push('  [tests vs solution] skipped — the solution app they depend on did not compile');
        } else {
          ok = (await compileTestsAgainst('solution', solutionApp, solutionDir)) && ok;
        }
      }
      if (starterResult === null) {
        out.push('  [tests vs starter] skipped — no starter files');
      } else if (starterResult.failure) {
        out.push('  [tests vs starter] skipped — the starter app they depend on did not compile');
      } else {
        ok = (await compileTestsAgainst('starter', starterApp, starterDir)) && ok;
      }
    }
  } finally {
    fs.rmSync(work, { recursive: true, force: true });
  }
  console.log(out.join('\n'));
  return ok;
}

function warnOnce(ctx, out, message) {
  if (ctx.warned.has(message)) return;
  ctx.warned.add(message);
  out.push(`  WARN  ${message}`);
}

async function runPool(items, concurrency, worker) {
  const results = new Array(items.length);
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(concurrency, items.length) }, async () => {
      for (let i = next++; i < items.length; i = next++) {
        results[i] = await worker(items[i]);
      }
    })
  );
  return results;
}

async function main() {
  if (!fs.existsSync(SYMBOLS_DIR)) {
    console.error(`symbol cache not found at ${path.relative(ROOT, SYMBOLS_DIR)} — the compile gate needs the pinned BC symbols.`);
    process.exit(1);
  }

  const requested = process.argv.slice(2);
  const allTasks = fs.readdirSync(TASKS_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();

  let targets;
  if (requested.length > 0) {
    const unknown = requested.filter((id) => !allTasks.includes(id));
    if (unknown.length > 0) {
      console.error(`unknown task id(s): ${unknown.join(', ')}`);
      process.exit(1);
    }
    targets = requested.map((id) => ({ label: `tasks/${id}`, dir: path.join(TASKS_DIR, id), appName: `Task_${id}` }));
  } else {
    targets = allTasks.map((id) => ({ label: `tasks/${id}`, dir: path.join(TASKS_DIR, id), appName: `Task_${id}` }));
    const template = path.join(ROOT, 'templates', 'full_execution');
    if (fs.existsSync(template)) {
      targets.push({ label: 'templates/full_execution', dir: template, appName: 'Template_full_execution' });
    }
  }

  const ctx = {
    al: findCompiler(),
    analyzerDir: findAnalyzerDir(),
    symbolDeps: loadSymbolDependencies(),
    warned: new Set(),
  };
  console.log(`compiler: ${ctx.al}${ctx.analyzerDir ? `\nanalyzers: ${ctx.analyzerDir}` : ''}`);
  console.log(`concurrency: ${COMPILE_CONCURRENCY}`);

  const results = await runPool(targets, COMPILE_CONCURRENCY, (t) => compileTarget(ctx, t.label, t.dir, t.appName));
  const failed = results.filter((ok) => !ok).length;

  console.log(`\n${targets.length} target(s) compiled: ${failed === 0 ? 'all OK' : `${failed} FAILED`}.`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
