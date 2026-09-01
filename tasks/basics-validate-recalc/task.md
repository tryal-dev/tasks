# Recalculate on Validate

Sales wants a pricing helper on items: enter a markup percentage, get a suggested sales price computed from the unit cost. The recalculation must happen when the field is **validated** — and only then. That's the whole difference between `Item.Validate("Markup %", 25)` and `Item."Markup %" := 25`, and one of the first things every AL developer has to internalize.

## Requirements

1. Create a **table extension** that extends the `Item` table.
2. Add a field named `"Markup %"` of type `Decimal`.
3. Add a field named `"Suggested Price"` of type `Decimal`.
4. Give `"Markup %"` an **`OnValidate` trigger** that recalculates the suggested price as

   > Suggested Price = Unit Cost × (1 + Markup % / 100)

   rounded to the nearest **0.01**. Translating that into AL — the field quoting, the `Round` call, the trigger — is your job.

Because the logic lives in the `OnValidate` trigger, a plain assignment to `"Markup %"` must leave `"Suggested Price"` untouched — AL gives you that for free; don't recalculate anywhere else (not in `OnModify`, not in the other field).

## What the tests check

The grading tests validate a generated markup against a generated unit cost and compare with the formula above, verify that a plain assignment followed by `Modify(true)` does *not* recalculate, and check the rounding from both sides: `33.33 * 1.10 = 36.663 → 36.66` and `33.33 * 1.20 = 39.996 → 40.00` (truncating is not rounding).

## Learn More

- [Record.Validate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method)
- [OnValidate (Field) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/field/devenv-onvalidate-field-trigger)
- [System.Round method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method)
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods)
- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object)
