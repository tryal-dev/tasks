# Next N Occurrences

Operations wants one planner for every recurring job in the company: the cycle count runs every Monday, Wednesday and Friday at 06:00; the subscription invoices go out on the last Friday of each month at 17:00. You are building the module that answers the only question anyone ever asks a schedule: when does it fire next?

## Requirements

The starter declares an enum `"Recurrence Ordinal"` with the values `First`, `Second`, `Third`, `Fourth`, `Last` — keep its name and values exactly as given, since the tests bind to them.

Create a **codeunit** named `"Recurrence Planner"` with four public procedures:

```al
procedure CreateWeekly(StartDate: Date; StartTime: Time; Weekdays: List of [Integer]; EndDate: Date)
procedure CreateMonthlyByDayOfWeek(StartDate: Date; StartTime: Time; Ordinal: Enum "Recurrence Ordinal"; Weekday: Integer; EndDate: Date)
procedure CalculateNextOccurrence(LastOccurrence: DateTime): DateTime
procedure NextOccurrences(FromDateTime: DateTime; MaxCount: Integer): List of [DateTime]
```

A planner instance holds **one schedule at a time**: each `Create` call defines the schedule and replaces whatever schedule the same instance held before.

Weekday numbers run 1 (Monday) through 7 (Sunday) — the numbering `Date2DWY` uses.

Every occurrence of a schedule happens at `StartTime`; which **dates** carry an occurrence depends on how the schedule was created:

- `CreateWeekly`: every date from `StartDate` onward whose weekday number is in `Weekdays` is an occurrence date.
- `CreateMonthlyByDayOfWeek`: every calendar month has exactly one candidate date — the first, second, third, fourth or **last** date in that month whose weekday number is `Weekday`, as picked by `Ordinal`. Every candidate date on or after `StartDate` is an occurrence date. Note that `Fourth` and `Last` are not the same thing: in a month with five Fridays, the fourth Friday and the last Friday are a week apart.
- In both kinds, when `EndDate` is not `0D` the schedule ends there: a date **on** `EndDate` still carries an occurrence; any later date does not. When `EndDate` is `0D` the schedule never ends.

`CalculateNextOccurrence` returns the earliest occurrence DateTime that is **strictly later** than `LastOccurrence` — so passing an occurrence's own DateTime returns the one after it, and passing `0DT` returns the very first occurrence of the schedule. Note the same-day case: when `LastOccurrence` falls on an occurrence date but earlier in the day than `StartTime`, that same day's occurrence is still ahead and must be returned. When no occurrence remains before the schedule ends, return `0DT`. If it is called before any `Create` procedure has run on the instance, raise an error with a message that contains the text `No schedule has been created`.

`NextOccurrences` returns the occurrences strictly later than `FromDateTime` in ascending order — at most `MaxCount` of them, fewer when the schedule ends first, an empty list when nothing remains at all. If `MaxCount` is below 1, raise an error with a message that contains the text `at least one occurrence`.

What you may rely on — the tests never violate this:

- `Weekdays` holds between 1 and 7 **distinct** values, each 1 to 7; it is never empty.
- `Weekday` is a single value from 1 to 7.
- `StartDate` and `StartTime` are always set; `EndDate` is either `0D` or on/after `StartDate`.
- `LastOccurrence` and `FromDateTime` can be any DateTime, including `0DT` and moments far before `StartDate` or far after `EndDate`.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The tests assert exact DateTime sequences from fixed anchors in 2026: the first occurrence and the five-element sequence of a Monday-Wednesday-Friday weekly plan, an anchor that starts on an unscheduled weekday, a query from a moment weeks before `StartDate` that must yield the anchor's occurrence and never an earlier date, the strictly-after rule from an occurrence's own DateTime and from an earlier moment on the same day, the `EndDate` boundary from both sides in both schedule kinds — including a monthly candidate landing exactly on `EndDate` — a never-ending schedule queried years past its anchor, `NextOccurrences` stopping early at the schedule's end, all five ordinals (first-Monday and last-Friday sequences across months, a second-Tuesday and a third-Wednesday pick, and the fourth-versus-last Friday split in a five-Friday month), a monthly anchor that has already passed its month's candidate, a second `Create` call replacing the first schedule, and both error rules against the exact message fragments quoted above. One test builds a **randomized** weekly schedule — random anchor date, time of day, weekday set and end date — and compares your output element by element against an independent day-by-day walk over the calendar, so hardcoding the fixed examples will not pass.

## Learn More

- [DateTime data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type) — what `0DT` means and how DateTime values compare.
- [System.CreateDateTime(Date, Time) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-createdatetime-method) — joining a date and a time into one DateTime.
- [System.DT2Date(DateTime) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-dt2date-method) — splitting the date back out of a DateTime.
- [System.Date2DWY(Date, Integer) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dwy-method) — the weekday numbering the schedule contract uses.
