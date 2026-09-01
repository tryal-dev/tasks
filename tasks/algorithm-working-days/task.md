# Promise a Ship Date

Sales keeps promising customers "we ship within three working days" — and the warehouse keeps missing it, because three working days is not three calendar days. The Friday order ships Wednesday, not Monday. The subsidiary in Dubai rests Friday and Saturday, not Saturday and Sunday. And no shipment leaves on a public holiday. You are writing the calculator both teams will trust.

## Requirements

Create a **codeunit** named `"Working Days Calculator"` with two public procedures:

```al
procedure WorkingDaysBetween(FromDate: Date; ToDate: Date; WeekendDays: List of [Integer]; Holidays: List of [Date]): Integer
procedure PromiseShipmentDate(OrderDate: Date; LeadTimeWorkingDays: Integer; WeekendDays: List of [Integer]; Holidays: List of [Date]): Date
```

A date is a **working day** exactly when its weekday number is not in `WeekendDays` and the date itself is not in `Holidays`. Weekday numbers run 1 (Monday) through 7 (Sunday) — the numbering `Date2DWY` uses.

What you may rely on — the tests never violate this:

- `WeekendDays` holds between 0 and 6 distinct values, each 1 to 7. It can be empty (a warehouse that never closes) and it never covers the whole week.
- `Holidays` is any list of dates: it may be empty, it may contain the same date more than once, and it may contain dates that fall on a weekend day or outside the range you are looking at.

`WorkingDaysBetween` returns the number of working days in the range from `FromDate` to `ToDate`, **both endpoints included**:

1. A holiday inside the range removes its day from the count **once** — no matter how many times it appears in the list.
2. A holiday that falls on a weekend day changes nothing: that day was never a working day to begin with.
3. A holiday outside the range changes nothing.
4. If `ToDate` is earlier than `FromDate`, raise an error with a message that contains the text `must not be before`.

`PromiseShipmentDate` returns the date the shipment leaves: the date reached by counting `LeadTimeWorkingDays` working days **strictly after** `OrderDate`:

5. `OrderDate` itself never counts, even when it is a working day — the order still has to be picked. A lead time of 1 therefore returns the first working day after `OrderDate`.
6. The returned date is always a working day by construction.
7. If `LeadTimeWorkingDays` is below 1, raise an error with a message that contains the text `at least one working day`.

## What the tests check

The tests exercise both procedures with fixed dates in July 2026: a full Monday-to-Friday week, a range crossing a Saturday–Sunday weekend, single-day ranges on a working day and on a weekend day, a Friday–Saturday weekend pattern, a holiday inside the range, the same holiday listed twice, a holiday on a Saturday, a holiday outside the range, an empty weekend list, and promises that must step over weekends, a two-day holiday run, and a custom weekend. Both error rules are checked against the exact message fragments quoted above — the lead-time rule with a lead time of zero and with a random negative value. Two tests use a **randomized** range, weekend pattern of 2 to 5 weekend days, lead time and holidays, and compare against an independent day-by-day count — so hardcoding the fixed examples or handling only two-day weekends will not pass.

## Learn More

- [System.Date2DWY(Date, Integer) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dwy-method)
- [Date.DayOfWeek() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-dayofweek-method)
- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type)
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling)
