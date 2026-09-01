# Search Across Columns

The customer list's search box takes one piece of text and promises a hit whether that text sits in the company's **name** or in its **city**. The current implementation filters both columns at once — and a record only survives filtering when it satisfies *every* filter, so the box now finds the customers matching in **both** columns instead of **either**. It returns the intersection; the search box promised the union.

## Requirements

Create a **codeunit** named `"Customer Cross Search"` with two public procedures:

```al
procedure CountMatches(SearchText: Text): Integer
procedure CountContactableMatches(SearchText: Text): Integer
```

Rules:

1. A customer **matches** when `SearchText` appears anywhere in its `Name` **or** anywhere in its `City`, ignoring case in both columns. One column is enough — and a customer carrying the text in both columns is still exactly one match.
2. `CountMatches` returns how many `Customer` records match.
3. `CountContactableMatches` returns how many matching customers also have a non-blank `"E-Mail"`. The e-mail rule only narrows the result — it must never add a customer that the text match alone would not have found.
4. `SearchText` is never empty and contains only plain letters and digits — no filter-syntax characters to defuse in this task (that lesson lives in `filtering-hostile-names`).
5. A search that finds nothing returns 0; neither procedure may raise an error.

## What the tests check

The grading tests generate the search text at run time (so no count can be hardcoded), seed customers carrying it at the start, in the middle and at the end of `Name` or `City`, always next to decoys that don't carry it, and assert **exact counts**. One test plants the text in a customer's name only, one in the city only, and one in both columns of the same customer — each of those customers must count exactly once. A lowercase search must find text stored in uppercase. The contactable tests mix blank and filled `"E-Mail"` values among the matching customers and plant a decoy that has an e-mail but no text match — it must never count, no matter how the e-mail condition is attached. The tests run in a real company that already contains customers, so your counts must be driven purely by the matching rule above.

## Learn More

- [Record.FilterGroup Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method)
- [Record.SetFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method)
- [Entering criteria in filters](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters)
- [Record.Count Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-count-method)
