# Total Without a Loop

The service desk has a "lifetime sales" lookup: type a customer number, get the total they have ever spent. For small customers it is instant; for the big retail chains it visibly hangs, and the trace shows why — the lookup drags every single ledger entry of the customer across the wire just to add them up, one row at a time. The number is right. The bill for computing it is not.

Your job: the same number, a handful of rows.

## Requirements

Create a **codeunit** named `"Customer Sales Total"` with one public procedure:

```al
procedure TotalSales(CustomerNo: Code[20]): Decimal
```

Rules:

1. Return the sum of `"Sales (LCY)"` across every `Cust. Ledger Entry` whose `"Customer No."` equals `CustomerNo`.
2. Entries belonging to other customers must never leak into the total — the tests plant some.
3. Negative entries (credit memos) reduce the total; they must not be skipped.
4. A customer with no ledger entries at all returns exactly 0. The procedure never raises an error — the number passed in may not even correspond to an existing `Customer` record, and the answer is still 0.
5. **The row budget:** one call must read **at most 10 rows** from the database, no matter how many entries the customer has. Grading measures `SessionInformation.SqlRowsRead` around a single call for a customer holding well over a hundred entries — an implementation that fetches every entry so AL can add them up reads them all and fails. Let the database do the adding.

## What the tests check

The grading tests create customers and mock their ledger entries with amounts generated fresh every run, so hardcoded answers fail. Decoys are planted: a second customer whose entries must stay out of the total, and a negative entry that must reduce it. One test asks for a customer with no entries and expects exactly 0; another passes a number that matches no `Customer` record at all and still expects 0, not an error. The budget test seeds 120+ entries, warms the caches with one throwaway call, then invalidates the server's data cache — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle the row-by-row loop past the budget — and snapshots `SessionInformation.SqlRowsRead` around a second call: the total must still be exact **and** the call must stay within the 10-row ceiling. The tests run in a real company with existing data, so your result must be driven purely by the customer number and the rules above.

## Learn More

- [Record.CalcSums(Any [, Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcsums-method)
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods)
- [SumIndexField Technology (SIFT)](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-sift-technology)
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server)
- [Performance articles for developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer)
