# Over the Threshold, Under Budget

Marketing runs a "big buyers" extract after every campaign: which customer numbers bought for more than a threshold amount inside the campaign window? The current extract crawls — the trace shows the server quietly computing a sales sum for one customer row after another — and last quarter it missed a company entirely: their customer card had been deleted in a data cleanup, but their postings are still sitting in the ledger, where the extract never looked.

Your job: the same answer, read straight off the ledger, in a handful of statements.

## Requirements

Create a **codeunit** named `"Top Customer Finder"` with one public procedure:

```al
procedure CustomersOverThreshold(FromDate: Date; ToDate: Date; ThresholdLCY: Decimal): List of [Code[20]]
```

Rules:

1. Consider every `Cust. Ledger Entry` whose `"Posting Date"` lies in the window `FromDate..ToDate` — both boundary dates inclusive.
2. Sum `"Sales (LCY)"` over those entries per `"Customer No."`; a customer number qualifies when its window sum is **strictly greater** than `ThresholdLCY`. A customer netting to exactly the threshold stays out.
3. Negative entries (credit memos) reduce the sum; skipping them is wrong — a credit memo can drag an otherwise qualifying customer back under the threshold.
4. Entries outside the window never count. A customer whose only postings lie outside the window must not appear, no matter how large those postings are.
5. The returned list holds each qualifying `"Customer No."` **exactly once**, in any order.
6. The ledger is the source of truth, not the customer list: a `"Customer No."` that appears on ledger entries but has **no `Customer` card** (deleted after posting, half-finished migrations) must still be reported when its window sales qualify.
7. A window in which nothing qualifies returns an empty list. The procedure never raises an error.
8. Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.
9. **The statement budget:** one call must execute **at most 8 SQL statements**, no matter how many customers post in the window. Grading measures `SessionInformation.SqlStatementsExecuted` around a single call in a window where 25+ customers posted — an implementation that has one conversation with the database per customer spends 25+ statements and fails.

## What the tests check

The grading tests seed customers and mock their ledger entries in far-future date windows, with amounts and thresholds generated fresh every run, so hardcoded answers fail. The fixtures cover every rule: a customer netting to exactly the threshold must stay out, a credit memo must drag a customer back under, entries exactly on both boundary dates must count while entries one day outside must not, a customer with postings only outside the window must not appear, and a customer number whose `Customer` card does not exist must still be reported — an answer assembled by walking the customer list, however its sales are computed, misses that one. The tests assert exact list contents: membership and count, each qualifying number exactly once. The budget test seeds 25+ posting customers, warms the caches with one throwaway call, then invalidates the server's data cache — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle per-customer chatter past the budget — and snapshots `SessionInformation.SqlStatementsExecuted` around a second call: the list must still be exact **and** the call must stay within the 8-statement ceiling. The tests run in a real company with existing data, so your result must be driven purely by the window, the threshold, and the rules above.

## Learn More

- [FlowFields overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields) — what a calculated field really is, and what it costs to evaluate one.
- [Troubleshooting: long-running SQL queries involving FlowFields](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/troubleshooting-queries-involving-flowfields-by-disabling-smartsql) — how the server folds FlowField calculations into its SQL, and why that work is easy to miss in a trace.
- [Data access](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-data-access) — how AL reads translate to SQL statements, including what filtering on a FlowField compiles into.
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server) — which record operations cost a round trip, and how to spend fewer of them.
