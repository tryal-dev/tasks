# Sum a Filtered Set Correctly

Finance wants a per-city credit exposure widget: the sum of customer credit limits in a city, plus a policy variant where no single customer counts for more than a given cap. The first version shipped and the numbers are wrong — multi-customer cities come up short, a one-customer city shows zero, and an empty city crashes the widget. The loop in the starter is the culprit.

## Requirements

Create a **codeunit** named `"City Credit Aggregator"` with two public procedures:

```al
procedure TotalCreditLimit(CityName: Text): Decimal
procedure TotalCreditLimitCapped(CityName: Text; Cap: Decimal): Decimal
```

Rules:

1. `TotalCreditLimit` returns the sum of `"Credit Limit (LCY)"` over every `Customer` whose `City` equals `CityName` — the whole value, exactly (searching `North` must not include a customer in `Northport`).
2. `TotalCreditLimitCapped` sums over the same set of customers, but caps each customer's contribution: a customer whose `"Credit Limit (LCY)"` is above `Cap` counts as exactly `Cap`; a customer at or below `Cap` counts at their own limit. Above-cap customers are capped, never dropped from the total.
3. `Cap` is always greater than zero, and the credit limits the tests seed are never negative.
4. A city with no customers totals 0 from both procedures — never an error.

## What the tests check

The grading tests seed customers with run-time-generated credit limits into marker city names, next to decoys in other cities, and assert **exact totals** — the amounts are generated, so no constant can pass. The data is crafted so each classic aggregation-loop mistake produces its own wrong number: a three-customer city (losing the first record or keeping only the last amount comes up short), a single-customer city (a loop that steps to the next record before reading the first returns 0), an empty city (an unguarded find crashes), and a decoy city that merely extends the searched name. The capped tests place one customer below, one exactly at, and one above the cap — forgetting the cap, capping every customer, or dropping the above-cap customer all give a different total — and keep an above-cap decoy in another city, so the capped total must filter by city too.

## Learn More

- [Record.FindSet Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method)
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods)
- [AL control statements](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements)
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method)
