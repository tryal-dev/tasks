# Customer Balance in a Date Window

Finance is building customer statements: for any statement period they need to know how much a customer's balance moved during the period, and what the running balance was at the end of any given day. Both numbers already live in the customer's ledger — the exercise is scoping them to a date window.

## Requirements

Create a **codeunit** named `"Customer Balance Window"` with two public procedures:

```al
procedure BalanceAsOf(CustomerNo: Code[20]; AsOfDate: Date): Decimal
procedure BalanceChangeBetween(CustomerNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
```

Rules:

1. `BalanceChangeBetween` returns the net amount, in local currency (LCY), posted to the customer's ledger with a posting date from `FromDate` through `ToDate` — **both boundary days included**.
2. `BalanceAsOf` returns the customer's balance in LCY as of the end of `AsOfDate`: every entry posted on or before that day counts; every later entry does not.
3. Both results are signed sums — payment and credit entries carry negative amounts and reduce the result.
4. Only entries of the customer identified by `CustomerNo` count; `CustomerNo` always refers to an existing customer.
5. A window (or an as-of date) that no entry falls into returns 0 — that is a normal answer, not an error.

## What the tests check

The grading tests create fresh customers and post general-journal entries to them on several posting dates, with amounts generated at run time — the answers cannot be hardcoded. They assert **exact amounts** for: a window covering only the middle of three entries; a window whose `FromDate` and `ToDate` land exactly on posting dates (both boundary days must count, the days just outside must not); a window covering every entry; a window containing no entries (expect 0); a window mixing a positive and a negative entry (expect the signed net); a second customer posting inside the same window (their entries must not leak into the answer); an as-of date landing exactly on a posting date (that day counts, later entries do not — and a negative entry posted over a year earlier also counts, so the as-of answer must be a signed sum with no lower date bound); and an as-of date before the customer's first entry (expect 0). All seeded entries are in local currency.

## Learn More

- [FlowFields overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields)
- [FlowFilters overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfilter-overview)
- [Record.CalcFields Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method)
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods)
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method)
