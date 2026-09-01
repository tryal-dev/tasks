# Wire a Document to No. Series

Your workshop takes repair orders, and every order needs a unique document number — `WO12-001`, `WO12-002`, … — handed out by a number series the accountant can configure. Older code did this through the `NoSeriesManagement` codeunit; it is obsolete, and its replacement is the `"No. Series"` module from Business Foundation. You will wire a brand-new document table to it.

## Requirements

1. Create a **table** named `"Workshop Order"` with:
   - a field `"No."` of type `Code[20]` — the **primary key**
   - a field `"No. Series"` of type `Code[20]`
2. In the table's **`OnInsert` trigger**, when `"No."` is blank (`''`):
   - assign the next number from the number series with code `WORKSHOP`, and
   - stamp `"No. Series"` with `WORKSHOP`, so every order records where its number came from.
3. A caller that has already set `"No."` before insert keeps that number — and **no number is drawn from the series**, so the sequence stays gapless.
4. Add a public **procedure on the table**:

```al
procedure PeekNextOrderNo(): Code[20]
```

It returns the number the **next** automatically numbered order will get, **without consuming it** — peeking any number of times must not advance the series.

Use the `"No. Series"` codeunit from the Business Foundation module: `GetNextNo` draws a number, `PeekNextNo` only looks. Do not roll your own counter on top of the series tables — the module already handles incrementing and updating the series line for you.

## What the tests check

The grading tests create the `WORKSHOP` series themselves with a **randomly generated starting number**, so hardcoded numbers cannot pass. They always insert with `Insert(true)` — table triggers do not run otherwise. They verify: the first order gets exactly the series' starting number (persisted under that key, not just in the variable); consecutive inserts number sequentially; `"No. Series"` is stamped on automatically numbered orders; `PeekNextOrderNo` returns the upcoming number; an insert right after peeking still gets that same number; a manually numbered order keeps its number; and a manual order does not consume anything from the series. They also check the declarations: both fields are `Code` (values stored uppercase) with a maximum length of exactly 20.

## Learn More

- [Codeunit "No. Series" (Business Foundation)](https://learn.microsoft.com/en-us/dynamics365/business-central/application/business-foundation/codeunit/microsoft.foundation.noseries.no.-series)
- [OnInsert (Table) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/table/devenv-oninsert-table-trigger)
- [Table object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object)
- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type)
- [Create number series](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-create-number-series)
