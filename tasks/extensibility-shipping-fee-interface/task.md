# One Interface, Three Calculators

Your company keeps changing how it charges shipping: this quarter it's a flat fee, the webshop team wants weight-based pricing, and marketing just promised free shipping on large orders. Every change so far has meant editing a growing `case` statement buried in posting code. You are going to end that: model the fee schemes the way the base application models price calculation — an enum picks the strategy, an interface defines the contract, and the calling code never knows which codeunit does the math.

## Requirements

1. Keep the **interface** `"Shipping Fee Calculator"` exactly as the starter declares it — one procedure:

```al
procedure CalculateFee(ParcelWeightKg: Decimal; OrderAmount: Decimal): Decimal
```

2. Wire the **enum** `"Shipping Fee Method"` to real calculators. The starter's enum already implements the interface, but every value falls back to the `"Shipping Fee Placeholder"` codeunit, whose `CalculateFee` only raises an error. Give each of its three values — `"Flat Rate"`, `"By Weight"`, `"Free Over Threshold"` — its own `Implementation`, so that assigning any of them to a variable of type `Interface "Shipping Fee Calculator"` yields a working calculator for that scheme. Once every value is wired, you may delete the placeholder, or keep it as the default for values nobody has wired yet — either is fine.
3. Implement **three calculator codeunits** (their names are your choice — the tests never reference them directly), one per enum value, with these exact rules:
   - `"Flat Rate"` — the fee is always **9.90**, whatever the weight or the order amount.
   - `"By Weight"` — the fee is the parcel weight in kg times **1.60**, rounded to the nearest cent (0.01); when that computed fee is below the **5.00** minimum, the fee is exactly 5.00. The order amount plays no part.
   - `"Free Over Threshold"` — orders with an amount of **100.00 or more** ship free (fee 0); below 100.00 the fee is a flat **7.50**. The parcel weight plays no part.

## What the tests check

The grading tests never name your codeunits: each test assigns one `"Shipping Fee Method"` value to an `Interface "Shipping Fee Calculator"` variable and calls `CalculateFee` through it, so the enum wiring itself is under test — against the unchanged starter every test fails with the placeholder's error, `No shipping fee calculator is wired to this Shipping Fee Method yet`. The tests probe randomized weights and amounts (a hardcoded fee won't survive `"By Weight"`), the cent rounding in both directions (a 4.03 kg parcel is 6.448, expected **6.45**; a 4.02 kg parcel is 6.432, expected **6.43**), the minimum-fee boundary (a 3.125 kg parcel costs exactly **5.00**), and the free-shipping threshold at exactly **100.00**, just below it (**99.99**) and above it. Every test passes a random value for the parameter its scheme is supposed to ignore.

## Learn More

- [Interfaces in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al)
- [Extensible Enums](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums)
- [Implementation Property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-implementation-property)
- [Implement interfaces in Dynamics 365 Business Central](https://learn.microsoft.com/en-us/training/modules/business-central-interfaces/)
