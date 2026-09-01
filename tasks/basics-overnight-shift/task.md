# The Night Shift Bug

The parcel depot runs at night: it opens at 22:00 and closes at 06:00 the next morning. The first "are we open?" check was copied from a daytime shop, so it insists that 01:00 is outside a 22:00–06:00 window and that the night shift is minus sixteen hours long. Your job is three small procedures that get windows crossing midnight right — and that refuse the undefined time `0T` with a clear message instead of a runtime crash.

## Requirements

Create a **codeunit** named `"Depot Hours"` with three public procedures:

```al
procedure IsOpen(At: Time; OpensAt: Time; ClosesAt: Time): Boolean
procedure ShiftMinutes(StartTime: Time; EndTime: Time): Integer
procedure MinutesUntilClose(At: Time; OpensAt: Time; ClosesAt: Time): Integer
```

Rules:

1. An opening window runs from `OpensAt` to `ClosesAt`. When `ClosesAt` is later on the clock than `OpensAt` it is a daytime window (08:00–17:00). When `ClosesAt` is earlier on the clock than `OpensAt` the window crosses midnight: 22:00–06:00 covers 22:00 up to midnight and midnight up to 06:00.
2. `IsOpen` returns `true` when `At` lies inside the window. The opening instant is open and the closing instant is closed: for 22:00–06:00, 22:00 exactly is open, 23:30 and 01:00 are open, 06:00 exactly is closed, 07:00 is closed.
3. When `OpensAt` equals `ClosesAt` the depot is open round the clock: `IsOpen` returns `true` for every `At`, including `At` equal to that shared time.
4. `ShiftMinutes` returns the length of a shift in whole minutes from `StartTime` to `EndTime`, wrapping past midnight when `EndTime` is earlier on the clock: 22:00 to 06:00 is 480, 08:00 to 16:30 is 510, 23:59 to 00:01 is 2. Leftover seconds are dropped, never rounded up: 08:15:15 to 09:00:00 is 44. A shift whose `EndTime` equals its `StartTime` is 0 minutes long — a shift is a duration, so equal times mean nothing happened, unlike the round-the-clock rule for a window.
5. `MinutesUntilClose` returns 0 when the depot is closed at `At` (rule 2 decides, so exactly at `ClosesAt` it is 0). Otherwise it returns the whole minutes from `At` until the clock next reads `ClosesAt`, counting past midnight when needed: for 22:00–06:00, 23:30 gives 390 and 01:00 gives 300. "Next" means strictly in the future, so in a round-the-clock window `At` equal to `ClosesAt` gives a full 1440.
6. `0T` is the undefined time: adding to it or subtracting it is a runtime error, and the runtime's own message is not what a user should see. Every procedure must check its `Time` parameters first and, when any of them is `0T`, call `Error` with a message that contains the text `undefined time (0T)` — for example `StartTime is an undefined time (0T).`

What you need from AL: `Time` values compare with the ordinary `<`, `>=` and `=` operators; `Time - Time` gives the difference in milliseconds as an `Integer`, negative when the left value is earlier on the clock; `Time + Integer` moves a time forward by that many milliseconds; `div` divides two integers and throws the remainder away. A minute is 60 × 1000 milliseconds and a day is 24 × 60 × 60 × 1000.

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The `IsOpen` tests use the 22:00–06:00 window at 22:00, 23:30, 01:00, 06:00 and 07:00, an 08:00–17:00 window at exactly 08:00 (open), at a generated minute inside it, at exactly 17:00 (closed) and at 06:00 and 19:00 outside it, and two round-the-clock windows: 00:00–00:00 at a generated minute and 06:00–06:00 at exactly 06:00. `ShiftMinutes` is checked with a generated daytime length (08:00 plus 1–600 minutes), 22:00–06:00 (480), 23:59–00:01 (2), a generated time paired with itself (0) and 08:15:15–09:00:00 (44 — seconds dropped, not rounded). `MinutesUntilClose` expects 390 at 23:30 and 300 at 01:00 for 22:00–06:00, 0 at 06:00 and at 07:00, the exact remaining minutes at a generated minute inside 08:00–17:00 and 0 at exactly 17:00, 180 at 21:00 in a 00:00–00:00 window and 1440 at 06:00 in a 06:00–06:00 window. Finally, every `Time` parameter of every procedure is tried with `0T` in turn (`At`, `OpensAt` and `ClosesAt` for `IsOpen` and `MinutesUntilClose`; `StartTime` and `EndTime` for `ShiftMinutes`), with the other arguments defined, and each call must fail with an error message that contains `undefined time (0T)` — the test shows the actual error text when it does not match.

## Learn More

- [Time data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/time/time-data-type) — the `hhmmssT` literal syntax and what `0T` means.
- [Arithmetic operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-arithmetic-operators) — the type table that says `Time - Time` is an `Integer` of milliseconds, `Time + Integer` is a `Time`, and that `0T` is a runtime error.
- [AL operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-operators) — `div`, `mod` and the comparison operators, with their precedence.
- [Dialog.Error(Text [, Any,...]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method) — raising your own error with a placeholder for the parameter name.
