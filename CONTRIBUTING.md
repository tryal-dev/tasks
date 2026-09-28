# Contributing a task

Thanks for helping grow the free task catalog of
[TryAL.dev](https://tryal.dev/)!

A task is one folder under `tasks/` with three parts: a problem statement,
starter code, and the tests that grade solutions. This guide takes you from
an idea to a merged pull request.

Before you start:

- **Check the idea.** Not sure it fits the catalog?
  [Propose it first](https://github.com/tryal-dev/tasks/issues/new?template=propose-task.yml)
  and get feedback before you spend time on tests.
- **Know the rule that matters most.** Your reference solution must pass
  every test, and the untouched starter must compile but fail at least one.
  Tests that can't tell a right answer from a wrong one grade nothing.
- **Get the tools.** [Node.js](https://nodejs.org/) 20 or later for the lint.
  To also compile locally, the [.NET SDK](https://dotnet.microsoft.com/download)
  10.x (see step 4). [VS Code](https://code.visualstudio.com/) with the YAML
  extension validates `metadata.yaml` as you type.

## Quickstart

1. **Copy the template** into a folder named after your task id — replace
   `algorithm-vat-rounding` below with your own.

   Windows (PowerShell):

   ```powershell
   Copy-Item -Recurse templates\full_execution tasks\algorithm-vat-rounding
   ```

   macOS / Linux (bash):

   ```bash
   cp -r templates/full_execution tasks/algorithm-vat-rounding
   ```

   The folder name **is** the task id, in the form `<topic>-<slug>`: the
   topic is an id from [`topics.yaml`](topics.yaml), and the slug is a short
   kebab-case description of what the solver builds. It must equal the `id`
   field in `metadata.yaml`. The lint checks both rules.

2. **Fill in the files.** Every template file has comments explaining what
   goes where.

   | File | Purpose |
   |---|---|
   | `metadata.yaml` | Title, topic, difficulty, hints, and grading settings — see the [field reference](#metadatayaml-field-reference). |
   | `task.md` | The problem statement, shown to solvers exactly as written. Delete the template's HTML comments. |
   | `starter/*.al` | The code solvers start from. One file per AL object, named `<ObjectName>.<ObjectType>.al` — a single flat `starter.al` is rejected by the lint. |
   | `tests/*.al` | The test codeunits that grade solutions. |
   | `solution/*.al` | Your reference solution. **Keep it local** — it's gitignored here (see [Reference solutions](#reference-solutions)). |

   [`tasks/basics-add-table-field`](tasks/basics-add-table-field) is a small
   finished example of the committed parts.

   **Set a `sortId`.** It's an integer that must be unique across every
   TryAL catalog, so each catalog owns a range — this one's is 1–4999. The
   template's placeholder is deliberately taken, so a fresh copy fails the
   lint until you change it; the lint message suggests an unused number.

3. **Run the lint:**

   ```bash
   npm install
   npm run lint
   ```

   It checks the format: valid metadata, id matching the folder name, unique
   `sortId`, required files, [submission limits](#submission-limits), a known
   topic, and `isPro: false`. It reports every problem at once, not just the
   first.

4. **Compile** — optional locally, always run in CI. CI compiles your
   starter and tests with the real AL compiler against the platform's pinned
   Business Central symbols ([`compiler/symbols/`](compiler/symbols)), so
   broken AL never reaches review. Running it yourself catches errors
   earlier, and locally it also compiles your `solution/` and the tests
   against it.

   It needs the .NET SDK 10.x, because the AL compiler ships as a `net10.0`
   dotnet tool. Install the compiler once (same command on every OS; the
   version is pinned in `package.json` → `config.alToolVersion`):

   ```bash
   dotnet tool install --global Microsoft.Dynamics.BusinessCentral.Development.Tools --version 18.0.38.52553-beta
   ```

   Then:

   ```bash
   npm run compile                           # every task and the template
   npm run compile -- algorithm-vat-rounding # just your task
   ```

   Compiler errors fail the check. Analyzer (code cop) findings are shown
   but don't fail it — the same as on the platform.

5. **Open a pull request.** CI runs the lint and the compile check
   automatically. After that:

   - A maintainer grades your task in a real Business Central container with
     the manual **Grade tasks** workflow: the unchanged starter must compile
     and fail at least one test. It's manual because every run takes up a
     real container.
   - A maintainer asks you for your reference solution and grades it from
     the private catalog (see [Reference solutions](#reference-solutions)).
   - Every task PR needs maintainer approval, because `tests/` is trusted
     code that runs inside those containers.

### Review or create with an AI agent

The repo ships a [Claude Code](https://claude.com/claude-code) skill at
[`.claude/skills/create-task/`](.claude/skills/create-task/SKILL.md) that
covers this whole guide — the format, the test quality bar, and AL
test-writing references distilled from Microsoft Learn and the Business
Central test libraries. Agents pick it up automatically when asked to create
a task; you can also run it explicitly with `/create-task`.

## Reference solutions

This repository is public, so reference solutions are deliberately kept out
of it: `tasks/*/solution/` is gitignored, the lint doesn't require it
(`package.json` → `config.solutions: optional`), and CI fails if one is ever
force-added. The maintainers keep every reference solution in a private
catalog with the same format and grade them there.

You still need to write one — without a passing solution, nobody can be sure
the task is solvable. Write it first (the template and the AI skill assume
you do) and keep it locally while you work: `npm run compile` compiles it,
and the tests against it, whenever it's present. Don't commit it. A
maintainer will ask you for it during review and grade it from the private
catalog before your task is merged.

Maintainers with a platform admin key can also grade tasks locally with
`npm run smoke`.

## Grading semantics

The solver's code is compiled **together with your `tests/` codeunits** into
a test app, published into a real Business Central container, and graded by
the `[Test]` procedures. Solvers see pass/fail for each test. Correctness
lives entirely in the tests.

- **Quality bar.** The reference solution passes **all** tests (graded by
  the maintainers from the private catalog); the unchanged starter
  **compiles** and **fails at least one** (proven by the Grade tasks
  workflow). A starter that doesn't compile is a broken task, not a
  challenging one, so grading rejects it too.
- **Test codeunit setup.** Declare `Subtype = Test;` and
  `TestPermissions = Disabled;`. The latter keeps permission-set simulation
  out of grading, so tests that seed base tables directly don't trip over it.
- **Test libraries.** All standard Microsoft test libraries are available —
  `Assert`, `"Library - Dialog Handler"`, the `"Library - X"` data and
  posting helpers (`"Library - Sales"`, `"Library - ERM"`,
  `"Library - Random"`, …), `Any`, `"Library - Variable Storage"`, and more.
  Reference them by their exact declared object name (dashes and quoting
  matter). APIs and full list:
  [.claude/skills/create-task/references/test-libraries.md](.claude/skills/create-task/references/test-libraries.md).
- **Reference objects by name, never by ID.** Object IDs, `tableextension`
  field IDs, and `enumextension` value IDs are renumbered at run time (a new
  table's own field numbers are kept). Write `Codeunit "Discount Calculator"`
  rather than a literal ID, and look up an enumextension ordinal or a
  tableextension field number by name instead of hardcoding it. Any 50000+
  ID is fine for the test codeunit itself.

### Make the statement and the tests agree

- Name the exact objects and procedure signatures in `task.md`. Your tests
  bind to them, so solvers must be able to predict them.
- Everything the statement promises should be enforced by a test, and every
  test should be predictable from the statement.
- If something is merely good practice (a caption, a tooltip), label it
  "not graded" rather than phrasing it as a requirement.
- Test one behavior per `[Test]`, with an assert message that tells the
  solver *what* went wrong — they see each test's result.

### Keep tasks rollback-safe

Tasks grade in a shared, already-warm company, so keep them rollback-safe
with the defaults: `transactionModel: auto_rollback` and
`companyIsolation: reuse`. A `committed` + `fresh` task spends about 17
seconds per run creating a throwaway company and never benefits from the
warm one. Declare it only when something really must commit (`Email.Send`, a
captured `Codeunit.Run`, `StartSession`). The lint warns when `committed` or
`fresh` is declared but nothing commits.

Two situations look like they need `committed` but don't:

- **Standard posting.** Posting routines (`Sales-Post`, `Purch.-Post`,
  `Gen. Jnl.-Post Batch`, undo, make-order, and the `Library - X` helpers
  around them) commit on their own. Put
  `[CommitBehavior(CommitBehavior::Ignore)]` on every test method that
  posts: it silences those commits for the whole call tree, tests and
  solution alike. The lint warns when an `auto_rollback` task posts without
  it, or when its tests contain a literal `Commit()` — the platform falls
  back to a fresh company whenever it finds one.
- **Checking data after an expected error.** An error caught by `asserterror`
  rolls the database back to the last `Commit` — including rows the test
  itself seeded. To read data back after a refused call, catch the error
  with a test-local `[TryFunction]` instead
  (`if TryCall(...) then Assert.Fail(...)`, then `Assert.ExpectedError`);
  a try function's writes are never rolled back.

Both patterns, with examples:
[.claude/skills/create-task/references/al-testing.md](.claude/skills/create-task/references/al-testing.md)
→ "Keeping a task rollback-safe".

### Why not `compile_only`?

The platform format also defines a `compile_only` tier, where success is
just "zero compiler errors". **This catalog doesn't accept `compile_only`
tasks for now** (the lint rejects them): compiling proves too little — an
empty file that compiles would pass, so the task can't promise the solver
anything real. Nearly anything worth teaching can be phrased as a small
`full_execution` task instead. If you believe a task genuinely needs
`compile_only`, open an issue and make the case before writing it.

## `metadata.yaml` field reference

The authoritative schema is [`schema/metadata.schema.json`](schema/metadata.schema.json).
The `# yaml-language-server: $schema=...` header in the templates gives you
live validation in VS Code (with the YAML extension) as you type.

| Field | Type / enum | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Must equal the folder name. |
| `sortId` | integer, 1–4999 | yes | Catalog sort key, unique across every TryAL catalog — each catalog owns its own range. The lint rejects duplicates and out-of-range numbers, and suggests an unused one. |
| `title` | string | yes | Title shown to solvers. |
| `author` | string | no | Optional display credit, e.g. `"@your-github-handle"`. Courtesy only — legal attribution is git history plus the repo [LICENSE](LICENSE). |
| `difficulty` | `easy \| medium \| hard` | yes | |
| `isPro` | boolean | yes | Whether the task is part of TryAL Pro. Always `false` here — this catalog has free tasks only (lint-enforced). |
| `topic` | string | yes | Must exist in [`topics.yaml`](topics.yaml). |
| `tags` | string[] | no | Free-form labels for filtering. |
| `executionTier` | `compile_only \| full_execution` | yes | Only `full_execution` is accepted here for now — see [Why not `compile_only`?](#why-not-compile_only) |
| `transactionModel` | `auto_rollback \| committed` | no | `full_execution` only. Whether the test run rolls back its writes. Never affects pass/fail. |
| `companyIsolation` | `reuse \| fresh` (default `reuse`) | no | `full_execution` only. `fresh` if the tests commit data. |
| `hints` | string[] | no | Ordered from gentle to explicit. |
| `allowedDependencies` | string[] | no | Display-only today. |
| `bcVersion`, `runtime`, `target` | — | no | **Omit.** They default from the platform's pinned Business Central version. Only set them for a deliberate exception, explained in the PR. |

The platform validates strictly: unknown fields are rejected, not ignored.

## Submission limits

The starter and the solution must each be a valid submission:

- at most **6 files**, each at most **70 KB**;
- `.al` files only, with flat filenames (no subfolders);
- no references to other objects by literal object ID — always by name.

## What solvers see

Solvers get `task.md` as the problem description, plus the starter files,
hints, allowed dependencies, and the test files — so treat your tests as
public. `transactionModel` and `companyIsolation` are never shown, and
reference solutions stay in the maintainers' private catalog and are never
served either.

## License

This repository is [MIT-licensed](LICENSE). By submitting a pull request you
agree that your contribution — task statements, code, and tests — is
licensed under the same terms. That's what lets the platform serve your task
through its API and website, and lets learners freely reuse what they see.

You keep your copyright, and git history is the permanent record of your
authorship. For visible credit on the platform, set the optional `author`
field in `metadata.yaml` to your GitHub handle. Tasks can't carry their own
license — one repo, one license.

## Changing the format itself

The task format is owned by the platform. New fields, enum values, or
semantics are coordinated changes — open an issue and make the case rather
than shipping it in a PR. When a rule here seems ambiguous, prefer the
stricter reading and leave a note in your PR.
