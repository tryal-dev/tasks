# Distinct Values Without a Query

Your warehouse streams IoT sensor readings into one ledger-style table — thousands of rows, one per reading. Devices self-register simply by sending: there is no device master table anywhere, so the readings themselves are the only record of which devices exist. The monitoring dashboard needs the list of devices that have ever reported, and the current helper builds it by scanning every single reading. The DBA has opinions: a list of about twenty codes should not cost ten thousand rows.

## Requirements

Your submission is the shipped table plus one codeunit — keep the table `"Sensor Reading"` exactly as given (the tests seed it by name), keep all object IDs in the 50100–50199 range, and reference objects by name, never by ID.

Create a **codeunit** named `"Device Directory"` with one public procedure:

```al
procedure GetDeviceCodes(var DeviceCodes: List of [Code[20]])
```

Rules:

1. After the call, `DeviceCodes` holds every device code that appears on at least one `Sensor Reading` — each code exactly once, no matter how many readings carry it.
2. Readings with a blank `"Device Code"` are malformed and must be ignored — the empty code never appears in the list.
3. The list comes back sorted ascending — the natural sort order of a `Code` field.
4. Whatever the list contained before the call is discarded — the procedure rebuilds it from scratch.
5. When the table holds no readings at all, the list comes back empty; the procedure never raises an error.
6. **The row budget:** one call must read **at most 3,000 rows** (`SessionInformation.SqlRowsRead`). Grading seeds roughly 10,000 readings spread over about 20 devices — an implementation that visits every reading reads them all and fails.

Solve it with record operations inside the codeunit. A Query object with a grouped dataitem would sidestep the whole exercise — the tests cannot detect one (not graded), but the point here is the record-level technique, for all the real-world spots where a one-off query object is not an option.

## What the tests check

The grading tests seed `Sensor Reading` rows under `TRYAL-*` device codes; codes and per-device reading counts are generated fresh each run, so hardcoded answers fail. Readings are inserted in an order hostile to "first seen" collection — the device that sorts first is inserted last — so a scan that reports codes in `"Entry No."` order without sorting fails the order check. Blank-code readings are planted next to real ones, a pre-filled list is passed in to verify it gets rebuilt, and the empty-table case must come back empty without an error. The budget test seeds ~10,000 readings across 18–20 devices, warms caches with one throwaway call, then invalidates the server's data cache — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle a full scan past the budget — and snapshots `SessionInformation.SqlRowsRead` around a second call on the same codeunit instance, which must both return the correct list and stay within the 3,000-row budget. Between the two calls a brand-new device reports for the first time, and the second call must include it: the procedure reads the table on every call, so an answer memoized inside the codeunit from an earlier call is stale and fails.

## Learn More

- [Table keys](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys) — how keys and sorting shape the order records come back in.
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server) — what Find, FindSet, and Next actually cost on the wire.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the collection type the procedure fills.
- [SessionInformation data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-data-type) — the counters the row budget is measured with.
