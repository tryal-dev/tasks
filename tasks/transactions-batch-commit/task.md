# One Poison Record Shouldn't Kill the Batch

The overnight import job dies at 03:12 on record 37 of 200, and in the morning you learn the real damage: the error didn't just skip one bad record; it rolled back the 36 good ones imported before it. Real BC batch routines — the job queue, batch posting — are built so that one poison record can never undo the work already done. In this task you build a batch importer with exactly that guarantee.

The starter ships three finished data objects. Do not rename them or their fields — the grading tests bind to every name below character for character.

## The objects you get

- Table `"Order Import Line"` — primary key `"Batch Code"` (Code[20]) + `"Line No."` (Integer); fields `"Customer No."` (Code[20]), `Quantity` (Decimal), `Status` (enum `"Order Import Status"`, defaults to `Pending`).
- Table `"Imported Order"` — primary key `"Batch Code"` + `"Line No."`; fields `"Customer No."`, `Quantity`.
- Enum `"Order Import Status"` — values `Pending`, `Imported`.

## Requirements

Implement `ImportBatch` in the codeunit `"Order Import Batch"`:

```al
procedure ImportBatch(BatchCode: Code[20])
```

Rules:

1. Scope — the run concerns exactly the lines of `BatchCode` whose `Status` is `Pending`, processed in ascending `"Line No."` order. Other batches and already-imported lines must be invisible to it; a batch with no pending lines is a quiet no-op — no error, no writes.
2. Importing a line — a valid line produces exactly one `"Imported Order"` with the same `"Batch Code"` and `"Line No."` and copies of `"Customer No."` and `Quantity`, and the line's `Status` flips to `Imported`. The line stays in the import table; importing never deletes lines.
3. Guards, checked per line before it is imported — a line with a blank `"Customer No."` fails with the standard field-guard error: the message names the field and contains `must have a value` (exactly what `TestField` produces). A line whose `Quantity` is zero or negative fails with an error message that contains `must be positive`.
4. The poison rule — when a line fails, the run stops there and the error reaches the caller. But every line this run already imported must survive the failure: its `"Imported Order"` record and its `Imported` status must still be in the database afterwards. The failing line leaves no `"Imported Order"` behind and stays `Pending`, and so do all lines after it.
5. Guard errors are not the only way a line can die — one test makes a line crash while writing its `"Imported Order"` (the record already exists). Whatever the error, the lines imported before it must survive it, unconditionally.
6. Fix and rerun — calling `ImportBatch` again after the bad line is repaired imports the remaining pending lines and creates no duplicates for the lines imported earlier.

## What the tests check

The happy-path count and a field-by-field copy check with generated values (hardcoding won't survive); each guard with its error text (matching is case-insensitive, but the quoted phrases must appear exactly as written); a four-line batch whose third line is poison — the two lines before it must still be imported after the run fails, while the poison line and the line after it must not; the same batch repaired and rerun without duplicates; a mid-run crash at insert time whose predecessors must survive; scoping to the given batch next to a poisoned neighbour batch; a pre-imported line that must not be imported again; and the empty batch.

## Learn More

- [Database.Commit() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method)
- [CommitBehavior Attribute](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-commitbehavior-attribute)
- [Codeunit.Run(Integer [, var Record]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method)
- [AL Error Handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling)
- [Handling Errors Using Try Methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods)
