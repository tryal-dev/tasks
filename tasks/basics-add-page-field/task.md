# Show the Customer Custom Field on the Card

Building on the table extension from `basics-add-table-field`, show `"Custom Field"` on the Customer Card page.

## Requirements

1. Create a **page extension** that extends the `"Customer Card"` page.
2. Add a field control named `"Custom Field"`, bound to `Rec."Custom Field"`, with `ApplicationArea = All`.
3. Anchor it after the `Name` control (any valid anchor is graded the same — this one keeps the layout sensible).

> **The starter already includes the table extension from `basics-add-table-field` — keep that file in your submission.** The platform does not carry objects over between tasks, so without it `Rec."Custom Field"` does not exist and your submission won't compile.

## What the tests check

The grading tests read the Customer Card's control list from the `"Page Control Field"` virtual table and require a field control bound to `Rec."Custom Field"` whose control name is exactly `"Custom Field"` (a missing control fails with a message saying so). They also store a value in `"Custom Field"` on a customer, open that customer on the Customer Card, and read the value back.

## Learn More

- [Page extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object)
- [Page object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object)
- [ApplicationArea property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-applicationarea-property)
- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object)
- [Add tooltips to table and page fields](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-adding-tooltips)
