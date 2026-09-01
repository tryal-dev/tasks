# Which Rate Applied on This Date?

Commission rates change over time: a salesperson earns 5% from January 1st, then 7% from March 1st, then 6% from June 1st. Nobody records an ending date — a rate simply stays in force until a newer one takes over. Business Central models currency exchange rates and price lists exactly this way: rows keyed by a code and a starting date, and the row that applies on any given date is the one with the **latest starting date on or before that date**. Your job is that lookup.

## Requirements

The starter ships a table named `"Commission Rate"` — keep its name, field names and primary key exactly as they are, because the grading tests write rows into it directly:

| Field | Type |
|---|---|
| `"Salesperson Code"` | `Code[20]` |
| `"Starting Date"` | `Date` |
| `"Rate %"` | `Decimal` |

Primary key: `"Salesperson Code", "Starting Date"`.

Complete the **codeunit** named `"Commission Rate Finder"` with two public procedures:

```al
procedure FindRateAt(SalespersonCode: Code[20]; AtDate: Date; var RatePct: Decimal): Boolean
procedure GetRateAt(SalespersonCode: Code[20]; AtDate: Date): Decimal
```

Rules:

1. A rate row *applies* at `AtDate` when its `"Salesperson Code"` equals `SalespersonCode` and its `"Starting Date"` is **on or before** `AtDate`. Among all applying rows, the one with the latest `"Starting Date"` wins.
2. `FindRateAt` returns `true` and sets `RatePct` to the winning row's `"Rate %"`. On the very day a new rate starts, the new rate already applies — not the previous one.
3. When no row applies — the salesperson has no rows at all, or every row starts after `AtDate` — `FindRateAt` returns `false` and sets `RatePct` to 0, whatever value the caller passed in.
4. A rate of 0% is a real rate: when the winning row's `"Rate %"` is 0, `FindRateAt` returns `true` with `RatePct` = 0. "Found a 0% rate" and "found no rate" are different answers.
5. Rows belonging to other salespeople never influence the result — not even when the queried salesperson has no rows of their own.
6. `GetRateAt` returns the winning row's `"Rate %"`, or 0 when no row applies.
7. Neither procedure may raise an error. The tests always seed real starting dates (never blank) and always pass a real `AtDate`.

## What the tests check

The grading tests seed `"Commission Rate"` rows for freshly invented salesperson codes — several rates per salesperson, with the rate values generated at run time so constants can't pass — and probe `FindRateAt` and `GetRateAt` with dates on a starting date, between two starting dates, before the first starting date, and after the last one. One test seeds a 0% rate on top of an earlier non-zero rate and expects `true` with `RatePct` = 0. Another seeds a second salesperson whose rates would win if your code forgot to filter by salesperson, and expects the queried salesperson's own rate. The no-rate tests pass a deliberately dirty `RatePct` in and expect it back as 0.

## Learn More

- [Record.FindLast Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findlast-method)
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method)
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods)
- [Table keys](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys)
