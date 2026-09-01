# Map Dates to Fiscal Periods

Not every company closes its books on December 31: UK and Japanese subsidiaries start their fiscal year in April, the US federal government in October, and Business Central models all of them with accounting periods. Your consolidation report needs the arithmetic underneath those periods: given nothing but the fiscal-year start month, place any date in its fiscal period and find the exact boundaries of the fiscal year it belongs to.

## Requirements

Create a **codeunit** named `"Fiscal Period Mapper"` with three public procedures:

```al
procedure GetPeriodNo(FiscalYearStartMonth: Integer; TheDate: Date): Integer
procedure GetFiscalYearStartDate(FiscalYearStartMonth: Integer; TheDate: Date): Date
procedure GetFiscalYearEndDate(FiscalYearStartMonth: Integer; TheDate: Date): Date
```

A fiscal year begins on day 1 of `FiscalYearStartMonth` and consists of 12 periods of exactly one calendar month each.

- `GetPeriodNo` returns the period `TheDate` falls in, from 1 to 12: the start month is period 1, the following month is period 2, and the month right before the start month is period 12. With an April start, 2026-04-01 is period 1 and 2026-03-31 is period 12.
- `GetFiscalYearStartDate` returns the first day of the fiscal year containing `TheDate`. If `TheDate`'s month is on or after the start month, the fiscal year began that same calendar year; otherwise it began the year before.
- `GetFiscalYearEndDate` returns the last day of that same fiscal year — the day before the next fiscal year begins. This is where leap days bite: a fiscal year that starts in March ends on the last day of February, which is February 29 in a leap year and February 28 otherwise — and century years such as 2100 are **not** leap years.
- All three procedures must raise an error when `FiscalYearStartMonth` is outside 1–12; the error message must contain the exact phrase `between 1 and 12`.

## What the tests check

The tests call your procedures with fixed cases — a January start (periods = calendar months), an April start on the first day of the fiscal year and on both sides of the year-end wrap, February 29, 2024 mapped to its period, an October start probed on, after, and just before its start date, and March starts whose fiscal years end in February 2024 (leap), February 2022 (common), and February 2100 (century year, not leap) — plus randomized start months and dates graded on each of the three procedures, so hardcoding the examples fails. Three more tests pass start months 0 and 13, one per procedure, and expect an error containing `between 1 and 12`.

## Learn More

- [Work with accounting periods and fiscal years](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-accounting-periods-and-fiscal-years)
- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type)
- [System.Date2DMY(Date, Integer) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dmy-method)
- [System.DMY2Date(Integer [, Integer] [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-dmy2date-method)
- [System.CalcDate(Text [, Date]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-string-date-method)
