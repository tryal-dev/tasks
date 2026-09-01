# Block Negative Credit Limits

Your company tracks an internal credit ceiling on each customer, and data-entry typos keep producing negative amounts. You'll add the field — and make it defend itself.

## Requirements

1. Create a **table extension** that extends the `Customer` table.
2. Add a field named `"Internal Credit Limit"` of type `Decimal`.
3. Give the field an **`OnValidate` trigger** that raises an error when the value is **negative**. The error message must contain the exact text `must not be negative`.
4. Zero and positive values are accepted.

## What the tests check

The grading tests validate a positive value and read it back, validate zero, and check with `asserterror` that validating a negative value fails with a message containing `must not be negative` — both for a large negative amount and for the boundary value `-0.01`.

## Learn More

- [OnValidate (Field) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/field/devenv-onvalidate-field-trigger)
- [Record.FieldError method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fielderror-joker-string-method)
- [Record.Validate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method)
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods)
- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object)
