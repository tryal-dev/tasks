# Setup Table Done Right

Every shipment your extension touches asks the same two questions — which carrier is the default, and how heavy may a package be. The answers live in a one-row setup table, and the profiler shows the same innocent one-row read firing on every single call, thousands of times a day, always returning the same row. The classic fix: read the row once per session, serve every later request from memory, and offer an explicit way to invalidate when the setup actually changes.

## Requirements

The starter ships the singleton setup table `"Dispatch Setup"`: one row keyed by `"Primary Key"` (`Code[10]`, always empty), carrying `"Default Carrier Code"` (`Code[20]`) and `"Max Package Weight"` (`Decimal`). Include the table in your submission unchanged — the tests read and write its fields by name.

Create a **codeunit** named `"Dispatch Setup Mgt."` with two public procedures:

```al
procedure GetSetup(var DispatchSetup: Record "Dispatch Setup")
procedure Invalidate()
```

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

Rules:

1. When a read is needed and no setup row exists, `GetSetup` creates it — the empty primary key, all other fields at their defaults — and the row must really be inserted into the table, not just fabricated in memory.
2. When the row exists, `GetSetup` returns exactly the values stored in it, and never overwrites it or inserts a second one: whatever the starting point, the table holds exactly one row afterwards.
3. Once one call has read (or created) the row, every later `GetSetup` call in the session is served from a copy kept in memory: it executes no SQL, and a change written straight to the table is deliberately **not** visible through `GetSetup` until someone invalidates. The tests check the stale value on purpose — returning the fresh value there is a failure, not a courtesy.
4. The cached copy belongs to the **session**, not to a codeunit variable: the tests warm the cache through one `"Dispatch Setup Mgt."` variable and read through a different, freshly declared one — the second variable must be served from the very same cache.
5. `Invalidate` drops the cached copy. The next `GetSetup` call reads the table again — picking up changes written directly to it, and re-creating the row if it has meanwhile been deleted.
6. **The statement budget:** after one warm-up call, a burst of `GetSetup` calls must execute **0 SQL statements** in total. Grading snapshots `SessionInformation.SqlStatementsExecuted` around each of 10 calls made through a cold codeunit variable, and the server's data cache is deliberately knocked out before every one of them — so a per-call read of the table cannot hide behind cached results: it pays a real statement every time and blows the budget on the first call.

## What the tests check

The setup values are generated fresh every run, so hardcoded answers fail. The tests check: that the first call on an empty table inserts exactly one row with the empty primary key and default values, and returns it; that stored values come back exactly and an existing row is neither overwritten nor duplicated; that a value changed directly in the table stays invisible through `GetSetup` — both through the variable that warmed the cache and through a second, independent variable; that after `Invalidate` the next call returns the fresh values, and re-creates the row after a deletion; and the budget of rule 6. The budget test warms the cache through one variable, plants a decoy row and bumps the table's version before every measured call — a write invalidates the server's cached result sets, so a repeated read served from the data cache cannot smuggle per-call chatter past the counter — and then measures 10 calls through a different variable: at that point, memory is the only place the row can legally come from.

## Learn More

- [Data Access](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-data-access) — how the server's data cache serves repeated reads and what invalidates it: the machinery the budget test wields against a per-call read.
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server) — what each data-access method really costs on SQL Server.
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods) — `Get` semantics, including the return-value check the auto-create path hinges on.
- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — creating and updating the row safely.
