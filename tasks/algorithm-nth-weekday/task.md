# Second Tuesday Payment Run

Treasury pays suppliers on schedule rules, not on calendar dates: "the second Tuesday of every month", "the last Friday", "the first workday on or after the 15th". Someone has been reading these off a wall calendar and marking the runs by hand — and the February entry has been wrong twice. You are writing the scheduler that turns a rule into real dates.

## Requirements

Create a **codeunit** named `"Payment Run Scheduler"` with four public procedures:

```al
procedure NthWeekdayOfMonth(Year: Integer; Month: Integer; WeekdayNumber: Integer; Occurrence: Integer): Date
procedure LastWeekdayOfMonth(Year: Integer; Month: Integer; WeekdayNumber: Integer): Date
procedure FirstWorkdayOnOrAfter(StartingDate: Date): Date
procedure PaymentRunDates(StartYear: Integer; StartMonth: Integer; MonthCount: Integer; WeekdayNumber: Integer; Occurrence: Integer): List of [Date]
```

Weekday numbers run 1 (Monday) through 7 (Sunday) — the numbering `Date2DWY` uses.

What you may rely on — the tests never violate this: `Year` is between 2020 and 2030, `Month` is 1 to 12, `WeekdayNumber` is 1 to 7, and `Occurrence` is 1 to 5 — except for `PaymentRunDates`, which is only ever called with occurrences 1 to 4.

The rules:

1. `NthWeekdayOfMonth` returns the date of the `Occurrence`-th day with that weekday number in the given month: occurrence 1 is the earliest such day in the month — which may be the 1st itself — occurrence 2 the next one, and so on.
2. Every month contains at least four of every weekday, but only some stretch to a fifth. If `Occurrence` is 5 and the month has no fifth such weekday, raise an error with a message that contains the text `no fifth`.
3. `LastWeekdayOfMonth` returns the date of the last day with that weekday number in the given month — the fifth occurrence when the month has five, otherwise the fourth. Watch out for February: how long it is depends on the year.
4. `FirstWorkdayOnOrAfter` returns `StartingDate` itself when it is a workday — Monday through Friday — and otherwise the first workday after it. The result may fall in a later month, or even a later year, than `StartingDate`.
5. `PaymentRunDates` returns one date per month, in chronological order: the `Occurrence`-th `WeekdayNumber` of the start month, then of the following month, and so on for `MonthCount` months in a row. The sequence of months keeps going past December into January of the next year.
6. If `MonthCount` is below 1, raise an error with a message that contains the text `at least one month`.

Pick your codeunit's object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The tests call all four procedures on fixed dates: a month whose 1st already is the wanted weekday, the second Tuesday of an ordinary month, a fifth Friday, a month where the fifth Monday is missing (the error rule), last weekdays in a five-occurrence and a four-occurrence month, the last weekday of February in a leap year and in a common year, a mid-month workday that stays put, a Friday that stays put — Friday is a workday — a Saturday 15th that rolls to Monday, a Sunday month-end that rolls into the next month, a Sunday 31 December that rolls into the next year, a four-month payment run that crosses a year boundary, and a single-month run. Both error rules are checked against the exact message fragments quoted above — the month-count rule with zero and with a random negative value. Two tests use fully **randomized** inputs and compare your result against an independent day-by-day walk over the calendar, so hardcoding the fixed examples will not pass.

## Learn More

- [System.Date2DWY(Date, Integer) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dwy-method) — the weekday numbering the whole task is built on.
- [System.DMY2Date(Integer [, Integer] [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-dmy2date-method) — build a date from day, month, and year numbers.
- [System.Date2DMY(Date, Integer) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dmy-method) — take a date apart again, for example to see which month it landed in.
- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type) — date arithmetic and the rest of the Date toolbox.
