# Find the Duplicate Customers

Years of imports and hasty data entry left the Customer table with the same company entered two or three times — `Contoso, Ltd.` next to `CONTOSO LTD`, identical VAT numbers spaced and dashed differently. Before the cleanup project can merge anything, it needs a finder that spots the duplicates reliably.

## Requirements

Create a **codeunit** named `"Duplicate Customer Finder"` with two public procedures:

```al
procedure Normalize(Value: Text): Text
procedure FindDuplicatesOf(CustomerNo: Code[20]): List of [Code[20]]
```

`Normalize` rules — all graded:

1. Keep only the letters `A`–`Z` / `a`–`z` and the digits `0`–`9`; every other character — spaces, tabs, punctuation, symbols, anything else — is removed.
2. Uppercase the kept letters: `'Contoso, Ltd.'` becomes `'CONTOSOLTD'`, `'gb-123 456'` becomes `'GB123456'`.
3. A value containing no letters or digits normalizes to an empty text (`''`).

`FindDuplicatesOf` receives the `"No."` of an existing customer and returns the numbers of every **other** customer in the `Customer` table that is a duplicate of it:

1. Two customers are duplicates when their normalized `Name` values are equal, **or** their normalized `"VAT Registration No."` values are equal.
2. An empty normalized value never makes a match, on either field: customers whose VAT numbers are blank (or punctuation-only) are not duplicates for that reason alone, and the same holds for names.
3. Each duplicate appears in the list exactly once, even when it matches on both name and VAT number.
4. The list is sorted ascending by `"No."` and never contains the customer you asked about. An empty list means no duplicates.

## What the tests check

The tests call `Normalize` on fixed and randomized values and compare the result exactly. For `FindDuplicatesOf`, they insert customers with crafted names and VAT numbers, then compare the returned list — content **and** order — against the expected customer numbers: name-only matches, VAT-only matches, a customer matching on both fields at once, blank and punctuation-only values that must not match, and a randomized pair so a solution hardcoded on the fixed examples fails. The company already contains other (demo) customers — your finder scans the real `Customer` table, and the seeded test customers are the only ones that can match.

## Learn More

- [Record data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type)
- [Record.SetFilter method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method)
- [Record.FindSet method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method)
- [Text.ToUpper method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-toupper-method)
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
