# Insert the Batch, Don't Interrogate It

Every night a marketplace connector hands your extension a batch of external reference keys to stage for import. The importer stages each key once — keys already staged, or repeated inside the same batch, are skipped — and stamps every new row with a running line number. In the pilot the nightly run was instant; now that batches have grown, it drags, and the DBA's trace shows why: this time it's the **write** side chatting. For every single candidate key the importer fires one SELECT at the staging table and then one INSERT — two round trips per row, all night long.

Your job: the same rows and the same numbers, in a handful of statements.

## Requirements

Your submission is the shipped table plus one codeunit — keep the table `"Import Staging"` exactly as given (the tests seed and read it by name, and the SQL budget is calibrated for its shipped shape), keep all object IDs in the 50100–50199 range, and reference objects by name, never by ID.

Create a **codeunit** named `"Staging Importer"` with one public procedure:

```al
procedure ImportBatch(ExternalNos: List of [Code[20]]): Integer
```

Rules:

1. Walk `ExternalNos` in list order. For each entry: if no `Import Staging` row with that `"External No."` exists yet, insert one; otherwise skip the entry. "Exists" covers both rows that were in the table before the call **and** rows inserted earlier in the same call — a key repeated inside the batch is inserted exactly once, at its first position.
2. Each inserted row's `"Line No."` continues one running sequence: the first row this call inserts gets the highest `"Line No."` already in the table before the call (0 for an empty table) plus 1, the next plus 2, and so on. Skipped entries consume no number — the inserted rows are numbered consecutively with no gaps.
3. Rows that already exist are left completely untouched: their `"Line No."` must still hold its old value after the call.
4. The procedure returns the number of rows this call inserted. An empty list returns 0; a batch whose keys are all staged already returns 0 — and the procedure never raises an error in either case.
5. **The statement budget:** one call importing a batch of 25–30 new keys (plus a few already-staged ones mixed in) must execute **at most 15 SQL statements**. Grading measures `SessionInformation.SqlStatementsExecuted` around a single call: the two-round-trips-per-row importer from the trace above spends 50+, and even one statement per candidate row is double the budget. The database must not be asked about — or written to — one row at a time.

## What the tests check

The grading tests seed `Import Staging` rows under `TRYAL-*` keys; batch sizes and pre-existing line numbers are generated fresh every run, so hardcoded answers fail. They assert the exact final row set and the exact `"Line No."` per key: new keys numbered consecutively in list order, numbering continuing from the highest pre-existing line number (gaps in the old numbering don't restart it), already-staged keys skipped without consuming a number and with their rows untouched, a key repeated inside one batch inserted once at its first position, and an empty or all-existing batch returning 0 without an error. The budget test seeds a few staged rows, runs one throwaway batch to warm caches, then clears the codeunit instance, so state remembered from the warm-up call cannot subsidize the graded call. It also invalidates the server's data cache — a read served from cache memory costs zero SQL, so cached reads can't smuggle per-row chatter past the budget — and then snapshots `SessionInformation.SqlStatementsExecuted` around one graded call importing 25–30 new keys plus already-staged decoys, which must both produce exactly the right rows and numbers and stay within the 15-statement budget.

## Learn More

- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — what the write methods do, and what their optional return value means.
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server) — what each database call actually costs on the wire.
- [SessionInformation data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-data-type) — the counter the statement budget is measured with.
- [Performance articles for developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer) — the wider map of efficient data access in AL.
