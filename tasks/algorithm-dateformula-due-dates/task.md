# Terms of Payment

An accounts-payable clerk just escalated three invoices: the vendor's portal says they fall due two days later than your system does, and one early-payment discount was refused that she swears was earned. Every invoice in Business Central carries a due date and a discount date, both computed from compact date-formula expressions stored on the payment terms — `<14D>`, `<CM+1M>`, `<-WD2>` — and the disagreements always surface at the nasty spots: months of different lengths, leap years, and weekday-based terms. You will build that calculator and get every calendar edge right.

## Requirements

Create a **codeunit** named `"Payment Terms Calculator"` with two public procedures:

```al
procedure CalcDueDate(DocumentDate: Date; DueDateFormulaText: Text): Date
procedure QualifiesForDiscount(DocumentDate: Date; PaymentDate: Date; DiscountDateFormulaText: Text): Boolean
```

How a date-formula text is read — this is the full contract the tests grade:

- A formula arrives wrapped in angle brackets (`<14D>`, `<CM+1M>`) and contains up to three terms, read left to right; each term moves a running date that starts at `DocumentDate`, and the final running date is the result.
- `nD` and `nW` move the running date exactly n days or n weeks forward; a leading `-` moves backward instead.
- `nM` and `nY` move to the same day of the month n calendar months or years away; when that day does not exist in the target month, the result is the last day of the target month — 31 January plus `1M` is 28 February, or 29 February in a leap year, and `1Y` applied to 29 February 2024 is 28 February 2025.
- `CM` jumps the running date forward to the last day of its own month.
- `WDn` (weekday n, Monday = 1 through Sunday = 7) jumps forward to the next date falling on that weekday, always moving by at least one day — so `<WD2>` on a date that is already a Tuesday lands a full week later; `-WDn` jumps backward to the previous such date, always moving back by at least one day.
- Terms apply strictly in the order written: `<CM+1M>` is month-end first, then one month — from 15 February 2024 that is 29 March 2024 — while `<1M+CM>` from the same date gives 31 March 2024. The tests grade this distinction.
- Blank text means due immediately: `CalcDueDate` returns `DocumentDate` unchanged.
- Text that is not a valid date formula must raise an error, and the error message must include the rejected text.

`QualifiesForDiscount` applies `DiscountDateFormulaText` to `DocumentDate` under exactly the same rules to get the discount date, and returns `true` when `PaymentDate` falls on or before that date — paying on the discount date itself still earns the discount.

What you may rely on — the tests never violate this: every formula the tests pass is blank, deliberately invalid, or built only from the term forms above; the number in a term never exceeds 300; all dates are ordinary dates well inside the supported calendar.

## What the tests check

Fixed calendar cases check each rule above — a plain day offset, month steps clamping into February of a common year and of a leap year, `<1Y>` off a leap day, both orderings of `CM` and `1M` from 15 February 2024, a `<CM-10D>` combination, a three-term `<CM+1M-10D>` combination, the next-Tuesday and previous-Tuesday weekday jumps including the full-week move in each direction when the start date is already a Tuesday, blank text, and the invalid-text error (matched as a substring on the rejected text). `QualifiesForDiscount` is graded on, before, and after the discount date. Finally, randomized day and week offsets are checked against plain calendar arithmetic, so hardcoding the fixed examples fails.

## Learn More

- [DateFormula data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dateformula/dateformula-data-type)
- [System.CalcDate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-dateformula-date-method)
- [System.Evaluate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method)
- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type)
- [Set up payment terms](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-payment-terms)
