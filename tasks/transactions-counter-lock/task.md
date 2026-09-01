# A Counter That Never Skips or Repeats

Sooner or later every Business Central project grows a "give me the next number" helper — for ledger entry numbers, ticket ids, license plates. The naive version reads a counter, adds one and writes it back, and it works perfectly in the demo. In production it hands the same number to two sessions that read the counter at the same moment, or it continues from a value it read earlier in the transaction and silently skips or repeats. Your job is the version that never does either.

## The object you get

The starter ships one finished data object. Do not rename it or its fields — the grading tests bind to every name below character for character.

- Table `"Number Counter"` — primary key `"Counter Code"` (Code[20]); field `"Last Used No."` (Integer).

## Requirements

Implement both procedures in the codeunit `"Counter Allocator"`:

```al
procedure NextValue(CounterCode: Code[20]): Integer
procedure ReserveBlock(CounterCode: Code[20]; BlockSize: Integer): Integer
```

Rules:

1. `NextValue` returns the counter's next number — the row's `"Last Used No."` plus one — and saves the returned number back to the row before returning. Consecutive calls return consecutive numbers: no gaps, no repeats.
2. A counter that has no row yet starts at 1: the first allocation returns 1 and creates the row. This applies to both procedures.
3. `ReserveBlock` allocates `BlockSize` consecutive numbers in one call: it returns the first number of the block and advances `"Last Used No."` by `BlockSize`, so the block's last number is the new `"Last Used No."` and the next allocation after it starts one past the block. `ReserveBlock(Code, 1)` behaves exactly like `NextValue(Code)`.
4. A `BlockSize` smaller than 1 must fail with an error message that contains `must be positive`, and the counter row must not move.
5. No stale reads — every call reads the counter row's current state at the moment of the call. The tests update `"Last Used No."` directly between two allocator calls, and the second call must continue from the updated value, not from anything the allocator remembered.
6. The concurrency contract this task is really about: in production two sessions can call the allocator in the same instant, and an ordinary read lets both see the same `"Last Used No."` and hand out the same number. The same ordinary read has a second face: once the row sits in the server's data cache, it is served from the cache without touching SQL at all. Your read must not be that read — every allocation must fetch the counter row's current state straight from SQL, even when the row is already warm in the cache. This is graded: the tests warm the cache with the counter row, then measure the SQL rows a single call reads, through both procedures — a call whose read is served from the cache reads zero rows and fails. Grading runs in one session, so the probe proves the fresh fetch rather than the blocking itself, but the read style that always fetches fresh is the one that also locks the row against concurrent allocators — the hints name it if you have not met it yet.
7. The allocator runs inside the caller's transaction: raise no `Message`, `Confirm` or other dialog, and never call `Commit` — the grading tests roll the allocations back, and a `Commit` fails them.

## What the tests check

Each rule is enforced by one or more grading tests: a fresh counter starting at 1 (through both procedures), continuation from a seeded row with generated values (hardcoded answers won't survive), three consecutive calls in a row, the returned value being persisted on the row, the direct-update-between-calls check from rule 5, two counters advancing independently of each other, block arithmetic (first value returned, row value after, and the first value allocated after the block), a block of exactly 1, rejection of both a zero and a negative `BlockSize` with the counter left untouched, and the rule-6 cache probe through both procedures: with the counter row already sitting warm in the server's data cache, a single allocation must still read at least one row from SQL — a call whose read is served entirely from the cache fails. Error-text matching is case-insensitive, but the quoted phrase must appear exactly as written.

## Learn More

- [Record.LockTable([Boolean] [, Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-locktable-method)
- [Record Instance Isolation Level](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-read-isolation)
- [Tri-State Locking in Database](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-tri-state-locking)
- [Data Access (Business Central Server Data Caching)](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-data-access)
- [Database.SelectLatestVersion() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-selectlatestversion-method)
