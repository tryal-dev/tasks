# Write Only What Changed

Every night at 02:00 your extension re-prices the `Price Review Line` worksheet — roughly 2,000 rows whose selling price is recomputed from cost and markup. Most nights only about 120 rows actually move; the rest already hold the right price. Yet the DBA's morning trace shows a statement for every single row — and on the rows that do change, the job somehow pays for two. The nightly window is gone before the job is.

Your job: the same prices and the same audit trail, at a cost that follows the changes, not the row count.

## Requirements

Your submission is the shipped table plus one codeunit — keep the table `"Price Review Line"` exactly as given (the tests seed and read it by name, and the SQL budget is calibrated for its shipped shape), keep all object IDs in the 50100–50199 range, and reference objects by name, never by ID.

Create a **codeunit** named `"Nightly Repricer"` with one public procedure:

```al
procedure RunRepricing(): Integer
```

Rules:

1. For every `Price Review Line` row, the correct selling price is `"Unit Cost"` × (1 + `"Markup %"` / 100), rounded to the nearest 0.01 (AL's default rounding). A negative `"Markup %"` is a markdown and follows the same formula.
2. Every row whose stored `"Unit Price"` differs from that computed price gets the computed price written to `"Unit Price"`. The procedure returns the number of rows it changed. No row is inserted or deleted.
3. Rows already holding the computed price come out of the call **untouched** — not merely equal-looking, but never written. Any write, even one that stores identical values, stamps the row's `SystemModifiedAt`, and the tests compare that exact stored value before and after the call.
4. An empty worksheet, or one where every row is already right, returns 0 — and the procedure never raises an error in either case.
5. **The statement budget:** the graded call runs over 350–450 seeded rows, of which exactly one in five is stale, and must execute at most **the number of stale rows + 40** SQL statements, measured via `SessionInformation.SqlStatementsExecuted` around a single call. The trace's write-everything loop spends one statement per row and blows that several times over — and even a loop that writes only the stale rows can quietly pay a second statement per write and still miss the ceiling. Finding where that hidden statement comes from is the second half of this task.

## What the tests check

The grading tests seed `Price Review Line` rows with generated costs, markups (including a fixed markdown row), and prices, so hardcoded answers fail. They assert that every stale row ends up holding exactly its computed price, that the return value counts exactly those rows, and that the pass neither inserts nor deletes rows; rows seeded as already correct must keep the exact `SystemModifiedAt` value they had before the call (captured before the run, compared after a short clock tick), so any write to them — even a value-identical one — fails; an empty worksheet and an all-correct worksheet both return 0 without an error. The budget test seeds 350–450 rows with every fifth row stale, runs one throwaway call to absorb one-time metadata statements, restores the stale prices, resets the codeunit instance so remembered state cannot subsidize the graded call, and snapshots `SessionInformation.SqlStatementsExecuted` around one graded call, which must both reprice exactly the stale rows and stay within stale rows + 40 statements.

## Learn More

- [System fields](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields) — what `SystemModifiedAt` promises and exactly when the platform stamps it.
- [Record.Modify method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method) — what one `Modify` call does, and therefore what each one costs.
- [SessionInformation data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-data-type) — the counter the statement budget is measured with.
- [Performance articles for developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer) — the wider map of efficient data access in AL.
