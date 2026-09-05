# Contributing a task

Thanks for adding to TryAL's task catalog! A task is one directory under
`tasks/` — a problem statement, starter code, and the tests that grade it.
This catalog is public, so reference solutions are **not** committed here —
see [Reference solutions](#reference-solutions). This guide walks you from
zero to a merged PR.

## Quickstart

1. **Copy the template** — Windows (PowerShell):

   ```powershell
   Copy-Item -Recurse templates\full_execution tasks\<topic>-<slug>
   ```

   macOS / Linux (bash):

   ```bash
   cp -r templates/full_execution tasks/<topic>-<slug>
   ```

   The directory name **is** the task id: `<topic>-<slug>`, e.g.
   `algorithm-vat-rounding`. The prefix is the task's `topic` (an id from
   [`topics.yaml`](topics.yaml)) and the slug is a short kebab-case
   description of what the user builds. It must equal the `id` field in
   `metadata.yaml`; the lint checks both rules.

   Every task is graded `full_execution`: real tests in a real Business
   Central container (see [Grading semantics](#grading-semantics)).

2. **Fill in the files** (each template file is annotated):

   | File | Purpose |
   |---|---|
   | `metadata.yaml` | Grading config + catalog metadata. Editors validate it live via the JSON Schema header. |
   | `task.md` | The problem statement users see, verbatim. Delete the template's HTML comments. |
   | `starter/*.al` | The user's starting point, one file per AL object named `<ObjectName>.<ObjectType>.al` (a flat `starter.al` is rejected by the lint). |
   | `tests/*.al` | The test codeunits that grade submissions. |
   | `solution/*.al` | Your reference solution — **gitignored in this catalog**, it stays on your machine (see [Reference solutions](#reference-solutions)). |

   For a complete worked example of the committed parts, see
   [`tasks/basics-add-table-field`](tasks/basics-add-table-field).

   Mind `sortId` in `metadata.yaml`: an integer that must be unique across
   every TryAL catalog, so each catalog owns a range — this one's is
   1–4999. The template's placeholder is deliberately taken, so a fresh copy
   fails the lint until you replace it — the message names an unused number.

3. **Lint before you push:**

   ```bash
   npm install
   npm run lint
   ```

   The lint checks the format contract: schema-valid metadata, id/dirname
   match, unique sortId, required files, submission limits, valid topic. It
   reports *all* findings at once.

   CI also **compiles** your starter and tests with the real AL compiler
   against the platform's pinned BC symbols
   ([`compiler/symbols/`](compiler)), so broken AL never reaches review.
   Locally the same gate also compiles your `solution/` (and the tests
   against it) whenever one is present. To run that gate locally you need the [.NET SDK](https://dotnet.microsoft.com/download)
   10.x — the AL compiler ships as a `net10.0` dotnet tool. Install the
   compiler once (same command on every OS; the version is pinned in
   `package.json` → `config.alToolVersion`):

   ```bash
   dotnet tool install --global Microsoft.Dynamics.BusinessCentral.Development.Tools --version 18.0.38.52553-beta
   ```

   then:

   ```bash
   npm run compile                  # all tasks + the template
   npm run compile -- <your-task-id>
   ```

   Compiler errors fail the gate; analyzer (cop) findings are shown but
   non-fatal, exactly as on the platform.

4. **Open a PR.** CI re-runs the lint and the compile gate automatically.
   Real grading is a separate, **manually triggered** workflow — a maintainer
   launches **Grade tasks** against your branch, which submits your unchanged
   `starter/` (must compile, and must fail at least one test). Your reference
   solution is graded from the private catalog, not from the PR (see
   [Reference solutions](#reference-solutions)). It is manual because each
   run occupies a real Business Central container. Every task PR gets human
   review before merge: `tests/` is trusted code that runs inside those
   containers.

### Review or create with an AI agent

The repo ships a [Claude Code](https://claude.com/claude-code) skill at
[`.claude/skills/create-task/`](.claude/skills/create-task/SKILL.md) that
encodes this whole guide — the format contract, the test quality bar, and
AL test-writing references distilled from Microsoft Learn and the BC test
libraries. Agents pick it up automatically when asked to create a task;
you can also invoke it explicitly with `/create-task`.

## Reference solutions

This repository is public, and a task's reference solution is deliberately
not part of it: `tasks/*/solution/` is gitignored, the lint does not require
it (`package.json` → `config.solutions: optional`), and CI fails if one is
ever force-added. The maintainers keep every reference solution in a private
sibling catalog with the same task format and grade it there.

You still need one — a task without a passing solution is not provably
solvable. Write `solution/` first (the template and the authoring skill
assume it) and keep it locally while you work: `npm run compile` compiles it
and the tests against it whenever it is present, and `npm run smoke` grades
it if you have platform credentials. Just don't try to commit it. A
maintainer will ask you for it during review so it can be graded from the
private catalog before your task is merged.

## Grading semantics

The submission can be compiled **together with your `tests/` codeunits** into a
test app, published into a real BC container, and graded by the `[Test]`
procedures. Users see per-test pass/fail. Correctness lives entirely in the
tests.

- Test codeunits declare `Subtype = Test;` and `TestPermissions = Disabled;`
  (the latter keeps permission-set simulation out of grading, so tests that
  seed base tables directly never trip over it). All standard Microsoft test
  libraries are available — `Assert`, `"Library - Dialog Handler"`, the
  `"Library - X"` data/posting helpers (`"Library - Sales"`,
  `"Library - ERM"`, `"Library - Random"`, …), `Any`,
  `"Library - Variable Storage"`, and more. Reference them by the exact
  declared object name (dashes and quoting matter). APIs and catalog:
  [.claude/skills/create-task/references/test-libraries.md](.claude/skills/create-task/references/test-libraries.md).
- Object/field/enum IDs are remapped into per-worker bands at run time.
  Reference the user's objects **by name** (`Codeunit "Discount Calculator"`),
  never by literal ID. Any 50000+ id is fine for the test codeunit itself.
- Name the exact objects and procedure signatures in `task.md` — your tests
  bind to them, so users must be able to predict them.
- **Quality bar:** the reference solution passes **all** tests (graded by the
  maintainers from the private catalog); the unchanged starter **compiles**
  and **fails at least one** (proven here by the Grade tasks workflow).
  Tests that can't discriminate grade nothing — and a starter that doesn't
  compile is a broken task, not a discriminating one, so grading rejects it
  separately.
- Keep tasks rollback-safe (the defaults, `transactionModel: auto_rollback`
  + `companyIsolation: reuse`): they grade in a shared warm company. A
  `committed` + `fresh` task pays ~17 s a run for a throwaway company and can
  never use the warm one, so declare it only when something must really commit
  (`Email.Send`, a captured `Codeunit.Run`, `StartSession`) — the lint warns
  when `committed`/`fresh` is declared with nothing that commits. Two traps
  look like they need it but don't:
  - Standard posting routines (`Sales-Post`, `Purch.-Post`,
    `Gen. Jnl.-Post Batch`, undo, make-order, and the `Library - X` helpers
    around them) commit on their own. Put `[CommitBehavior(CommitBehavior::Ignore)]`
    on every test method that posts: it silences those commits for the whole
    call tree, tests and solution alike. The lint warns when an
    `auto_rollback` task posts without it, or keeps a literal `Commit()` in
    its tests (the platform's isolation scanner falls back to a fresh company
    on a literal `Commit`).
  - An error caught by `asserterror` rolls the database back to the last
    `Commit` — including the rows the test itself seeded. A test that reads
    state back after a refused call catches the error through a test-local
    `[TryFunction]` instead (`if TryCall(...) then Assert.Fail(...)`, then
    `Assert.ExpectedError`); a try function's writes are never rolled back.
  Both patterns with examples:
  [.claude/skills/create-task/references/al-testing.md](.claude/skills/create-task/references/al-testing.md)
  → "Keeping a task rollback-safe".
- Object IDs, `tableextension` field IDs and enumextension-value IDs are
  renumbered at run time (a new table's own field numbers are kept), so tests
  must not hardcode an enumextension ordinal or a tableextension field number
  — look them up by name.

Everything the statement promises should be enforced by a test, and every
test should be predictable from the statement. If something is merely good
practice (a caption, a tooltip), label it "not graded" rather than phrasing
it as a requirement.

### Why not `compile_only`?

The platform format also defines a `compile_only` tier where success is just
"zero compiler errors". **This catalog does not accept compile_only tasks for
now** (the lint rejects them): compiling proves too little — an
empty-but-compiling file passes, so the task can't hold any real promise to
the user. Nearly anything worth teaching can be phrased as a small
`full_execution` task instead. If you believe a task genuinely warrants
compile_only, open an issue and make the case before authoring it.

## `metadata.yaml` field reference

The authoritative schema is [`schema/metadata.schema.json`](schema/metadata.schema.json)
— the `# yaml-language-server: $schema=...` header in the templates gives you
live validation in VS Code (with the YAML extension) as you type.

| Field | Type / enum | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Must equal the directory name. |
| `sortId` | integer, 1–4999 | yes | Catalog sort key, unique across every TryAL catalog — each catalog owns a disjoint range. The lint rejects duplicates and out-of-range numbers and names an unused one. |
| `title` | string | yes | Display title. |
| `author` | string | no | Optional display credit, e.g. `"@your-github-handle"`. Courtesy only — legal attribution is git history + the repo [LICENSE](LICENSE). |
| `difficulty` | `easy \| medium \| hard` | yes | |
| `topic` | string | yes | Must exist in [`topics.yaml`](topics.yaml). |
| `tags` | string[] | no | Free-form facets for filtering. |
| `executionTier` | `compile_only \| full_execution` | yes | Only `full_execution` is accepted in this catalog for now — see grading semantics above. |
| `transactionModel` | `auto_rollback \| committed` | no | `full_execution` only. Whether the test run rolls back its writes. Never affects pass/fail. |
| `companyIsolation` | `reuse \| fresh` (default `reuse`) | no | `full_execution` only. `fresh` if the tests commit data. |
| `hints` | string[] | no | Ordered gentle → explicit. |
| `allowedDependencies` | string[] | no | Display-only today. |
| `bcVersion`, `runtime`, `target` | — | no | **Omit.** They default from the platform's pinned BC version. Only set for a deliberate exception, explained in the PR. |

The platform validates strictly: unknown fields are rejected, not ignored.

## Submission limits

Starter and solution must each be a valid submission:

- at most **6 files**, each at most **70 KB**;
- `.al` extension only, flat filenames (no subdirectories);
- `full_execution` submissions must not reference other objects by literal
  object ID — always by name.

## What users see

`GET /tasks/{id}` serves `task.md` as the description plus the starter files,
hints, allowed dependencies, and the test files. `transactionModel` and
`companyIsolation` are never served; reference solutions exist only in the
maintainers' private catalog and are never served either.

## License

This repository is [MIT-licensed](LICENSE). By submitting a pull request you
agree that your contribution — task statements, code, and tests — is licensed
under the same terms. That's what lets the platform serve your task through
its API and website, and lets learners freely reuse what they see.

You keep your copyright, and git history is the permanent record of your
authorship. For visible credit on the platform, set the optional `author`
field in `metadata.yaml` to your GitHub handle. Tasks cannot carry their own
license — one repo, one license.

## Changing the format itself

The task format contract is owned by the platform. New fields, enum values,
or semantics are coordinated changes — open an issue and make the case, don't
ship it in a PR. When a rule here seems ambiguous, prefer the stricter reading
and leave a note in your PR.
