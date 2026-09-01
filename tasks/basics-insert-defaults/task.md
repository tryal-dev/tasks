# Default Values on Insert

Every new customer must enter your onboarding pipeline, stamped with the date it was registered and an initial review status. Records are created from pages, APIs, and background jobs alike — so the defaults must be applied by the **table itself**, at insert time, not by any page.

## Requirements

1. Create a **table extension** that extends the `Customer` table with two fields:
   - `"First Registered On"` of type `Date`
   - `"Review Status"` of type `Code[10]`
2. Add an **`OnBeforeInsert` trigger** that stamps defaults:
   - a blank `"First Registered On"` (`0D`) becomes `WorkDate()`
   - a blank `"Review Status"` (`''`) becomes `NEW`
3. Values the caller has already set must be kept — only blank fields get a default.

The defaults must hold even when a field is explicitly cleared just before insert, so the `InitValue` property can't solve this one — the decision has to be made at insert time.

## What the tests check

The grading tests insert customers with `Insert(true)` and read them back from the database: blank fields must come back as `WorkDate()` / `NEW`, and pre-set values must come back unchanged. They also check the declaration of `"Review Status"`: a `Code` field (values stored uppercase) with a maximum length of exactly 10.

## Learn More

- [OnBeforeInsert (Table Extension) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/tableextension/devenv-onbeforeinsert-tableextension-trigger)
- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object)
- [System.WorkDate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-workdate-method)
- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type)
- [InitValue property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property)
