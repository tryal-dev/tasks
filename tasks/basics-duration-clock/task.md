# Elapsed Time as hh:mm:ss

Service tickets carry a `"Reported At"` DateTime and an SLA measured in hours. The support dashboard needs four small calculations: how long a ticket has been open as a clock string, when its SLA runs out, how much time is left (or by how much it is overdue), and how many hours to bill for the work.

All four start from the same fact: subtracting one `DateTime` from another gives a `Duration` — a 64-bit whole number of milliseconds. That number is easy to work with once you stop treating it like text: `Format` on a Duration prints a sentence such as `1 day 2 hours 5 minutes`, never a clock. Dividing a Duration with `/` is decimal division, so whole hours, minutes and seconds come from `div` and `mod`, not from `/`.

## Requirements

Create a **codeunit** named `"SLA Clock"` with four public procedures:

```al
procedure Elapsed(StartDT: DateTime; EndDT: DateTime): Text
procedure Deadline(ReportedAt: DateTime; SlaHours: Integer): DateTime
procedure RemainingText(DeadlineAt: DateTime; AsOf: DateTime): Text
procedure BillableHours(StartDT: DateTime; EndDT: DateTime): Decimal
```

Rules:

1. `Elapsed` returns the time from `StartDT` to `EndDT` as `hh:mm:ss`: whole hours, a colon, two-digit minutes, a colon, two-digit seconds. Hours never wrap at 24 — 26 hours, 5 minutes and 9 seconds is `26:05:09`, not a day count. Hours are zero-padded to at least two digits and simply grow beyond that (`123:04:05`). Any remainder below a whole second is dropped, never rounded: 1 hour, 2 minutes and 3.999 seconds is `01:02:03`. Identical times give `00:00:00`.
2. `Deadline` returns `ReportedAt` moved forward by `SlaHours` hours. `SlaHours` is always a positive whole number; the result must cross midnight and month ends correctly.
3. `RemainingText` describes the time from `AsOf` to `DeadlineAt`. When `AsOf` is at or before the deadline, return `<hours>h <minutes>m` — hours unpadded and never wrapping at 24, minutes always two digits: `2h 05m`, `0h 00m`, `30h 15m`. When `AsOf` is strictly after the deadline, prefix the same text with `overdue by `: `overdue by 1h 10m`. In both directions any remainder below a whole minute is dropped, so 45 seconds past the deadline is `overdue by 0h 00m` and 2 hours, 5 minutes and 59 seconds before it is `2h 05m`.
4. `BillableHours` returns the elapsed time from `StartDT` to `EndDT` in decimal hours, rounded **up** to the next multiple of 0.25 — `Round` accepts a precision and a direction. Anything past a quarter-hour boundary, even a single second, rounds up: 2 hours and 1 second bills as `2.25`, and 1 hour 46 minutes bills as `2.00` (not the nearest quarter, `1.75`). An exact multiple of a quarter hour stays where it is: exactly 2 hours bills as `2.00`, identical times bill `0`.
5. Every procedure raises an error with a message that contains `must be set` when any of its DateTime arguments is `0DT`. This check comes first: an unset `EndDT` is reported as `must be set`, never as "before the start".
6. `Elapsed` and `BillableHours` raise an error with a message that contains `before the start time` when `EndDT` is earlier than `StartDT`. Equal times are not an error.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The grading tests call each procedure with fixed instants and with generated ones, all in January–March 2025 and never `CurrentDateTime`. `Elapsed` is checked from 31 January 22:00:00 to 2 February 00:05:09 (expects exactly `26:05:09`), for identical times, for a span of 3,723,999 milliseconds (expects `01:02:03`), and for generated spans of 25–99 and 100–400 hours with random minutes and seconds. `Deadline` is checked across midnight (15 January 20:00 plus 8 hours), across a month end (27 February 10:00 plus 48 hours lands on 1 March 10:00) and for a generated SLA of 1–72 hours. `RemainingText` is checked at 2h 05m before the deadline with and without 59 extra seconds, exactly at the deadline, 1h 10m and 45 seconds past it, and with generated spans on both sides. `BillableHours` is checked for exactly 2 hours, a generated number of exact quarters, a generated number of quarters plus one second, and 1 hour 46 minutes. The error tests pass `0DT` in each position and an end before the start, and match the message substrings named above. Text comparisons are exact — note the colons, the zero padding, the single space before `h` and `m`, and the lowercase `overdue by `.

## Learn More

- [Duration data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type) — what `DateTime - DateTime` returns, and what `Format` makes of it.
- [DateTime data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type) — the range, the `0DT` constant, and why you cannot write a DateTime literal.
- [Round method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method) — precision and direction arguments, with a table of what `>`, `<` and `=` do.
- [Text.PadLeft method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-padleft-method) — the simplest way to zero-pad a number to two digits.
