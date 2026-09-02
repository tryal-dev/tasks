export const meta = {
  name: 'create-tasks-from-ideas',
  description: 'Author catalog tasks from ideas.md entries in parallel, each following the create-task skill, with adversarial review and repo-wide lint rounds',
  whenToUse: 'When entries from ideas.md should become real tasks. Pass args = { ideas: [{id, title, difficulty, text}] } with verbatim ideas.md entries for not-yet-created tasks.',
  phases: [
    { title: 'Create', detail: 'one author agent per idea, per-task compile gate' },
    { title: 'Review', detail: 'adversarial review against the create-task skill bar' },
    { title: 'Fix', detail: 'apply confirmed blockers, recompile' },
    { title: 'Lint', detail: 'repo-wide lint after all tasks land, up to 3 fix rounds' },
  ],
}

const input = typeof args === 'string' ? JSON.parse(args) : (args || {})
// Agents inherit the session's working directory, so the catalog is whichever
// repo the workflow was launched from. repoRoot only changes how the prompts
// name it — pass it when the wording would otherwise be ambiguous.
const REPO = input.repoRoot || 'the repository you are running in (the session working directory)'
const ideas = input.ideas || []
if (!ideas.length) throw new Error('args.ideas is required: [{id, title, difficulty, text}, ...]')

const CREATE_SCHEMA = {
  type: 'object',
  required: ['taskId', 'status', 'compiled', 'testCount', 'notes'],
  properties: {
    taskId: { type: 'string' },
    status: { enum: ['created', 'failed'] },
    compiled: { type: 'boolean' },
    testCount: { type: 'integer' },
    notes: { type: 'string' },
  },
}

const REVIEW_SCHEMA = {
  type: 'object',
  required: ['taskId', 'blockers', 'improvements'],
  properties: {
    taskId: { type: 'string' },
    blockers: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'issue', 'fix'],
        properties: {
          file: { type: 'string' },
          issue: { type: 'string' },
          fix: { type: 'string' },
        },
      },
    },
    improvements: { type: 'array', items: { type: 'string' } },
  },
}

const FIX_SCHEMA = {
  type: 'object',
  required: ['taskId', 'applied', 'skipped', 'compiled'],
  properties: {
    taskId: { type: 'string' },
    applied: { type: 'array', items: { type: 'string' } },
    skipped: { type: 'array', items: { type: 'string' } },
    compiled: { type: 'boolean' },
  },
}

const SORT_ID_SCHEMA = {
  type: 'object',
  required: ['maxSortId'],
  properties: {
    maxSortId: { type: 'integer' },
  },
}

const LINT_SCHEMA = {
  type: 'object',
  required: ['clean', 'errors'],
  properties: {
    clean: { type: 'boolean' },
    errors: {
      type: 'array',
      items: {
        type: 'object',
        required: ['taskId', 'message'],
        properties: {
          taskId: { type: 'string' },
          message: { type: 'string' },
        },
      },
    },
  },
}

function maxSortIdPrompt() {
  return [
    'In ' + REPO + ' find the highest sortId declared across tasks/*/metadata.yaml (each file has one top-level "sortId: <integer>" line; e.g. grep -h "^sortId:" tasks/*/metadata.yaml).',
    'Do not edit any file, do not run npm run lint or any git command.',
    'Return structured output: maxSortId (0 if no task declares one).',
  ].join('\n')
}

function createPrompt(idea, sortId) {
  return [
    'You are authoring a new practice task for the TryAL catalog, in ' + REPO + '. Every path below is relative to the repo root; on Windows prefer forward slashes.',
    '',
    'MANDATORY reading before you write a single file, in this order:',
    '1. .claude/skills/create-task/SKILL.md - the authoring skill. Follow its workflow exactly, including designing the grading tests before writing any code.',
    '2. .claude/skills/create-task/references/al-testing.md and .claude/skills/create-task/references/test-libraries.md',
    '3. CONTRIBUTING.md (metadata.yaml field reference)',
    '4. Model tasks: tasks/basics-add-table-field, and if a task in your topic already exists under tasks/, read it too; otherwise tasks/filtering-hostile-names is a good codeunit-shaped model.',
    '',
    'Your assigned idea, verbatim from ideas.md:',
    '---',
    idea.text,
    '---',
    'Task id (= directory name = metadata.yaml id): ' + idea.id + '. Difficulty: ' + idea.difficulty + '.',
    'metadata.yaml sortId: ' + sortId + ' - assigned by the orchestrator so the tasks being authored in parallel never collide. Set exactly this value; never compute your own from the catalog.',
    '',
    'Scaffold by copying templates/full_execution to tasks/' + idea.id + ', then write task.md, tests/, solution/, the starter, and metadata.yaml per the skill.',
    'House convention for task.md: one line per paragraph or list item - never hard-wrap prose.',
    '',
    'Verification you MUST run and pass: from the repo root, COMPILE_CONCURRENCY=2 node scripts/compile.js ' + idea.id + ' (bash syntax; other agents compile concurrently, keep concurrency at 2). Iterate until starter, solution and tests all compile with zero error-severity diagnostics. Analyzer (cop) warnings are surfaced but acceptable.',
    '',
    'Hard constraints:',
    '- Other agents are creating OTHER tasks in this same repo right now. Create and modify files ONLY inside tasks/' + idea.id + '. Never run "npm run lint" (it scans the whole repo and will see their half-written work). Never edit ideas.md, topics.yaml, templates/, or any shared file. Never run any git command.',
    '- Comments in code only for non-obvious whys; never restate what the code says.',
    '',
    'Return structured output: taskId, status (created|failed), compiled (did the per-task compile gate pass), testCount (number of [Test] procedures), notes (design decisions a reviewer should know, plus anything you could not verify - e.g. actual grading runs are not possible locally).',
  ].join('\n')
}

function reviewPrompt(idea) {
  return [
    'You are an adversarial reviewer of a newly-authored practice task in ' + REPO + '. The task: tasks/' + idea.id + ' ("' + idea.title + '", ' + idea.difficulty + ').',
    '',
    'First read .claude/skills/create-task/SKILL.md and both files in .claude/skills/create-task/references/ - they define the quality bar. Then read every file in tasks/' + idea.id + '.',
    '',
    'The original idea this task implements, verbatim from ideas.md:',
    '---',
    idea.text,
    '---',
    '',
    'Hunt for violations, most damaging first:',
    '- Contract: a promise in task.md with no test enforcing it, or a test asserting something a user could not predict from task.md.',
    '- Discrimination: could a lazy or wrong solution pass? Could the unchanged starter pass? Would hardcoding a constant or pattern-matching the examples pass (is there a generated-input or second-case test)?',
    '- Craft: user objects referenced by literal ID instead of name; missing explicit [TransactionModel] on any test; failure messages that hide the actual value; tests depending on each other, on Today, on demo data, or on locale; leftover template HTML comments; the metadata gotchas listed in the skill.',
    '- Scaffolding gradient: for a non-basics task the statement or hints must not hand over the winning mechanism or paste-ready solution code; for basics, known invisible dead-ends must be called out. The contract itself (names, signatures, graded outcomes) must be complete at every difficulty.',
    '',
    'Verify every suspicion by reading the actual code before reporting it. Do NOT edit any file. Do NOT run npm run lint or any git command.',
    '',
    'Return structured output: taskId, blockers (only findings that would let a wrong submission pass, fail a correct one, or break a lint/skill rule - each with file, issue, fix), improvements (everything else, as short strings).',
  ].join('\n')
}

function fixPrompt(idea, blockers) {
  return [
    'Apply confirmed review findings to the practice task tasks/' + idea.id + ' in ' + REPO + '.',
    '',
    'First read .claude/skills/create-task/SKILL.md (the quality bar), then the task files, then apply these blockers:',
    JSON.stringify(blockers, null, 2),
    '',
    'If you can verify a finding is actually wrong, skip it and say why. Modify files ONLY inside tasks/' + idea.id + '. After fixing, re-run from the repo root: COMPILE_CONCURRENCY=2 node scripts/compile.js ' + idea.id + ' and iterate until clean. Never run "npm run lint" or any git command.',
    '',
    'Return structured output: taskId, applied, skipped, compiled.',
  ].join('\n')
}

function lintPrompt(round) {
  return [
    'In ' + REPO + ' run: npm run lint',
    'This is lint round ' + round + '. Report results without fixing anything - do not edit files, do not run other commands.',
    'clean = the lint exited 0 with no errors. For each reported problem, attribute it to the task id whose files it concerns (the directory name under tasks/), or "shared" if it is not about one task.',
    'Return structured output: clean, errors [{taskId, message}].',
  ].join('\n')
}

function lintFixPrompt(taskId, messages, sortId) {
  return [
    'The repo-wide lint (npm run lint) in ' + REPO + ' reported these errors for the task tasks/' + taskId + ':',
    messages.map(m => '- ' + m).join('\n'),
    '',
    'Read .claude/skills/create-task/SKILL.md and CONTRIBUTING.md if needed, fix the errors, touching ONLY files inside tasks/' + taskId + '. If the fix could affect compilation, re-run: COMPILE_CONCURRENCY=2 node scripts/compile.js ' + taskId + '. No git commands.',
    'If an error concerns sortId, set it to exactly ' + sortId + ' (this task\'s assigned number) - not the number the lint message suggests, which other fixers running in parallel would take too.',
    'Return a short summary of what you changed.',
  ].join('\n')
}

log('Creating ' + ideas.length + ' tasks: ' + ideas.map(i => i.id).join(', '))

// sortId is unique across the catalog and the authors run in parallel, so
// they must not each derive "highest + 1" from a catalog the others are
// writing to — the orchestrator reads the base once and hands out numbers.
const base = await agent(maxSortIdPrompt(), { label: 'sortid:base', phase: 'Create', schema: SORT_ID_SCHEMA, effort: 'low' })
if (!base || !Number.isInteger(base.maxSortId)) throw new Error('could not determine the highest existing sortId')
const sortIds = Object.fromEntries(ideas.map((idea, i) => [idea.id, base.maxSortId + 1 + i]))
log('sortIds: ' + ideas.map(i => i.id + '=' + sortIds[i.id]).join(', '))

const results = await pipeline(
  ideas,
  (_, idea) => agent(createPrompt(idea, sortIds[idea.id]), { label: 'create:' + idea.id, phase: 'Create', schema: CREATE_SCHEMA }),
  (created, idea) => {
    if (!created || created.status !== 'created') {
      log(idea.id + ': creation failed, skipping review')
      return { idea: idea.id, created, review: null, fix: null }
    }
    return agent(reviewPrompt(idea), { label: 'review:' + idea.id, phase: 'Review', schema: REVIEW_SCHEMA })
      .then(review => ({ idea: idea.id, created, review, fix: null }))
  },
  (acc, idea) => {
    if (!acc || !acc.review || !acc.review.blockers || acc.review.blockers.length === 0) return acc
    log(idea.id + ': ' + acc.review.blockers.length + ' blocker(s) to fix')
    return agent(fixPrompt(idea, acc.review.blockers), { label: 'fix:' + idea.id, phase: 'Fix', schema: FIX_SCHEMA })
      .then(fix => ({ ...acc, fix }))
  }
)

phase('Lint')
const ourIds = ideas.map(i => i.id)
let lint = null
for (let round = 1; round <= 3; round++) {
  lint = await agent(lintPrompt(round), { label: 'lint:round' + round, phase: 'Lint', schema: LINT_SCHEMA, effort: 'low' })
  if (!lint || lint.clean) break
  const mine = lint.errors.filter(e => ourIds.includes(e.taskId))
  if (mine.length === 0) {
    log('Lint errors remain but none belong to the new tasks - stopping')
    break
  }
  const byTask = {}
  for (const e of mine) {
    if (!byTask[e.taskId]) byTask[e.taskId] = []
    byTask[e.taskId].push(e.message)
  }
  log('Lint round ' + round + ': fixing ' + Object.keys(byTask).length + ' task(s)')
  await parallel(Object.entries(byTask).map(([id, errs]) => () =>
    agent(lintFixPrompt(id, errs, sortIds[id]), { label: 'lintfix:' + id, phase: 'Lint' })))
}

return { tasks: results.filter(Boolean), lint }