# A Miniature Posting Routine

Every Business Central developer eventually steps through `Gen. Jnl.-Post Batch` in the debugger: guard the lines, prove the batch balances, number the ledger entries, flip the status — all inside one transaction. This task is that routine in miniature, and it is the archetypal BC interview exercise.

The starter ships three finished data objects. Do not rename them or their fields — the grading tests bind to every name below character for character.

## The objects you get

- Table `"Mini Journal Line"` — primary key `"Batch Name"` (Code[10]) + `"Line No."` (Integer); fields `"Account No."` (Code[20]), `"Posting Date"` (Date), `Description` (Text[50]), `Amount` (Decimal), `Status` (enum `"Mini Journal Status"`, defaults to `Open`).
- Table `"Mini Ledger Entry"` — primary key `"Entry No."` (Integer); fields `"Account No."`, `"Posting Date"`, `Description`, `Amount`, `"Batch Name"`.
- Enum `"Mini Journal Status"` — values `Open`, `Posted`.

## Requirements

Implement `PostBatch` in the codeunit `"Mini Jnl.-Post Batch"`:

```al
procedure PostBatch(BatchName: Code[10])
```

Rules:

1. Scope — every check and every write below concerns exactly the lines of `BatchName` whose `Status` is `Open`. Other batches and already-posted lines must be invisible to the routine.
2. If there are no such lines, fail with an error message that contains `nothing to post`.
3. Field guards — every line must carry an `"Account No."`, a `"Posting Date"` and a non-zero `Amount`. A line that lacks any of them must fail the whole batch with the standard field-guard error: the message names the field and contains `must have a value` (exactly what `TestField` produces).
4. Balance — the amounts of the lines being posted must sum to zero; otherwise fail with an error message that contains `out of balance`.
5. Posting — create one `"Mini Ledger Entry"` per line, in ascending `"Line No."` order. `"Entry No."` continues the ledger: the highest existing entry number plus 1 for the first new entry, then plus 1 per entry, no gaps. Copy `"Account No."`, `"Posting Date"`, `Description`, `Amount` and `"Batch Name"` from the line.
6. Status update — each posted line gets `Status` = `Posted` and stays in the journal table; posting never deletes lines.
7. All or nothing — when the routine fails, the ledger must gain no entries and every line of the batch must still be `Open`.
8. Run it again — a second call on the same batch finds nothing open and fails with the `nothing to post` error, leaving the ledger unchanged. Lines added to the batch afterwards post on their own, without duplicating the already-posted ones.

## What the tests check

Each rule above is enforced by one or more grading tests: happy-path entry counts and a field-by-field copy check (with generated values — hardcoding won't survive), entry numbering after a pre-seeded ledger entry, `"Line No."` ordering, all three field guards, out-of-balance batches (in either direction — a single cent off is enough), the empty batch, double-posting, a batch that gains new open lines after being posted, and a batch posted next to a deliberately broken neighbour batch that must stay untouched. Error-text matching is case-insensitive, but the quoted phrases must appear exactly as written. The guard tests use balanced amounts, so the order in which you run the guards and the balance check never decides a test.

## Learn More

- [Record.FindSet([Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method)
- [Get, Find, and Next Methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods)
- [Dialog.Error(Text [, Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method)
- [Field Calculation Methods (CalcFields, TestField, Validate, and More)](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods)
- [Database.Commit() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method)
