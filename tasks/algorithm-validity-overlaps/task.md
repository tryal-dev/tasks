# Conflicting Price List Lines

A customer imports sales price lists from three legacy systems, and the same item now sits on several lines whose validity windows overlap — two prices can both be "the" valid price on the same day. Before anyone activates that price list, your import review tool must show the continuous coverage the windows add up to and how many pairs of lines actually collide.

## Requirements

Create a **codeunit** named `"Price Validity Analyzer"` with two public procedures:

```al
procedure MergeValidityPeriods(var PriceListLine: Record "Price List Line" temporary; var MergedPeriod: Record "Price List Line" temporary)
procedure CountConflictingPairs(var PriceListLine: Record "Price List Line" temporary): Integer
```

Both procedures receive a temporary buffer of price list lines belonging to one item. Only three fields matter: `"Line No."` (distinct on every input line), `"Starting Date"`, and `"Ending Date"` — the tests never set any other field on the input, and read only those three on the output.

A line is valid from its `"Starting Date"` through its `"Ending Date"`, both days inclusive. A blank `"Starting Date"` means the line has always been valid (no lower bound); a blank `"Ending Date"` means it stays valid forever (no upper bound).

Two periods **overlap** when they share at least one calendar day. Two periods are **adjacent** when one ends exactly the day before the other starts — touching, but sharing no day.

### `MergeValidityPeriods`

- First removes any records already sitting in `MergedPeriod` — callers may hand you a dirty buffer.
- Writes one record per **continuous coverage period**: input periods that overlap or are adjacent belong to the same coverage period; a gap of at least one full uncovered day separates two coverage periods.
- Output records get `"Line No."` 10000, 20000, 30000, … assigned in ascending date order, with `"Starting Date"` and `"Ending Date"` set to the coverage period's outermost bounds.
- A coverage period that contains a blank-start line has a blank `"Starting Date"`; one that contains an open-ended line has a blank `"Ending Date"`.
- Input lines arrive in no particular order — never assume they are sorted.

### `CountConflictingPairs`

- Returns the number of **unordered pairs** of input lines whose periods overlap.
- Adjacent-but-not-overlapping pairs are not conflicts; two lines with identical periods are one conflicting pair.
- Count pairs, not lines: a line covering all of 2027 conflicting with a January line and a March line is **2** pairs, even though 3 lines are involved.

### Validation

Both procedures must raise an error when any input line has a non-blank `"Ending Date"` earlier than its non-blank `"Starting Date"`. The error message must contain the exact phrase `before the starting date`.

## What the tests check

Fixed merge cases: a single line, disjoint periods inserted out of date order (the output must still be sorted and numbered 10000/20000), an overlapping pair, a pair sharing exactly one day, an adjacent pair, a one-day gap (must stay separate), a fully contained period, an unsorted chain of three, blank starting and ending dates, adjacent blank-bounded lines merging into all-time coverage, a preloaded output buffer, and an empty input. Fixed conflict cases: disjoint, adjacent, one overlapping pair, pairs-versus-lines, identical duplicates, and an open-ended line against a much later line. Two randomized tests grade the merge day by day against a coverage bitmap and the conflict count against an independent pairwise check, so hardcoding the examples fails. Two error tests pass a line with the ending date before the starting date to each procedure and expect an error containing `before the starting date`.

## Learn More

- [Temporary tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables)
- [Record data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type)
- [Record.SetCurrentKey(Any [, Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method)
- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type)
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling)
