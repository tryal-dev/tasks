# Week 53 of Last Year

The weekly sales summary groups posted invoices under an ISO week key such as `2026-W01`, and finance wants the month-end, quarter and leap-year helpers to live next to it. The first version keyed every invoice on its calendar year — and every January the summary showed invoices from New Year's Day under "week 53 of 2021", a week that does not exist: 1 January 2021 belongs to week 53 of **2020**. AL's date toolbox already knows the ISO rules; this task is about calling the right function and reading its result correctly.

## Requirements

Create a **codeunit** named `"Period Helper"` with six public procedures:

```al
procedure IsoWeekKey(TheDate: Date): Text
procedure WeekMonday(TheDate: Date): Date
procedure EndOfMonth(TheDate: Date): Date
procedure DaysInMonth(TheDate: Date): Integer
procedure IsLeapYear(Year: Integer): Boolean
procedure QuarterOf(TheDate: Date): Integer
```

The toolbox: AL takes a date apart in two ways. `Date2DMY` returns the calendar day, month and year. `Date2DWY` returns the day of the week (1 = Monday … 7 = Sunday), the ISO week number, and — the part this task depends on — the **ISO week-numbering year**: 2020 for 1 January 2021, 2026 for 29 December 2025. `DMY2Date` and `DWY2Date` build a date back from those pieces, and `DWY2Date(1, 1, 2026)` correctly returns 29 December 2025 — the Monday that starts week 1 of 2026. `CalcDate` moves a date by a date formula, and the formula `<CM>` (current month) lands on the last day of the reference date's month. A dead end to know about: `Date2DMY(TheDate, 3)` and `TheDate.Year()` return the calendar year — right for fifty weeks a year and wrong on exactly the dates the tests probe.

Rules:

1. `IsoWeekKey` returns the ISO 8601 week key: the four-digit ISO week-numbering year, a hyphen, a capital `W`, and the week number zero-padded to two digits — `2024-W24`, `2026-W08`. ISO weeks run Monday to Sunday and week 1 is the week containing 4 January, so the first days of January can belong to week 52 or 53 of the previous year and the last days of December can belong to week 1 of the next: 1 January 2021 is `2020-W53`, 29 December 2025 is `2026-W01`.
2. `WeekMonday` returns the Monday that starts the date's week: the date itself when it is a Monday, otherwise the nearest Monday before it — six days back for a Sunday. The Monday may lie in the previous month or year.
3. `EndOfMonth` returns the last day of the date's month — 29 February in a leap year, 28 otherwise, 31 December for a December date. The last day of a month maps to itself.
4. `DaysInMonth` returns the number of days in the date's month, 28 to 31.
5. `IsLeapYear` follows the Gregorian rules: a year divisible by 4 is a leap year, except century years, which are leap years only when divisible by 400 — 2000 was one, 1900 and 2100 are not.
6. `QuarterOf` returns the calendar quarter 1 to 4: January–March is 1, April–June is 2, July–September is 3, October–December is 4.

You may rely on this: every date the tests pass lies between 1900 and 2100, and every year passed to `IsLeapYear` lies between 1800 and 2400.

Pick your codeunit's object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The tests call each procedure with fixed dates: a mid-year date (`2024-W24`), 1 January 2021 (`2020-W53`), 29 December 2025 (`2026-W01`) and 18 February 2026 (`2026-W08`, note the zero) for the week key; a Sunday whose Monday is six days back, a Monday that maps to itself, 1 January 2021 (Monday 28 December 2020) and 31 December 2025 (Monday 29 December 2025) for the week Monday; February 2024, February 2023, a December date and a date that already is the last day of its month for the month end; February 2024 and February 2100 for the month length; 2024, 2023, 1900 and 2000 for the leap flag; and 31 March, 1 April and a December date for the quarter. Every procedure is also graded on a **generated** input compared against an independent calendar computation — the ISO year taken from the week's Thursday, a weekday count back to Monday, a day-by-day walk to the month end, February's actual length — so hardcoding the examples fails. Week-key comparisons are exact text: four-digit year, hyphen, capital `W`, two digits.

## Learn More

- [System.Date2DWY(Date, Integer) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dwy-method) — day of week, ISO week number, and the week-numbering year, with the year-boundary example spelled out.
- [System.DWY2Date(Integer [, Integer] [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-dwy2date-method) — rebuild a date from weekday, week and year; shows why week 1 can start in December.
- [System.CalcDate(Text [, Date]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-string-date-method) — date formulas such as `<CM>` and how they move a reference date.
- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property) — the `Format` building blocks for a fixed-width, zero-filled number.
