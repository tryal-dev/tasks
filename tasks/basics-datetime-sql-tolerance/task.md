# Detect Real Changes Despite SQL DateTime Rounding

Your nightly sync job pushes changed customers to an external system by comparing each record's current "last modified" timestamp with the timestamp remembered at the previous sync — and every night it re-emits thousands of records nobody touched.

The culprit is the database, not the sync: SQL Server's `datetime` type keeps only 1/300-second precision, so the milliseconds of a stored value snap to `.000`, `.003` or `.007`. A timestamp can change by a few milliseconds just by being written and read back, and a strict `=` or `<>` on DateTime values then fails at random — exactly what the LinterCop rule LC0029 warns about.

Your job is a comparison codeunit that treats two timestamps within SQL rounding noise as the same moment, so the sync only re-emits real changes.

## Requirements

Create a **codeunit** named `"DateTime Change Detector"` with two public procedures:

```al
procedure IsSameMoment(First: DateTime; Second: DateTime): Boolean
procedure ShouldResync(CurrentModifiedAt: DateTime; LastSyncedModifiedAt: DateTime): Boolean
```

Rules:

1. `IsSameMoment` returns `true` when the two timestamps differ by **strictly less than 10 milliseconds** in either direction — a drift of 0, 3 or 9 ms is the same moment; a gap of exactly 10 ms or more is a different moment.
2. An undefined timestamp (`0DT`) is the same moment **only** as another undefined timestamp: `IsSameMoment` with one `0DT` and one real value returns `false`, in either argument order; with two `0DT` values it returns `true`.
3. `ShouldResync` returns `true` when `LastSyncedModifiedAt` is `0DT` — a record that has never been synced is always emitted.
4. Otherwise `ShouldResync` returns `true` exactly when the two timestamps are **not** the same moment by the rules above — SQL drift alone must never trigger a resync.
5. Neither procedure may raise an error, whatever combination of values it receives.

You can get there with plain DateTime arithmetic (subtracting two DateTimes yields a `Duration` — the difference in milliseconds) or with a ready-made helper from the Base Application; the tests only grade the behavior above.

## What the tests check

The grading tests call both procedures with fixed and randomly generated timestamps: pairs 0, 3 and 9 ms apart must compare as the same moment and pairs exactly 10 ms and 20+ ms apart must not — each in both argument orders — and the `0DT` rules are checked in both directions. `ShouldResync` is graded with the current stamp ahead of the stored one, behind it, and undefined (`0DT`) against a real stored stamp. One test simulates a whole sync pass — stored stamps whose current values drifted by 0, 3, 9, 20 and 250 ms plus one never-synced record — and expects exactly the two real changes and the never-synced record to be emitted, no more and no fewer.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## Learn More

- [DateTime data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type) — how AL DateTime values are stored and which range SQL Server accepts.
- [Time data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/time/time-data-type) — its "Comparing time values" section documents Microsoft's own tolerance comparison for values that were rounded by SQL Server.
- [datetime (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/data-types/datetime-transact-sql) — why the milliseconds snap to `.000`, `.003` or `.007`.
- [Type Helper codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/codeunit/system.reflection.type-helper) — the Base Application helper whose `CompareDateTime` implements exactly this tolerance.
