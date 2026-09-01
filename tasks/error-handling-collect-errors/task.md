# Collect Every Problem, Not Just the First

The nightly webshop import dumps order lines into staging batches, and the current validator gives up at the first broken line — the operations team fixes one field, reruns, hits the next error, and burns the whole morning clearing a batch one failure at a time.

You'll build a validator with two faces: checking a single line still fails fast with a precise error, but checking a whole batch reports **every** broken line in one run.

## What you get

The starter ships a staging table named `"Import Order Line"` with the fields `"Batch Code"` (Code[20]), `"Line No."` (Integer), `"Item No."` (Code[20]), `Quantity` (Decimal) and `"Unit Price"` (Decimal), keyed on Batch Code + Line No. Keep it unchanged and include it in your submission — the grading tests seed it directly by these names.

## Requirements

Create a **codeunit** named `"Import Line Validator"` with two public procedures:

```al
procedure ValidateLine(ImportOrderLine: Record "Import Order Line")
procedure ValidateBatch(BatchCode: Code[20]; var Problems: List of [Text])
```

`ValidateLine` checks the rules below in this order and raises an error carrying the exact message of the **first** broken rule, where `%1` is the line's `"Line No."`; a line that passes all three rules returns silently:

1. `Line %1: Item No. is missing.` — when `"Item No."` is blank.
2. `Line %1: Quantity must be greater than zero.` — when `Quantity` is zero or negative.
3. `Line %1: Unit Price cannot be negative.` — when `"Unit Price"` is below zero. A price of exactly 0 is valid.

`ValidateBatch`:

- examines every `"Import Order Line"` whose `"Batch Code"` equals `BatchCode`, and nothing else — lines of other batches must never influence the result;
- fills `Problems` with exactly one entry per broken line — the same message `ValidateLine` would raise for that line — ordered by `"Line No."` ascending;
- a line breaking several rules still contributes exactly one entry: its first broken rule in the order above;
- clears whatever input `Problems` already contains;
- never raises an error itself — a batch where every single line is broken still returns normally, and a clean batch yields an empty list.

## What the tests check

Direct `ValidateLine` calls: a fully valid line and a zero-price line pass silently; a blank Item No., a zero quantity, a negative quantity and a negative price each raise exactly the message above (note casing and the trailing period), a line breaking all three rules raises the Item No. message, and a line with a valid Item No. but both a bad quantity and a bad price raises the Quantity message — the rules are checked in exactly the order above. `ValidateBatch` runs: a clean batch yields zero problems; a mixed five-line batch yields exactly its three broken lines' messages in line order; a batch where every line is broken returns normally with every line reported; a line breaking several rules shows up exactly once; a broken line in a second batch stays out of the result; and calling the procedure twice leaves the list holding one run's findings, not two.

## Learn More

- [Collecting errors](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-error-collection)
- [Collectible errors API](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-error-collection-api)
- [ErrorBehavior attribute](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-errorbehavior-attribute)
- [System.GetCollectedErrors([Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getcollectederrors-method)
- [ErrorInfo data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type)
