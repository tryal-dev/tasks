---
name: create-task
description: Author a practice task for this catalog end to end — design, statement, starter, grading tests, reference solution, metadata — or review and strengthen an existing task's tests. Use whenever asked to create, add, or write a task, or to improve a task's tests or statement.
---

# Create a task

A task is one directory under `tasks/`. The platform serves `task.md` and the
starter over its REST API; a submission is compiled **together with the
task's `tests/` codeunits** into a test app, published into a real Business
Central container, and graded by the `[Test]` procedures — per-test pass/fail
plus your failure messages are shown to the user. The tests ARE the grader:
a task is exactly as good as its tests.

## Workflow

1. **Design first.** Decide what the user builds, which `[Test]` procedures
   will grade it, and how each test would catch a wrong or lazy solution.
   If you can't name a test that fails for a plausible wrong answer, the
   task is under-specified — redesign before writing files.
2. **Scaffold:** copy `templates/full_execution/` to `tasks/<topic>-<slug>/`.
   The directory name IS the task id; the prefix must be a topic id from
   `topics.yaml` and must equal `metadata.yaml` → `id` (both lint-enforced).
3. **Write `task.md`** — the statement (rules below).
4. **Write `tests/`** — read the references first (see "Writing the tests").
5. **Write `solution/`**, then strip it down to the `starter/` skeleton.
6. **Fill `metadata.yaml`** (field reference: CONTRIBUTING.md).
7. **Validate:** `npm run lint`, then the self-check list at the end.

## The statement (`task.md`)

The contract: **everything the statement promises is enforced by a test, and
every test is predictable from the statement.** Users must never lose to a
hidden rule, and never be promised something grading ignores.

- Name the exact object names and procedure signatures the tests bind to —
  tests reference the user's objects by name, so users must be able to
  predict them character for character.
- Describe what the grading tests check under a `## What the tests check`
  heading, in one short paragraph — every task in the catalog has this
  section, under exactly that title. If a comparison is exact, say so
  ("mind the comma and the exclamation mark").
- Anything that is merely good practice (captions, tooltips) is labelled
  "not graded" — never phrased as a requirement.
- Tell users to pick object IDs in the house range 50100–50199 and to
  reference other objects **by name, never by ID**.
- If the task builds on another task's objects, say explicitly: "include the
  files from `<task-id>` in your submission" — the platform does NOT carry
  objects between tasks.
- End every statement with a `## Learn More` section: 2–4 links to official
  Microsoft Learn pages genuinely useful for solving this task, formatted
  `- [Page Title](url) — short why-it-helps phrase.` Verify every URL via
  the Microsoft Learn docs search tool (`microsoft_docs_search` /
  `microsoft_docs_fetch`) before including it — never write a URL from
  memory. Pin the locale: `learn.microsoft.com/en-us/dynamics365/...`. The
  statements, object names and error strings are all English, and Learn's
  translated developer pages lag the English ones — every reader should land
  on the page you actually verified. Mind the scaffolding
  gradient below: for non-basics tasks, link
  the contract's surrounding concepts, not the page that names the winning
  mechanism.
- Delete every template HTML comment before committing.

### How much to reveal — the scaffolding gradient

A statement carries two kinds of information. Keep them apart:

- **The contract** — object names, signatures, formulas, boundary rules,
  what the tests assert. Always complete, at every difficulty: tests bind
  by name, and users must never lose to a hidden rule. Hiding contract is
  never the way to make a task harder.
- **The mechanism** — which AL construct or API satisfies the contract
  (`OnValidate` vs `MinValue`, `IsEmpty` vs `Count`, `CalcSums` vs a loop).
  This is the difficulty dial.

Set the dial by topic and difficulty:

- **basics:** teach openly. The statement may name the mechanism, even the
  exact trigger or property — the challenge is producing correct AL, not
  finding it. Also call out known dead-ends that fail invisibly (e.g.
  `MinValue` is UI-only and never fires for code writes): a beginner must
  be able to see why a plausible attempt failed. But even here, express
  formulas and rules as math or prose, never as paste-ready AL — the
  translation into field quoting, `Round` signatures, and trigger placement
  is the exercise that remains. If the statement (or a hint) contains a
  line the user can paste verbatim as the solution body, rewrite it.
- **everything else:** the statement gives the contract and the graded
  outcome — never the winning mechanism. Discovering it IS the lesson. A
  performance statement promises "correct totals and at most N SQL
  statements", not "use CalcSums"; a transactions statement promises "all
  invalid lines reported at once", not "use ErrorBehavior::Collect". The
  mechanism belongs in the hints (gentle → explicit) and in the failing
  tests' messages, so the wall users hit is discoverable, never silent.

Smell test: if a submission can be assembled by copy-pasting code out of
the statement, either it is a basics task or the statement over-shares.

## Writing the tests

Read before writing any test:

- `references/al-testing.md` — test codeunit mechanics, `asserterror`,
  `[TransactionModel]`, TestPage patterns, handler methods, SQL-budget
  tests. **Mandatory** when the task touches pages/UI, expected errors,
  commits data, or grades a SQL statement/row budget (the server data
  cache silently breaks naive budget tests — see that section).
- `references/test-libraries.md` — the exact API of the libraries available
  on the platform, and what exists in the wider BC ecosystem.

Hard platform facts:

- All standard Microsoft test libraries ship on the platform: `Assert` (the
  conventional assert), `"Library - Dialog Handler"`, the `"Library - X"`
  data/posting helpers (`"Library - Sales"`, `"Library - ERM"`,
  `"Library - Random"`, …), plus `Any`, `"Library Assert"`, and
  `"Library - Variable Storage"`. Reference any of them by the **exact
  declared object name** — dashes and quoting matter
  (`LibraryVariableStorage: Codeunit "Library - Variable Storage";`).
  APIs and catalog: references/test-libraries.md. Prefer library creators
  (`LibrarySales.CreateCustomer`) over hand-rolled `Insert`s for BC master
  data.
- All object/field/enum IDs are remapped into per-worker bands at run time.
  Reference the user's objects **by name** (`Codeunit "Discount Calculator"`),
  never by literal ID. Any 50000+ id is fine for the test codeunit itself.
- Test codeunits declare `Subtype = Test;` and `TestPermissions = Disabled;`
  — the latter keeps permission-set simulation out of grading, so tests that
  seed base tables directly can never trip over it.
- Default grading rolls the database back (`transactionModel: auto_rollback`,
  `companyIsolation: reuse`) and grades in a shared warm company. A
  `committed` + `fresh` task pays ~17 s per run for a throwaway company —
  keep every task rollback-safe unless a real commit is unavoidable. Two
  things threaten that more often than expected (details and the patterns
  in references/al-testing.md → "Keeping a task rollback-safe"):
  - **Standard posting commits** (`Sales-Post`, `Purch.-Post`,
    `Gen. Jnl.-Post Batch`, Make Order, Undo …, and the `Library - X`
    posting helpers). Put `[CommitBehavior(CommitBehavior::Ignore)]` on
    every test method that posts — it silences those commits for the whole
    call tree, test and solution alike, with no change to the statement.
  - **An error caught by `asserterror` rolls back to the last `Commit`**,
    the test's own arrangement included. A test that reads state back after
    a refused call catches the error through a test-local `[TryFunction]`
    instead (`if TryCall(...) then Assert.Fail(...)`, then
    `Assert.ExpectedError`) — a try function keeps every row in place.
  Only when something must really commit (`Email.Send`, a captured
  `Codeunit.Run`, `StartSession`) declare `transactionModel: committed` AND
  `companyIsolation: fresh`.
- IDs are remapped at run time: object IDs, every `field(<id>;` in a
  tableextension and every `value(<id>;` in an enumextension (one sequential
  allocator). A new table keeps its own field numbers, so `TransferFields`
  between custom tables pairs fields exactly as authored. Never hardcode an
  enumextension ordinal in a test (look it up by name via `Ordinals()`/
  `Names()`), and never hardcode a tableextension field number.
- Grading containers have **no outbound network** — tests must never call a
  real external service. For HTTP, let users write real `HttpClient` code
  and intercept it in the tests with an `[HttpClientHandler]` +
  `TestHttpRequestPolicy = BlockOutboundRequests` (BC 26+); for non-HTTP
  seams, mock via integration events (`EventSubscriberInstance = Manual` +
  `BindSubscription`). Both patterns: references/al-testing.md.

Quality bar — CI-enforced when grading credentials are configured, and
checked by every reviewer:

- `solution/` passes **all** tests.
- The unchanged starter **compiles together with the tests** and **fails at
  least one** of them. A starter that does not compile is a broken task (the
  user opens a red compiler, not a failing test) and grading rejects it —
  so tests must never bind at compile time to what the user is asked to add
  (a field, an enum value, an event); see "Grading what the user adds" below.
  Tests that can't discriminate grade nothing.

Craft rules:

- One behavior per `[Test]`, named after the behavior
  (`GreetsTheWorldWhenNoNameIsGiven`, not `Test1`). Exactly one action
  (WHEN) per test — a second WHEN with its own verification is a second test.
- Declare `[TransactionModel(TransactionModel::AutoRollback)]` (or the model
  the test actually needs) explicitly on every test method — never rely on
  the default.
- The failure message is user-facing UI. Say what was expected in the task's
  own vocabulary: `'Expected the value typed into the card control to be
  saved on the customer'`. And make the ACTUAL value visible: the
  `AreEqual` family prints `Expected:<>/Actual:<>` on its own — prefer it
  over `IsTrue(A = B, ...)`, which hides both; where `IsTrue`/`IsFalse` is
  the right assert, embed the value via
  `StrSubstNo('Expected ..., got %1', Value)`
  (see references/al-testing.md → "Failure messages").
- Tests must not depend on each other or on execution order. Use distinct
  record keys per test (`'TRYAL-T101'`, `'TRYAL-T101B'`, …).
- Defeat hardcoding: when the task computes something, at least one test
  should assert on generated input (`Any.AlphabeticText`, `Any.IntegerInRange`)
  or a second fixed case, so returning a constant or pattern-matching the
  examples fails.
- Pin the discriminating boundaries the statement names: exact field lengths
  (`MaxStrLen`), boundary amounts (at/below/above), empty input. A weaker
  implementation than promised must fail somewhere.
- Don't grade ambient state: no assertions that depend on `Today`, demo-data
  specifics, or locale formatting. If the behavior involves dates, put the
  date parameter in the promised signature so tests pass explicit values.
- For UI tasks, test both directions of a binding: input reaches the record,
  and record state shows in the control.
- Error-path requirements use `asserterror` and verify the message.

## Starter and solution

- Both must be valid submissions: **≤ 6 files, ≤ 70 KB each, `.al` only,
  flat filenames** — always `starter/*.al`, one file per object, named
  `<ObjectName>.<ObjectType>.al` (a flat `starter.al` is lint-rejected).
- The starter is the natural empty shell of the solution: object declared,
  body reduced to a `// TODO:` comment. It must never pass the tests.
- `solution/` is never served; it is the proof the task is solvable and the
  thing CI grades. Keep it idiomatic — it sets the standard reviewers
  compare submissions against.

## Grading what the user adds

The tests are compiled together with the starter, so they can only name
what the starter already declares. When the task is "add a field / an enum
value / a FlowField / an event", the tests reach the new thing **at run
time, by name**, and fail with a user-facing message when it is missing:

```al
local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
var
    FldRef: FieldRef;
    i: Integer;
begin
    for i := 1 to RecRef.FieldCount() do begin
        FldRef := RecRef.FieldIndex(i);
        if FldRef.Name() = FieldName then
            exit(FldRef);
    end;
    Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
end;
```

- Declaration checks: `RecRef.Open(Database::X)`, then `FldRef.Type()`,
  `Length()`, `Class()` (FlowField/FlowFilter), `IsEnum()`.
- Writes: `RecRef.GetTable(Rec); FieldByName(RecRef, 'X').Value := V;
  RecRef.Modify(); RecRef.SetTable(Rec)`; validation via
  `FieldByName(RecRef, 'X').Validate(V)`. Reads: assign `.Value()` to a
  typed local so `Assert.AreEqual` compares like with like. FlowFields:
  `CalcField()` then `Value()`.
- Enum values: look the ordinal up by name in `Enum::"X".Names()` /
  `Ordinals()` (never a literal — enumextension ordinals are renumbered).
- Page controls: the `"Page Control Field"` virtual table (`PageNo`,
  `TableNo`, `FieldNo`, `ControlName`) proves a control is bound to the new
  field; `TestPage` control access is compile-time only.
- Events the tests subscribe to must already exist: declare the publisher
  in the starter with the promised signature (never raised), and let the
  starter fail because the event never fires.
- `tasks/basics-add-table-field` is the canonical small example; `npm run
  compile` gates both pairings (`tests vs solution`, `tests vs starter`).

## `metadata.yaml` gotchas

Full field reference: CONTRIBUTING.md. The ones that bite:

- `executionTier: full_execution` — the only tier this catalog accepts.
- `sortId` — an integer unique across every TryAL catalog; each catalog owns
  a range (this repo's schema `minimum`/`maximum`). Take the highest existing
  `sortId` + 1. The template's placeholder is deliberately taken, so a fresh
  copy fails the lint until you replace it (the message names an unused
  number).
- `hints` run gentle → explicit; the last hint may be nearly explicit but
  must not paste the full solution.
- Omit `bcVersion` / `runtime` / `target` — they default from the platform's
  pinned BC version.

## Validate before opening a PR

1. `npm run lint` — schema, id = dirname, id prefix = topic, unique
   sortId, required files, submission limits.
2. Self-check, mirroring `.github/PULL_REQUEST_TEMPLATE.md`:
   - every statement promise has a test; every test is predictable from the
     statement;
   - solution passes all tests, starter fails at least one — the lint cannot
     run tests, so unless the CI grading smoke test runs, say plainly in the
     PR that grading proof is pending;
   - objects referenced by name only; hints ordered; template comments gone.
