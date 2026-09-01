# Gilded Rose, AL Edition

The Gilded Rose is a small inn that buys and sells only the finest goods, and every night its ledger must be brought forward one day: items creep toward their sell-by date and their quality drifts — each category by its own rule.

The previous innkeeper implemented only the plain rule before leaving. You inherit the starter's three objects — keep their names, values and fields exactly as given, since the tests bind to them — and finish the nightly update for every category.

## The objects (already declared in the starter)

- Enum `"Gilded Item Category"` with values `Normal`, `"Aged Brie"`, `Sulfuras`, `"Backstage Pass"`, `Conjured`.
- Table `"Gilded Item"` with fields `"No."` (Code[20], primary key), `Category` (the enum), `"Sell In"` (Integer — days until the sell-by date), `Quality` (Integer).
- Codeunit `"Gilded Rose"` with two public procedures:

```al
procedure UpdateItem(var GildedItem: Record "Gilded Item")
procedure EndOfDay()
```

## The nightly rules

`UpdateItem` advances one item by exactly one day and persists the change to the database — the tests re-read the record after the call. Every category decision below is based on the `"Sell In"` value **as it stood before the update**; an item is *expired* when that value is `0` or less.

1. Every item except `Sulfuras`: `"Sell In"` decreases by 1 — it keeps counting and may go negative.
2. `Normal`: `Quality` decreases by 1, or by 2 when expired.
3. `"Aged Brie"`: `Quality` increases by 1, or by 2 when expired.
4. `Sulfuras`: legendary — neither `"Sell In"` nor `Quality` ever changes; its quality is always 80.
5. `"Backstage Pass"`: `Quality` increases by 1 when `"Sell In"` is 11 or more, by 2 when it is 10 down to 6, by 3 when it is 5 down to 1 — and when the pass is expired the concert is over: `Quality` drops to exactly 0, whatever it was.
6. `Conjured`: degrades twice as fast as `Normal` — `Quality` decreases by 2, or by 4 when expired.
7. After the day's change, `Quality` is never below 0 and never above 50 (`Sulfuras` is exempt and stays at 80).

`EndOfDay` runs that same one-day update once for every record in the `"Gilded Item"` table.

What you may rely on — the tests never violate this: seeded items always start with `Quality` between 0 and 50 (`Sulfuras` always exactly 80), and `Category` is always one of the five values.

## What the tests check

Each test seeds one item, calls `UpdateItem` once, and verifies the persisted `"Sell In"` and `Quality`: fresh, on-the-date and long-expired `Normal` items plus the floor at 0 for both a fresh and an expired item; fresh, expired and capped `"Aged Brie"`; an untouched `Sulfuras`; `"Backstage Pass"` at 11, 10, 6, 5 and 1 days out, after the concert, and at the cap of 50 in each of the three gain windows; fresh, expired and floored `Conjured` items, the floor checked both fresh and expired; two items with randomized values so hardcoding the examples fails; and one `EndOfDay` run over a mixed five-item inventory verifying every item moved exactly one day by its own rule.

## Learn More

- [Table object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object)
- [Extensible enums](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums)
- [Record.Modify([Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method)
- [Record.FindSet([Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method)
- [Record data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type)
