# Customers Who Never Ordered

Marketing is planning a re-engagement campaign and needs the classic anti-join question answered in AL: which customers went a whole period without a single posted transaction? In Business Central every posted sales document and payment leaves a trail in the customer ledger — a customer who "never ordered" in a period is simply a customer with no trace there.

## Requirements

Create a **codeunit** named `"Never Ordered Customers"` with two public procedures:

```al
procedure NeverOrderedInPeriod(CustomerNo: Code[20]; FromDate: Date; ToDate: Date): Boolean
procedure GetNeverOrderedCustomers(FromDate: Date; ToDate: Date): List of [Code[20]]
```

Rules:

1. `NeverOrderedInPeriod` returns `true` when the `"Cust. Ledger Entry"` table holds **no** entry for `CustomerNo` whose `"Posting Date"` falls between `FromDate` and `ToDate`, both days **inclusive** — and `false` as soon as at least one such entry exists.
2. Entries posted before `FromDate` or after `ToDate` do not make a customer "ordered" — a customer whose entries all fall outside the period has still never ordered in it.
3. Any ledger entry inside the period counts, whatever its document type, amount or open state — and only entries of that customer count, never a neighbour's.
4. `GetNeverOrderedCustomers` returns the `"No."` of every record in the `Customer` table for which `NeverOrderedInPeriod` is `true` for that period; customers with at least one entry in the period are left out.
5. Neither procedure may raise an error; a customer with no ledger entries at all has never ordered in any period.

## What the tests check

The grading tests create fresh customers, generate a random period per test, and write customer ledger entries directly with posting dates derived from that period: one in the middle, one exactly on `FromDate`, one exactly on `ToDate`, one the day before, and one the day after. The boolean is asserted at each of those boundaries, and one test seeds a single in-period entry and asks about both customers in the same period — the entry's owner must come back ordered and the other customer never ordered. The list tests assert **membership only** — the returned list must contain the seeded never-ordered customers (including one whose entries fall just outside both ends of the period) and must not contain the seeded ordered ones, including customers whose only entry falls exactly on `FromDate` or exactly on `ToDate`; the tests run in a real company that already contains customers, so a total count is never asserted.

## Learn More

- [Record.IsEmpty Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-isempty-method)
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method)
- [Record.FindSet Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method)
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
