# Yes or No, Not the Whole Table

The customer list got a little activity panel: does this customer have open ledger entries, how many, and is the customer dormant? It looked instant in the demo company. On the production database, where a busy customer carries hundreds of ledger entries, scrolling the list now crawls — the trace shows every entry being dragged into AL just to produce a yes/no or a single number.

Your job: same three answers, at row-one prices.

## Requirements

Create a **codeunit** named `"Customer Activity Check"` with three public procedures:

```al
procedure HasOpenEntries(CustomerNo: Code[20]): Boolean
procedure IsDormant(CustomerNo: Code[20]): Boolean
procedure OpenEntryCount(CustomerNo: Code[20]): Integer
```

Rules:

1. `HasOpenEntries` returns `true` exactly when at least one `Cust. Ledger Entry` with `"Customer No."` = `CustomerNo` has `Open` = `true`. Closed entries don't count, and a customer with no entries at all returns `false`.
2. `IsDormant` returns `true` exactly when the customer has no `Cust. Ledger Entry` at all — open or closed. A single closed entry is history enough: it must return `false`.
3. `OpenEntryCount` returns how many `Cust. Ledger Entry` records of that customer have `Open` = `true` — exactly, and `0` when none are open.
4. Entries belonging to other customers must never influence any of the three answers.
5. None of the procedures ever raises an error — a customer number with no entries is a normal input, not a failure.
6. **The budget:** one call to any of the three procedures must execute **at most 5 SQL statements** and read **at most 10 rows**, no matter how many ledger entries the customer has. Grading measures `SessionInformation.SqlStatementsExecuted` and `SessionInformation.SqlRowsRead` around a single call while the customer holds a couple hundred entries — an implementation that fetches the entries into AL to inspect or count them reads them all and fails.

## What the tests check

The grading tests create real customers through the standard number series — the graded customer numbers differ from run to run, so an answer keyed to a specific customer number or a hardcoded count has nothing stable to latch onto — and seed `Cust. Ledger Entry` rows for them directly; the counting test asserts the exact number of open entries it seeded. Decoys are planted: closed entries sitting next to open ones, and a neighbour customer whose entries must not leak into your answers. The three budget tests warm the caches with one throwaway call, then invalidate the server's data cache — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle row-by-row work past the budget — and snapshot the `SessionInformation` counters around one graded call per procedure: `HasOpenEntries` on a customer whose ~200 entries are all closed, `IsDormant` on a customer with ~150 entries, and `OpenEntryCount` on a customer with well over 100 open entries. The tests run in a real company with existing data, so your answers must be driven purely by the customer number and the rules above.

## Learn More

- [Record.IsEmpty() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-isempty-method)
- [Record.Count() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-count-method)
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server)
- [Performance articles for developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer)
