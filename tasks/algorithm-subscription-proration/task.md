# Mid-Period Plan Change

A customer on your Streaming Plus plan just upgraded to Premium — eleven days into the billing period, of course, never on day one. The full period was already invoiced at the old price, so billing now owes the customer two adjustment lines: a credit for the days they will not use on the old plan, and a charge for those same days at the new price. This is exactly what Business Central's subscription-billing module does on every mid-cycle contract change, and finance will reject the batch if the numbers drift by a single cent.

Beware the folklore: subscription proration here has nothing to do with "a month is 30 days". Days are counted on the real calendar, and February — 28 days, or 29 in a leap year — is where the 30-day shortcut goes to die.

## Requirements

Create a **codeunit** named `"Plan Change Prorator"` with one public procedure:

```al
procedure ProrateChange(PeriodStart: Date; PeriodEnd: Date; ChangeDate: Date; OldPrice: Decimal; NewPrice: Decimal; var CreditAmount: Decimal; var ChargeAmount: Decimal)
```

What you may rely on — the tests never violate this:

- The billing period runs from `PeriodStart` through `PeriodEnd`, both days inclusive, and is at least one day long. The customer has already been invoiced `OldPrice` for the whole period.
- `PeriodStart` <= `ChangeDate` <= `PeriodEnd`. The change takes effect on `ChangeDate`: that day and every later day of the period belong to the new plan.
- `OldPrice` and `NewPrice` are `>= 0` and exact multiples of 0.01. `NewPrice = 0` means the customer cancels — the remaining days are simply not billed.

What the procedure must produce — all of it is graded:

1. Day counts use actual calendar days, inclusive on both ends: the period day count runs from `PeriodStart` through `PeriodEnd`, and the remaining day count runs from `ChangeDate` through `PeriodEnd`. A February period has 28 or 29 days — never 30.
2. `CreditAmount` is the value of the remaining days at the old price: `OldPrice` × remaining days ÷ period days, rounded to the nearest cent, with an exact half-cent rounding up (away from zero). It is returned as a positive amount.
3. `ChargeAmount` is the value of the remaining days at the new price: `NewPrice` × remaining days ÷ period days, same rounding. A cancellation therefore charges exactly 0.00.
4. Both lines cover the same remaining days with the same rounding, so a plan "change" that keeps the price unchanged must yield `CreditAmount` equal to `ChargeAmount` to the cent — the customer nets exactly zero. This symmetry is graded with randomized inputs.
5. Assign both `var` parameters unconditionally — the tests pass in variables that already hold garbage, and whatever your procedure leaves there is what gets graded.

## What the tests check

The tests call `ProrateChange` and compare both amounts penny-exact against hand-computed fixtures: a change on the first day of the period (full credit, full charge), a mid-January upgrade, a downgrade inside a 28-day February, an upgrade inside a leap-year February, a cancellation, a change on the last day of the period (exactly one remaining day), and a fixture whose exact shares end in half a cent. Two randomized tests finish the job: a same-price switch must net to exactly zero, and a fully random plan change is checked against independently computed proration — so hardcoding the examples fails.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## Learn More

- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type) — what an AL Date is and what you can do with one.
- [System.Round(Decimal [, Decimal] [, Text]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method) — rounding decimals to a given precision and direction.
- [Decimal data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type) — the numeric type doing the money math.
- [Overview of subscription billing](https://learn.microsoft.com/en-us/dynamics365/business-central/srb/welcome) — the real BC module whose mid-cycle proration you are rebuilding in miniature.
