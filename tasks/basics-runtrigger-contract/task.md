# Two Insert Paths: The RunTrigger Contract

Your company is replacing a legacy loyalty system. New members sign up every day and must be stamped with today's enrollment date, while thousands of legacy members arrive through a migration job and must keep the audit dates they earned years ago. Same table, two write paths — and the only difference between them is whether the table's triggers run.

## Requirements

1. Create a **table** named `"Loyalty Member"` with these fields:
   - `"Member No."` of type `Code[20]` — the primary key
   - `Description` of type `Text[100]`
   - `"Enrolled On"` of type `Date`
   - `"Last Updated On"` of type `Date`
2. Give the table an **`OnInsert` trigger** that stamps `"Enrolled On"` with `WorkDate()` — unconditionally, even when the caller already filled the field: for a normal registration, the system is the authority on the enrollment date.
3. Give the table an **`OnModify` trigger** that stamps `"Last Updated On"` with `WorkDate()` — unconditionally.
4. Create a **codeunit** named `"Member Registration"` with four procedures:

```al
procedure RegisterMember(var Member: Record "Loyalty Member")
procedure MigrateMember(var Member: Record "Loyalty Member")
procedure UpdateMember(var Member: Record "Loyalty Member")
procedure PatchMigratedMember(var Member: Record "Loyalty Member")
```

5. `RegisterMember` inserts the record so that the `OnInsert` trigger **runs** — the enrollment stamp appears.
6. `MigrateMember` inserts the record so that the `OnInsert` trigger does **not** run — every imported field value, including `"Enrolled On"`, lands in the database exactly as provided.
7. `UpdateMember` modifies the record so that the `OnModify` trigger **runs** — `"Last Updated On"` is stamped.
8. `PatchMigratedMember` modifies the record so that the `OnModify` trigger does **not** run — a data-fix pass over migrated rows must keep the imported `"Last Updated On"`.

Which path a caller gets is decided by the `RunTrigger` parameter of `Insert` and `Modify` — and its default is `false`, which is why a bare parameterless call is a classic source of "my trigger never fired" bugs. Write the parameter explicitly on every `Insert` and `Modify` call so the choice is visible in the code (LinterCop rule LC0040 flags calls that omit it); the explicitness itself is not graded — the behavior above is.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The grading tests drive members through your codeunit and read them back from the database: the register and update paths must come back with `WorkDate()` in the stamped field (even when the test pre-filled it); the migration paths must come back with the imported dates unchanged and the other changed fields saved. They also insert and modify a record directly with triggers running to verify that the stamping lives in the table's own triggers, not in the codeunit, and they check the declared maximum lengths of `"Member No."` (20) and `Description` (100).

## Learn More

- [OnInsert (Table) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/table/devenv-oninsert-table-trigger) — when the trigger runs, and why code-based inserts only fire it on request.
- [OnModify (Table) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/table/devenv-onmodify-table-trigger) — the modify-side counterpart.
- [Record.Insert(Boolean) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-boolean-method) — the RunTrigger parameter and its default.
- [Record.Modify([Boolean]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method) — same contract for modifying records.
- [Table object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object) — declaring fields, keys, and triggers on a new table.
