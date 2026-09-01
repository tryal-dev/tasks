# Sales per Salesperson, Without the Chatter

Finance runs the commission report every Monday. It used to be instant; now that the company has thousands of customers it takes minutes, and the DBA's trace shows why: a wall of nearly identical tiny SELECT statements, one per customer. The numbers are right — the report is just having thousands of little conversations with the database instead of one.

Your job: same numbers, a handful of statements.

## Requirements

Create a **codeunit** named `"Salesperson Sales Report"` with one public procedure:

```al
procedure TotalSalesBySalesperson(SalespersonFilter: Text): Dictionary of [Code[20], Decimal]
```

Rules:

1. Consider every `Customer` whose `"Salesperson Code"` matches `SalespersonFilter` — an AL filter expression for a Code field. The tests use simple patterns like `TRYAL-P1*` or a single code; the filter is never empty.
2. The dictionary holds one key per distinct `"Salesperson Code"` found on those customers — each **exactly once**, and only codes that at least one matching customer actually carries. A salesperson who exists in the Salesperson/Purchaser table but owns no matching customer must not appear.
3. Each value is the sum of `"Sales (LCY)"` across every `Cust. Ledger Entry` of that salesperson's matching customers (entries are linked to customers by `"Customer No."`), added up over **all** their customers. Negative entries reduce the total.
4. Group by the salesperson on the **customer card**. Ledger entries carry a `"Salesperson Code"` of their own — stamped at posting time, possibly stale — and the tests deliberately seed entries whose stamp points at a different salesperson. The stamp must be ignored.
5. A salesperson whose customers have no ledger entries at all still appears — with a total of exactly 0.
6. A filter that matches no customer returns an empty dictionary. The procedure never raises an error.
7. **The statement budget:** one call must execute **at most 4 SQL statements**, no matter how many customers match. Grading measures `SessionInformation.SqlStatementsExecuted` around a single call with a dozen-plus salespersons and two customers each — an implementation that goes back to the database once per customer spends 25+ statements and fails. The ceiling also holds when every matching customer has no entries at all: an all-zero report is still one conversation, not a rescue loop.
8. **The row budget:** the same call must read **at most 50 rows**, measured with `SessionInformation.SqlRowsRead` around a call whose customers hold a couple hundred ledger entries between them. Dragging every entry across the wire to add it up in AL reads them all and fails — even when it happens in a single statement. Let the database do the adding.

## What the tests check

The grading tests seed salespersons, customers and ledger entries marked `TRYAL-*`; amounts and the number of salespersons are generated fresh every run, so hardcoded answers fail. Decoys are planted: an entry whose own `"Salesperson Code"` stamp points at the wrong salesperson, a customer outside the filter, and a salesperson master record with no customers. One salesperson's customers have no entries at all and must come back as 0; one entry is negative and must reduce the total. One test filters on a single exact code instead of a pattern. The tests assert **exact dictionary contents** — keys, counts and totals. The budget tests warm the caches with one throwaway call, then invalidate the server's data cache — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle the chatter past the budget — and snapshot the `SessionInformation` counters around a second call: statement count on wide data, statement count again when the correct answer is all zeros, and rows read on entry-heavy data. The tests run in a real company with existing data, so your result must be driven purely by the filter and the rules above.

## Learn More

- [Query object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object)
- [Linking and Joining Data Items to Define the Query Dataset](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-links-joins)
- [Aggregating data in query objects](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-totals-grouping)
- [DataItemLink property (query)](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemlink-query-property)
- [Query objects and performance](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-query-objects-and-performance)
