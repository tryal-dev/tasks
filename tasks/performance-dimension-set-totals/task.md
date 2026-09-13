# Totals by a Dimension Nobody Made Global

Finance tags every posting with a REGION dimension, but the two global dimension slots went to DEPARTMENT and PROJECT years ago. So REGION is not one of the shortcut columns on `G/L Entry`; it exists only inside each entry's dimension set, reachable through `"Dimension Set ID"`. The controller wants an account's net change broken down by the values of that dimension, and the first draft of the report drags: the DBA's trace shows the same tiny lookup against the dimension tables fired once per entry.

Your job: same numbers, a handful of statements.

## Requirements

Create a **codeunit** named `"Dimension Set Totals"` with one public procedure:

```al
procedure NetChangeByDimensionValue(GLAccountNo: Code[20]; DimensionCode: Code[20]): Dictionary of [Code[20], Decimal]
```

Use object IDs in the range 50100–50199 and reference every other object by name, never by ID.

Rules:

1. Consider every `G/L Entry` whose `"G/L Account No."` equals `GLAccountNo`. `GLAccountNo` always names an existing G/L account. Entries on other accounts never count, even when they carry the very same dimension set.
2. An entry belongs to a dimension value when the dimension set its `"Dimension Set ID"` points at holds an entry for `DimensionCode`; that set entry's `"Dimension Value Code"` is the dictionary key. An entry whose set holds no value for `DimensionCode` — including an entry with `"Dimension Set ID"` 0 — is skipped entirely: it never produces a key, not even a blank one.
3. Each value's number is the sum of `Amount` over its entries, across every dimension set that contains the value. Credits are negative amounts and reduce the sum; no rounding is applied.
4. A key appears **if and only if** at least one matching entry carries the value. A value whose entries net to exactly 0 still appears, with 0. A value that merely exists in the `Dimension Value` table, or whose dimension sets are used only on other accounts, does not appear.
5. `DimensionCode` is never one of the two global dimensions, so the `"Global Dimension 1 Code"` and `"Global Dimension 2 Code"` columns on the entry are not where its value lives. The tests plant an entry whose shortcut columns spell the value code while its dimension set holds no value for the dimension — it must stay out. Likewise, another dimension may own a value with the very same code; only `DimensionCode`'s own value counts.
6. Totals are read from the ledger at call time: an entry — even one carrying a brand-new dimension set — added between two calls on the same codeunit instance shows up in the second result. Nothing may be remembered across calls.
7. A call that matches no entry returns an empty dictionary. The procedure never raises an error.
8. **The statement budget:** one call must execute **at most 15 SQL statements**, no matter how many entries the account holds or how many distinct dimension sets they spread across. Grading measures `SessionInformation.SqlStatementsExecuted` around a single call on an account with a couple of hundred entries spread over roughly 30–40 distinct dimension sets: one lookup per entry — or even one per **distinct** set, however cleverly memoised — spends 30+ and fails.

## What the tests check

The grading tests create fresh dimensions, dimension values, dimension sets and G/L accounts every run and seed `G/L Entry` rows directly, with amounts, value counts and set counts generated fresh, so hardcoded answers fail. They assert exact per-value net changes across values that live in several dimension sets, that values stay separate, that credits reduce the sum, and that entries netting to exactly 0 still yield a key with 0. Decoys are planted: an entry on another account carrying the same set, an entry with `"Dimension Set ID"` 0, an entry whose set holds only another dimension, an entry whose global-dimension shortcut columns spell the value code while its set does not, another dimension's value with the identical code, a value with sets used only elsewhere, and a value that exists only as a master record. An account with no entries must come back as an empty dictionary, and so must a dimension that no dimension set has ever used — neither may raise an error. One test calls the procedure twice on the same codeunit instance and inserts an entry with a brand-new dimension set in between: the second call must include it. The budget test warms the caches with one throwaway call on a separate account and a separate dimension, only then seeds the graded entries and sets, and clears the codeunit variable before measuring — so the graded call meets dimension sets no earlier call has resolved, and state kept between calls, in the instance or anywhere else, cannot subsidise the budget. It also invalidates the server's data cache with decoy writes — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle the chatter past the budget — and then snapshots the `SessionInformation` counter around a second call. The tests run in a real company with existing data, so your result must be driven purely by the account filter, the dimension code and the rules above.

## Learn More

- [Dimension Set Entries Overview](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-dimension-set-entries-overview) — how a dimension set is stored and what a `Dimension Set ID` on an entry actually points at.
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — the return type, and the natural home for whatever you look up once.
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server) — which AL calls cost a statement, and why a loop of single-record reads is the expensive shape.
- [SessionInformation data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-data-type) — the counters the budget test reads; handy for measuring your own draft.
