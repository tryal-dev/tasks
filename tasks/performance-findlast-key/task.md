# Latest Entry, One Read

Support has a "latest activity" box on the document inquiry page: for any document number, it shows the most recent customer ledger entry posted under it. The helper behind it works — and the DBA hates it: for a document with sixty entries it drags all sixty across the wire just to keep one of them. The newest entry is one row; fetching it should cost one row.

## Requirements

Create a **codeunit** named `"Latest Entry Finder"` with one public procedure:

```al
procedure FindLatest(DocumentNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
```

Rules:

1. Consider every `Cust. Ledger Entry` whose `"Document No."` equals `DocumentNo` exactly — entries of other documents must never leak in, however recent they are.
2. The latest entry is the one with the **highest `"Entry No."`** — entry numbers only grow, so the biggest number is the newest posting.
3. When at least one entry matches, return `true` and hand that latest entry back in `CustLedgerEntry` — the tests read `"Entry No."` and `"Sales (LCY)"` from it.
4. When no entry matches, return `false`. The procedure never raises an error, even when the table is full of entries for other documents.
5. **The row budget:** one call must read **at most 10 rows** (`SessionInformation.SqlRowsRead`), no matter how many entries the document has. Grading seeds a document with dozens of entries — walking them all to find the newest reads every one and fails.
6. **The statement budget:** the same call must execute **at most 3 SQL statements** (`SessionInformation.SqlStatementsExecuted`). Going back to the database once per entry can never fit.

## What the tests check

The grading tests seed ledger entries under `TRYAL-*` document numbers; amounts and entry counts are generated fresh every run, so hardcoded answers fail. The newest entry of the multi-entry document deliberately carries the smallest amount, so "biggest amount" is not "latest". A decoy is planted: an entry posted later under a different document number, which must not win over the requested document's own latest entry. One document has no entries at all and must come back `false` while other documents' entries exist. The budget tests warm the caches with one throwaway call, then invalidate the server's data cache — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle the chatter past the budget — and snapshot the `SessionInformation` counters around a second call: rows read on an entry-heavy document, and statement count on the same shape of data. The tests run in a real company with existing data, so your result must be driven purely by the `"Document No."` filter.

## Learn More

- [Record.FindLast() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findlast-method)
- [Record.SetCurrentKey(Any [, Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method)
- [Table keys](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys)
- [Table Keys and Performance in Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-table-keys-and-performance)
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server)
