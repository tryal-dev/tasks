#!/usr/bin/env node
// Validates every task in tasks/ against the platform's format contract
// (schema/metadata.schema.json for metadata, CONTRIBUTING.md for the rest).
// Reports ALL findings, exits 1 on any error.
// No platform dependency — safe to run offline: `npm run lint`.
'use strict';

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const Ajv = require('ajv');

const ROOT = path.resolve(__dirname, '..');
const TASKS_DIR = path.join(ROOT, 'tasks');

// Platform submission limits (defaults; env-tunable on the platform side —
// treat as the budget every starter and solution must fit).
const MAX_FILES = 6;
const MAX_FILE_BYTES = 70 * 1024;

const EXPECTED_ENTRIES = new Set(['metadata.yaml', 'task.md', 'starter', 'tests', 'solution']);

const findings = []; // { task, level: 'error'|'warn', message }

function error(task, message) {
  findings.push({ task, level: 'error', message });
}

function warn(task, message) {
  findings.push({ task, level: 'warn', message });
}

function isDir(p) {
  return fs.existsSync(p) && fs.statSync(p).isDirectory();
}

function isFile(p) {
  return fs.existsSync(p) && fs.statSync(p).isFile();
}

// Returns the .al files of a directory (non-recursive: submissions require
// single-segment filenames, so nested directories are a contract violation).
function collectAlDir(taskId, dir, label) {
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      error(taskId, `${label}/${entry.name} is a directory — submission filenames are single-segment, no nesting`);
    } else if (!entry.name.endsWith('.al')) {
      error(taskId, `${label}/${entry.name}: only .al files are allowed`);
    } else {
      files.push(path.join(dir, entry.name));
    }
  }
  return files;
}

function checkSubmissionLimits(taskId, files, label) {
  if (files.length > MAX_FILES) {
    error(taskId, `${label} has ${files.length} files — submissions are limited to ${MAX_FILES}`);
  }
  for (const file of files) {
    const size = fs.statSync(file).size;
    if (size > MAX_FILE_BYTES) {
      error(taskId, `${label}/${path.basename(file)} is ${size} bytes — the per-file limit is ${MAX_FILE_BYTES} (70 KB)`);
    }
    if (size === 0) {
      warn(taskId, `${label}/${path.basename(file)} is empty`);
    }
  }
}

function loadYaml(taskId, filePath, label) {
  try {
    return yaml.load(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    error(taskId, `${label} is not valid YAML: ${e.message.split('\n')[0]}`);
    return undefined;
  }
}

function unusedSortIdHint(sortIds) {
  return sortIds.nextFree === null
    ? ` (this catalog's range ${sortIds.min}–${sortIds.max} is exhausted)`
    : ` (an unused one is ${sortIds.nextFree})`;
}

function formatAjvError(err, sortIds) {
  const where = err.instancePath ? err.instancePath.replace(/^\//, '').replace(/\//g, '.') : '(root)';
  if (err.keyword === 'additionalProperties') {
    return `${where}: unknown field "${err.params.additionalProperty}" (the platform validates strictly and rejects unknown fields)`;
  }
  if (err.keyword === 'required' && err.params.missingProperty === 'sortId') {
    return `sortId is missing — every task carries an integer sortId, unique across every TryAL catalog; this catalog's range is ${sortIds.min}–${sortIds.max}${unusedSortIdHint(sortIds)}`;
  }
  if (err.instancePath === '/sortId' && (err.keyword === 'minimum' || err.keyword === 'maximum')) {
    return `sortId: must be within this catalog's range ${sortIds.min}–${sortIds.max} — every TryAL catalog owns a disjoint range so numbers stay unique across catalogs (see CONTRIBUTING.md)`;
  }
  if (err.schemaPath.includes('companyIsolation') && err.message === 'boolean schema is false') {
    return 'companyIsolation applies to full_execution tasks only — remove it';
  }
  return `${where}: ${err.message}`;
}

// First pass over every task's sortId, so a duplicate or missing one can be
// reported together with a number that is actually unused. Only numbers
// inside this catalog's range count towards the suggestion: an out-of-range
// one is a schema error on its own task and must not drag the suggestion out
// of the range as well. Unreadable metadata is skipped silently here —
// lintTask reports it.
function collectSortIds(taskIds, range) {
  const owners = new Map(); // sortId -> [taskId]
  let highest = range.min - 1;
  for (const taskId of taskIds) {
    const metaPath = path.join(TASKS_DIR, taskId, 'metadata.yaml');
    if (!isFile(metaPath)) continue;
    let meta;
    try {
      meta = yaml.load(fs.readFileSync(metaPath, 'utf8'));
    } catch {
      continue;
    }
    if (meta && typeof meta === 'object' && Number.isInteger(meta.sortId)) {
      if (!owners.has(meta.sortId)) owners.set(meta.sortId, []);
      owners.get(meta.sortId).push(taskId);
      if (meta.sortId >= range.min && meta.sortId <= range.max && meta.sortId > highest) highest = meta.sortId;
    }
  }
  const nextFree = highest + 1 <= range.max ? highest + 1 : null;
  return { owners, nextFree, min: range.min, max: range.max };
}

function lintTask(taskId, validate, topics, sortIds) {
  const taskDir = path.join(TASKS_DIR, taskId);

  for (const entry of fs.readdirSync(taskDir)) {
    if (!EXPECTED_ENTRIES.has(entry)) {
      warn(taskId, `unexpected entry "${entry}" — the format defines metadata.yaml, task.md, starter/, tests/, solution/`);
    }
  }

  // --- metadata.yaml ---
  let meta;
  const metaPath = path.join(taskDir, 'metadata.yaml');
  if (!isFile(metaPath)) {
    error(taskId, 'metadata.yaml is missing');
  } else {
    meta = loadYaml(taskId, metaPath, 'metadata.yaml');
    if (meta !== undefined && (typeof meta !== 'object' || meta === null || Array.isArray(meta))) {
      error(taskId, 'metadata.yaml must be a YAML mapping');
      meta = undefined;
    }
  }

  if (meta) {
    if (!validate(meta)) {
      // 'if' errors are ajv wrapper noise — the failing subschema errors are
      // reported alongside them.
      for (const err of validate.errors.filter((e) => e.keyword !== 'if')) {
        error(taskId, `metadata.yaml: ${formatAjvError(err, sortIds)}`);
      }
    }

    if (Number.isInteger(meta.sortId)) {
      const others = (sortIds.owners.get(meta.sortId) || []).filter((t) => t !== taskId);
      if (others.length > 0) {
        error(taskId, `metadata.yaml: sortId ${meta.sortId} is already used by ${others.join(', ')} — sortId is unique across the catalog${unusedSortIdHint(sortIds)}`);
      }
    }

    // Repo policy (not the platform format): compile_only proves too little —
    // an empty-but-compiling file passes — so the catalog is full_execution
    // only for now. Revisit if a compelling compile_only use case appears.
    if (meta.executionTier === 'compile_only') {
      error(taskId, 'metadata.yaml: executionTier "compile_only" is not accepted in this catalog for now — author the task as full_execution with grading tests (see CONTRIBUTING.md)');
    }

    if (meta.id !== undefined && meta.id !== taskId) {
      error(taskId, `metadata.yaml: id "${meta.id}" does not match the directory name (the directory name IS the task id)`);
    }
    if (typeof meta.topic === 'string' && topics && !(meta.topic in topics)) {
      error(taskId, `metadata.yaml: topic "${meta.topic}" is not defined in topics.yaml (known: ${Object.keys(topics).join(', ')})`);
    }
    // Repo policy: ids are <topic>-<slug> so the prefix can't drift from
    // the topic field.
    if (typeof meta.topic === 'string' && typeof meta.id === 'string'
      && !meta.id.startsWith(`${meta.topic}-`)) {
      error(taskId, `metadata.yaml: id "${meta.id}" does not start with its topic — task ids are <topic>-<slug>, so it should be "${meta.topic}-<slug>"`);
    }
    for (const field of ['bcVersion', 'runtime', 'target']) {
      if (meta[field] !== undefined) {
        warn(taskId, `metadata.yaml: "${field}" is set — the contract says omit it unless this is a deliberate exception (leave a note in the PR)`);
      }
    }
  }

  // --- task.md ---
  const taskMd = path.join(taskDir, 'task.md');
  if (!isFile(taskMd)) {
    error(taskId, 'task.md is missing');
  } else if (fs.readFileSync(taskMd, 'utf8').trim() === '') {
    error(taskId, 'task.md is empty');
  }

  // --- starter/ ---
  // Repo policy: only the directory form (as in templates/full_execution).
  // A flat starter.al also works on the platform, but one shape keeps the
  // catalog uniform and file names meaningful.
  const starterFile = path.join(taskDir, 'starter.al');
  const starterDir = path.join(taskDir, 'starter');
  let starterFiles = [];
  if (isFile(starterFile)) {
    error(taskId, 'flat starter.al is not accepted — move it to starter/<ObjectName>.<ObjectType>.al (see templates/full_execution)');
  }
  if (isDir(starterDir)) {
    starterFiles = collectAlDir(taskId, starterDir, 'starter');
    if (starterFiles.length === 0) {
      error(taskId, 'starter/ contains no .al files');
    }
  } else if (!isFile(starterFile)) {
    error(taskId, 'starter/ is missing');
  }
  checkSubmissionLimits(taskId, starterFiles, 'starter');

  // --- solution/ ---
  const solutionDir = path.join(taskDir, 'solution');
  let solutionFiles = [];
  if (!isDir(solutionDir)) {
    error(taskId, 'solution/ is missing — the reference solution is the proof the task is solvable');
  } else {
    solutionFiles = collectAlDir(taskId, solutionDir, 'solution');
    if (solutionFiles.length === 0) {
      error(taskId, 'solution/ contains no .al files');
    }
    checkSubmissionLimits(taskId, solutionFiles, 'solution');
  }

  // --- tests/ ---
  const testsDir = path.join(taskDir, 'tests');
  const testFiles = isDir(testsDir) ? collectAlDir(taskId, testsDir, 'tests') : [];
  if (meta) {
    if (meta.executionTier === 'full_execution' && testFiles.length === 0) {
      error(taskId, 'full_execution requires at least one test codeunit in tests/');
    }
    if (meta.executionTier === 'compile_only' && isDir(testsDir)) {
      warn(taskId, 'tests/ is present but the task is compile_only — tests will not grade anything');
    }

    // A task that grades in its own throwaway company costs ~17 s a run and is
    // locked out of the warm one, so the declaration has to be earned: something
    // in the graded run must actually commit. Codeunit.Run with its return value
    // captured commits implicitly, and so do the platform APIs that commit on
    // your behalf before handing work off — Email.Send commits before it calls
    // the connector, TaskScheduler/StartSession run outside the transaction.
    // Standard posting (Sales-Post, Purch.-Post, the journal posting batches,
    // transfer/assembly posting, undo, blanket-to-order, and the Library - X
    // helpers around them) commits on its own too — but a test method carrying
    // [CommitBehavior(CommitBehavior::Ignore)] silences those explicit commits for
    // its whole call tree, which is the rollback-safe way to grade posting.
    const testSources = testFiles.map((f) => fs.readFileSync(f, 'utf8'));
    const solutionSources = solutionFiles.map((f) => fs.readFileSync(f, 'utf8'));
    const al = [...testSources, ...solutionSources];
    const hardCommits = [
      /\bif\s+[\w".]+\.Run\s*\(/,
      /\b(?:Email\.(?:Send|Enqueue)|TaskScheduler\.CreateTask|StartSession)\s*\(/,
    ];
    const postingCalls = [
      // The "-Post Line" journal codeunits never commit; only the batch posters do
      // (Library - ERM's PostGeneralJnlLine runs the batch poster — proven on the platform).
      /"(?:Sales-Post|Purch\.-Post|Gen\. Jnl\.-Post(?: Batch)?|Item Jnl\.-Post(?: Batch)?|Assembly-Post|TransferOrder-Post (?:Shipment|Receipt|Transfer)|Undo [\w. ]+ Line|Blanket (?:Sales|Purch\.) Order to Order)"/,
      /\bLibrary\w+\.(?:Post\w*|Undo\w*|BlanketSalesOrderMakeOrder|BlanketPurchaseOrderMakeOrder)\s*\(/,
    ];
    const literalCommit = /\bCommit\s*\(/;
    // Either silences a posting routine's own commits: the attribute for the
    // whole call tree of a test method, SetSuppressCommit for that codeunit run.
    const ignoresCommits = /\[\s*CommitBehavior\s*\(\s*CommitBehavior::Ignore\s*\)\s*\]|\bSetSuppressCommit\s*\(\s*true\s*\)/;
    const matchesAny = (sources, res) => sources.some((src) => res.some((re) => re.test(src)));

    if (meta.transactionModel === 'committed' || meta.companyIsolation === 'fresh') {
      if (!matchesAny(al, [literalCommit, ...hardCommits, ...postingCalls])) {
        const declared = [
          meta.transactionModel === 'committed' && 'transactionModel: committed',
          meta.companyIsolation === 'fresh' && 'companyIsolation: fresh',
        ].filter(Boolean).join(' + ');
        warn(taskId, `metadata.yaml: ${declared}, but nothing in tests/ or solution/ commits — a rollback-safe task should declare auto_rollback + reuse (see CONTRIBUTING.md)`);
      }
    } else {
      if (matchesAny(al, postingCalls) && !al.some((src) => ignoresCommits.test(src))) {
        warn(taskId, 'tests/ or solution/ drive standard posting, which commits, but the task is auto_rollback and nothing silences those commits — put [CommitBehavior(CommitBehavior::Ignore)] on every posting test (or SetSuppressCommit(true) on the codeunit run), or declare committed + fresh (see CONTRIBUTING.md)');
      }
      if (testSources.some((src) => literalCommit.test(src))) {
        warn(taskId, 'tests/ call Commit() while the task is auto_rollback — it errors under AutoRollback and the platform falls back to a fresh company on a literal Commit; drop it (CommitBehavior::Ignore / a [TryFunction] wrapper) or declare committed + fresh');
      }
    }
  }
}

// Templates must stay valid against the schema, or every new task starts
// broken. Same checks as tasks minus id==dirname.
function lintTemplates(validate, topics, sortIds) {
  const templatesDir = path.join(ROOT, 'templates');
  if (!isDir(templatesDir)) return;
  for (const name of fs.readdirSync(templatesDir)) {
    const tplDir = path.join(templatesDir, name);
    if (!fs.statSync(tplDir).isDirectory()) continue;
    const label = `templates/${name}`;

    const metaPath = path.join(tplDir, 'metadata.yaml');
    if (!isFile(metaPath)) {
      error(label, 'metadata.yaml is missing');
      continue;
    }
    const meta = loadYaml(label, metaPath, 'metadata.yaml');
    if (!meta || typeof meta !== 'object') continue;

    if (!validate(meta)) {
      for (const err of validate.errors.filter((e) => e.keyword !== 'if')) {
        error(label, `metadata.yaml: ${formatAjvError(err, sortIds)}`);
      }
    }
    if (typeof meta.topic === 'string' && topics && !(meta.topic in topics)) {
      error(label, `metadata.yaml: topic "${meta.topic}" is not defined in topics.yaml`);
    }
    if (meta.executionTier !== name) {
      warn(label, `executionTier "${meta.executionTier}" does not match the template name`);
    }
    if (!isFile(path.join(tplDir, 'task.md'))) error(label, 'task.md is missing');
    if (!isDir(path.join(tplDir, 'starter'))) {
      error(label, 'starter/ is missing');
    }
    if (!isDir(path.join(tplDir, 'solution'))) error(label, 'solution/ is missing');
    if (name === 'full_execution' && !isDir(path.join(tplDir, 'tests'))) {
      error(label, 'tests/ is missing');
    }
  }
}

function displayName(task) {
  return task.includes('/') || task.startsWith('(') ? task : `tasks/${task}`;
}

function main() {
  if (!isDir(TASKS_DIR)) {
    console.error('tasks/ directory not found — run from the repo root.');
    process.exit(1);
  }

  const schema = JSON.parse(fs.readFileSync(path.join(ROOT, 'schema', 'metadata.schema.json'), 'utf8'));
  const ajv = new Ajv({ allErrors: true, strictTypes: false });
  const validate = ajv.compile(schema);

  // Each catalog owns a disjoint sortId range, declared by its own schema, so
  // numbers stay unique across catalogs without any cross-repo check.
  const sortIdRange = { min: schema.properties.sortId.minimum, max: schema.properties.sortId.maximum };
  if (!Number.isInteger(sortIdRange.min) || !Number.isInteger(sortIdRange.max)) {
    console.error('schema/metadata.schema.json: properties.sortId needs an integer minimum and maximum — that pair is this catalog\'s sortId range.');
    process.exit(1);
  }

  let topics = loadYaml('(repo)', path.join(ROOT, 'topics.yaml'), 'topics.yaml');
  if (topics !== undefined && (typeof topics !== 'object' || topics === null || Array.isArray(topics))) {
    error('(repo)', 'topics.yaml must be a mapping of topic id -> display name');
    topics = undefined;
  }

  const taskIds = fs.readdirSync(TASKS_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();

  const sortIds = collectSortIds(taskIds, sortIdRange);
  for (const taskId of taskIds) {
    lintTask(taskId, validate, topics, sortIds);
  }
  lintTemplates(validate, topics, sortIds);

  const errors = findings.filter((f) => f.level === 'error');
  const warnings = findings.filter((f) => f.level === 'warn');

  let lastTask = null;
  for (const f of findings) {
    if (f.task !== lastTask) {
      console.log(`\n${displayName(f.task)}`);
      lastTask = f.task;
    }
    console.log(`  ${f.level === 'error' ? 'ERROR' : 'WARN '}  ${f.message}`);
  }

  console.log(`\n${taskIds.length} task(s) checked: ${errors.length} error(s), ${warnings.length} warning(s).`);
  process.exit(errors.length > 0 ? 1 : 0);
}

main();
