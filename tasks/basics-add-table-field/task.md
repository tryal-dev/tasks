# Add a Custom Field to Customer

Your team needs to track a short internal label on each customer record.

## Requirements

1. Create a **table extension** that extends the `Customer` table.
2. Add a field named `"Custom Field"` of type `Text[50]`.

## What the tests check

The grading tests look the field up on the `Customer` table by its exact name `"Custom Field"` at run time (a missing or misspelled field fails with a message saying so). They write a value to it on a customer record and read it back, verify that the field holds a full 50-character value, and check that it is declared as `Text` with a maximum length of exactly 50.

## Learn More

- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object)
- [Extension objects overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-object-overview)
- [Table object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object)
- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)
