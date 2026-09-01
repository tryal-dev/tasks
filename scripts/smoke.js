#!/usr/bin/env node
// Grading smoke test: grades tasks against the real platform — the AL compiler
// plus a Business Central container — and asserts the two properties that make
// a task worth solving:
//
//   solution/  compiles AND every [Test] passes;
//   starter/   compiles AND at least one [Test] fails.
//
// The starter must reach the test phase: a starter that fails to compile also
// reports success=false, so checking `!success` alone would let a broken
// starter through. We require an execution result (one carrying test counts)
// with failed > 0.
//
// The runner holds the branch's files but the platform grades by task id
// against its own catalog, so each task is first uploaded to the platform's
// staging area (POST /tasks/stage, admin-only, in-memory and TTL'd). A staged
// task shadows the platform's committed copy, so what gets graded is the code
// in this checkout — including tasks the platform has never seen.
//
// Usage:  node scripts/smoke.js <task-id ...>
//         node scripts/smoke.js all
//         node scripts/smoke.js --changed <base-ref>
// Env:    PLATFORM_URL      host only, e.g. https://api.tryal.dev (no /api/v1)
//         PLATFORM_API_KEY  an admin alpract_* key
//         SMOKE_TIMEOUT_MS  per submission (default 900000)
//         SMOKE_STAGE_TTL_S staged-task lifetime (default 3600)
//         SMOKE_CONCURRENCY tasks graded at once (default 3 — the platform runs
//                           three execution workers, one per BC container;
//                           more than that only queues on the platform side)
//         SMOKE_INFRA_RETRIES extra attempts for a task whose run died in the
//                           grading infrastructure, not in its tests (default 1)
'use strict';

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const ROOT = path.resolve(__dirname, '..');
const TASKS_DIR = path.join(ROOT, 'tasks');
const POLL_INTERVAL_MS = 3000;
const POLL_TIMEOUT_MS = Number(process.env.SMOKE_TIMEOUT_MS) || 15 * 60 * 1000;
const STAGE_TTL_SECONDS = Number(process.env.SMOKE_STAGE_TTL_S) || 3600;
const CONCURRENCY = Math.max(1, Number(process.env.SMOKE_CONCURRENCY) || 3);
const INFRA_RETRIES = Math.max(0, Number(process.env.SMOKE_INFRA_RETRIES ?? 1));
const MAX_ATTEMPTS = 4;
const INFRA_FAILURE_MARK = 'grading infrastructure reported failure';

const baseUrl = (process.env.PLATFORM_URL || '').replace(/\/+$/, '');
const apiKey = process.env.PLATFORM_API_KEY || '';

function readDirFiles(dir) {
  if (!fs.existsSync(dir)) return {};
  const out = {};
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    if (fs.statSync(full).isFile()) out[name] = fs.readFileSync(full, 'utf8');
  }
  return out;
}

function alFilesOnly(files) {
  return Object.fromEntries(Object.entries(files).filter(([name]) => name.toLowerCase().endsWith('.al')));
}

// starter/ is the documented layout; a single starter.al beside it is the
// legacy shape the platform's loader still accepts.
function starterFilesOf(taskDir) {
  const single = path.join(taskDir, 'starter.al');
  if (fs.existsSync(single)) return { 'starter.al': fs.readFileSync(single, 'utf8') };
  return alFilesOnly(readDirFiles(path.join(taskDir, 'starter')));
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

class ApiError extends Error {
  constructor(status, body, message) {
    super(message);
    this.status = status;
    this.body = body;
  }
}

async function api(method, urlPath, body) {
  let lastError;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    let res;
    try {
      res = await fetch(`${baseUrl}${urlPath}`, {
        method,
        headers: {
          Authorization: `Bearer ${apiKey}`,
          ...(body ? { 'Content-Type': 'application/json' } : {}),
        },
        body: body ? JSON.stringify(body) : undefined,
      });
    } catch (e) {
      lastError = new Error(`${method} ${urlPath} -> ${e.message}`);
      if (attempt === MAX_ATTEMPTS) throw lastError;
      await sleep(2000 * attempt);
      continue;
    }

    if (res.ok) return res.json();

    const text = (await res.text()).slice(0, 800);
    // 429 carries Retry-After and 5xx is worth another try; anything else is a
    // contract error, and retrying only wastes platform capacity.
    if ((res.status === 429 || res.status >= 500) && attempt < MAX_ATTEMPTS) {
      const retryAfter = Number(res.headers.get('retry-after'));
      await sleep(Number.isFinite(retryAfter) && retryAfter > 0 ? retryAfter * 1000 : 5000 * attempt);
      lastError = new ApiError(res.status, text, `${method} ${urlPath} -> HTTP ${res.status}: ${text}`);
      continue;
    }
    throw new ApiError(res.status, text, `${method} ${urlPath} -> HTTP ${res.status}: ${text}`);
  }
  throw lastError;
}

async function stageTask(taskId, taskDir) {
  const metadata = yaml.load(fs.readFileSync(path.join(taskDir, 'metadata.yaml'), 'utf8'));
  const taskMd = path.join(taskDir, 'task.md');
  await api('POST', '/api/v1/tasks/stage', {
    id: taskId,
    metadata,
    description: fs.existsSync(taskMd) ? fs.readFileSync(taskMd, 'utf8') : undefined,
    starterFiles: starterFilesOf(taskDir),
    testFiles: alFilesOnly(readDirFiles(path.join(taskDir, 'tests'))),
    solutionFiles: alFilesOnly(readDirFiles(path.join(taskDir, 'solution'))),
    ttlSeconds: STAGE_TTL_SECONDS,
  });
  return metadata;
}

async function unstageTask(taskId, log) {
  try {
    await api('DELETE', `/api/v1/tasks/stage/${taskId}`);
  } catch (e) {
    // Best-effort: the stage expires on its own, so a failed cleanup must not
    // turn a passing task red.
    log(`  note: could not unstage ${taskId} (${e.message}); it expires in ${STAGE_TTL_SECONDS}s`);
  }
}

async function submitAndWait(taskId, files, label, log) {
  const { submissionId } = await api('POST', '/api/v1/submit', { taskId, files });
  log(`  [${label}] submitted as ${submissionId}`);

  const deadline = Date.now() + POLL_TIMEOUT_MS;
  let last = '';
  while (Date.now() < deadline) {
    const status = await api('GET', `/api/v1/submit/${submissionId}/status`);
    if (status.status !== last) {
      log(`  [${label}] ${status.status}${status.phase ? ` (${status.phase})` : ''}`);
      last = status.status;
    }
    if (status.status === 'completed') return status.result;
    if (status.status === 'failed') {
      throw new Error(`[${label}] ${INFRA_FAILURE_MARK}: ${status.error || 'no detail'}`);
    }
    await sleep(POLL_INTERVAL_MS);
  }
  throw new Error(`[${label}] timed out after ${POLL_TIMEOUT_MS / 1000}s waiting for ${submissionId}`);
}

// An execution result carries test counts; a compile result carries only
// diagnostics. Which one came back tells us how far the submission got.
function reachedTests(result) {
  return result && typeof result.total === 'number';
}

function describeResult(result) {
  if (reachedTests(result)) {
    return `success=${result.success}, tests: ${result.passed}/${result.total} passed, ${result.failed} failed, ${result.skipped} skipped`;
  }
  const errors = (result.diagnostics || []).filter((d) => d.severity === 'error');
  return `success=${result.success}, did not reach the tests, ${errors.length} compiler error(s)`;
}

function compilerErrorLines(result, limit = 10) {
  const errors = (result.diagnostics || []).filter((d) => d.severity === 'error');
  return errors.slice(0, limit).map((d) => {
    const where = d.file ? `${d.file}${d.line ? `(${d.line})` : ''}: ` : '';
    return `      ${where}${d.code || ''} ${d.message}`.trimEnd();
  });
}

function failedTestLines(result, limit = 10) {
  return (result.tests || [])
    .filter((t) => t.result === 'failed')
    .slice(0, limit)
    .map((t) => `      ${t.method || t.name}: ${(t.message || 'no message').split('\n')[0]}`);
}

async function smokeTask(taskId, log) {
  const taskDir = path.join(TASKS_DIR, taskId);
  const meta = await stageTask(taskId, taskDir);
  log(`${taskId} (${meta.executionTier}) — staged`);

  try {
    const solution = await submitAndWait(taskId, alFilesOnly(readDirFiles(path.join(taskDir, 'solution'))), 'solution', log);
    log(`  [solution] ${describeResult(solution)}`);
    if (!solution.success) {
      const detail = reachedTests(solution) ? failedTestLines(solution) : compilerErrorLines(solution);
      throw new Error(
        `[solution] the reference solution did not pass — the task is not provably solvable\n${detail.join('\n')}`,
      );
    }

    if (meta.executionTier !== 'full_execution') {
      log('  OK');
      return { taskId, solution, starter: null };
    }

    const starter = await submitAndWait(taskId, starterFilesOf(taskDir), 'starter', log);
    log(`  [starter] ${describeResult(starter)}`);

    // Checked before the red-tests assertion: a starter that cannot compile is
    // a broken starter, not a discriminating one.
    if (!reachedTests(starter)) {
      throw new Error(
        `[starter] the unchanged starter does not compile — users would open a task that is already broken\n${compilerErrorLines(starter).join('\n')}`,
      );
    }
    if (starter.success) {
      throw new Error(`[starter] the unchanged starter passes all ${starter.total} tests — the tests cannot discriminate`);
    }
    if (starter.failed === 0) {
      throw new Error(`[starter] no test failed on the unchanged starter (${starter.skipped} skipped of ${starter.total})`);
    }

    log('  OK');
    return { taskId, solution, starter };
  } finally {
    await unstageTask(taskId, log);
  }
}

// A task's lines are buffered and printed as one block when it finishes, so
// concurrently graded tasks never interleave in the log. Only the start/finish
// markers print immediately, as the live progress signal.
async function smokeTaskBuffered(taskId, index, total) {
  const lines = [];
  const log = (line) => lines.push(line);
  const flush = () => {
    console.log(`\n${lines.join('\n')}`);
    lines.length = 0;
  };
  console.log(`▶ ${taskId} (${index + 1}/${total})`);

  // A run that died in the grading infrastructure — a container OOM, a lost
  // WebSocket, a bcx timeout — says nothing about the task; it is retried. A
  // failed test or a compile error is a verdict and is never retried.
  for (let attempt = 0; ; attempt++) {
    try {
      const result = await smokeTask(taskId, log);
      flush();
      return result;
    } catch (e) {
      const infra = e.message.includes(INFRA_FAILURE_MARK);
      if (infra && attempt < INFRA_RETRIES) {
        log(`  retrying (${attempt + 1}/${INFRA_RETRIES}) — ${e.message.split('\n')[0]}`);
        continue;
      }
      flush();
      throw e;
    }
  }
}

async function runPool(items, concurrency, worker) {
  const results = new Array(items.length);
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(concurrency, items.length) }, async () => {
      while (next < items.length) {
        const i = next++;
        results[i] = await worker(items[i], i);
      }
    }),
  );
  return results;
}

function summaryRow(r) {
  const sol = reachedTests(r.solution) ? `${r.solution.passed}/${r.solution.total} passed` : 'compiled';
  const starter = r.starter ? `${r.starter.failed}/${r.starter.total} failed` : 'n/a';
  return `| \`${r.taskId}\` | ✅ | ${sol} | ${starter} |`;
}

function writeStepSummary(results, failures) {
  const file = process.env.GITHUB_STEP_SUMMARY;
  if (!file) return;
  const lines = ['## Grading smoke test', ''];
  if (results.length > 0) {
    lines.push('| Task | Result | Solution | Starter |', '| --- | --- | --- | --- |');
    for (const r of results) lines.push(summaryRow(r));
    lines.push('');
  }
  for (const f of failures) {
    lines.push(`### ❌ \`${f.taskId}\``, '', '```', f.message, '```', '');
  }
  if (failures.length === 0 && results.length > 0) {
    lines.push(`All ${results.length} task(s) graded green: solution passes every test, starter compiles and fails at least one.`);
  }
  fs.appendFileSync(file, lines.join('\n') + '\n');
}

function allTaskIds() {
  return fs.readdirSync(TASKS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();
}

function changedTaskIds(baseRef) {
  const out = execFileSync('git', ['diff', '--name-only', `${baseRef}...HEAD`, '--', 'tasks/'], { encoding: 'utf8' });
  const ids = new Set();
  for (const line of out.split('\n')) {
    const m = /^tasks\/([^/]+)\//.exec(line.trim());
    if (m && fs.existsSync(path.join(TASKS_DIR, m[1]))) ids.add(m[1]);
  }
  return [...ids].sort();
}

function resolveTargets(argv) {
  if (argv[0] === '--changed') return changedTaskIds(argv[1] || 'origin/main');
  if (argv.length === 1 && argv[0] === 'all') return allTaskIds();
  // Accept comma- and space-separated ids so a workflow_dispatch input can be
  // pasted in either shape.
  return [...new Set(argv.flatMap((a) => a.split(/[,\s]+/)).filter(Boolean))];
}

async function main() {
  const argv = process.argv.slice(2);
  const listOnly = argv.includes('--list');
  const taskIds = resolveTargets(argv.filter((a) => a !== '--list'));

  const unknown = taskIds.filter((id) => !fs.existsSync(path.join(TASKS_DIR, id)));
  if (unknown.length > 0) {
    console.error(`Unknown task id(s): ${unknown.join(', ')}`);
    process.exit(1);
  }

  // Resolve-only mode: lets a caller show and cap the plan before any grading
  // capacity is spent. Needs no credentials.
  if (listOnly) {
    console.log(taskIds.join('\n'));
    return;
  }

  if (taskIds.length === 0) {
    console.log('No task ids given — nothing to smoke test.');
    return;
  }
  if (!baseUrl || !apiKey) {
    console.error('PLATFORM_URL and PLATFORM_API_KEY must be set.');
    process.exit(1);
  }
  if (/\/api\/v\d/.test(baseUrl)) {
    console.error(`PLATFORM_URL must be the host only (no /api/v1 path) — got ${baseUrl}`);
    process.exit(1);
  }

  console.log(`Grading ${taskIds.length} task(s) against ${baseUrl}, ${CONCURRENCY} at a time`);

  const results = [];
  const failures = [];
  // Every full_execution grade occupies one BC container, and the platform has
  // exactly CONCURRENCY execution workers — so this many tasks in flight keeps
  // every container busy, and one more would only wait in the platform's queue.
  await runPool(taskIds, CONCURRENCY, async (taskId, index) => {
    try {
      results.push(await smokeTaskBuffered(taskId, index, taskIds.length));
    } catch (e) {
      failures.push({ taskId, message: e.message });
      console.error(`  FAIL ${e.message}`);
      if (process.env.GITHUB_ACTIONS) {
        console.log(`::error title=Grading failed: ${taskId}::${e.message.split('\n')[0]}`);
      }
    }
  });
  const byId = (a, b) => a.taskId.localeCompare(b.taskId);
  results.sort(byId);
  failures.sort(byId);

  console.log(`\n${results.length} passed, ${failures.length} failed.`);
  writeStepSummary(results, failures);
  process.exit(failures.length > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
