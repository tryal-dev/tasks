# Shelf Totals, Straight From the Index

Your warehouse extension logs every put-away and pick as one movement row, and the shelf inquiry page asks "how much is on this shelf?" hundreds of times a day. It has started to crawl: telemetry shows each lookup dragging every movement row of the shelf across the wire just to add them up in a loop. The fix is not a faster loop — it is a table designed so the database keeps the totals ready.

## Requirements

Create a **table** named `"Shelf Movement Entry"` with exactly these fields:

- `"Entry No."` — `Integer`, the primary key. The grading tests insert movement rows directly and assign `"Entry No."` themselves.
- `"Shelf Code"` — `Code[20]`.
- `"Item No."` — `Code[20]`.
- `Quantity` — `Decimal`.

Besides the primary key, the table must declare a secondary key whose field list **starts with** `"Shelf Code", "Item No."` (in that order) and which carries `Quantity` among its `SumIndexFields`. Leave the key enabled and its SIFT index maintained — this is the key that lets SQL Server keep a pre-summed total per shelf and item.

Create a **codeunit** named `"Shelf Totals"` with two public procedures:

```al
procedure QuantityOnShelf(ShelfCode: Code[20]): Decimal
procedure QuantityOnShelfForItem(ShelfCode: Code[20]; ItemNo: Code[20]): Decimal
```

Rules:

1. `QuantityOnShelf` returns the sum of `Quantity` over every movement carrying exactly that `"Shelf Code"`, across all items on the shelf.
2. `QuantityOnShelfForItem` returns the sum of `Quantity` over the movements carrying exactly that `"Shelf Code"` **and** that `"Item No."`. The same item sitting on a different shelf must not leak into the total.
3. Movements are signed: put-aways are positive, picks are negative, and negative rows reduce the total.
4. A shelf — or a shelf-and-item combination — with no movements at all totals exactly 0. Neither procedure ever raises an error.
5. **The row budget:** after a warm-up call, one call to either procedure must read **at most 25 rows**, measured with `SessionInformation.SqlRowsRead` around a single call while the graded filter holds several hundred movement rows. An implementation that fetches every movement row and adds them up in AL reads them all and fails — however few SQL statements it needs to do so. Let the database hand you the answer, not the ingredients.

## What the tests check

The grading tests seed movements marked `TRYAL-*` with quantities generated fresh every run, so hardcoded answers fail. They assert per-shelf and per-shelf-and-item totals, that shelves and items stay separate, that a negative movement reduces both the shelf total and the item total, and that empty shelves come back as exactly 0. One test reads your table's key metadata (the virtual `Key` table) and fails unless it finds an enabled key whose field list starts with `"Shelf Code", "Item No."`, whose `SumIndexFields` include `Quantity`, and whose SIFT index is maintained. The budget tests warm up with one throwaway call, then invalidate the server's data cache with a decoy write — a repeated call served from cache memory reads zero rows, so cached reads can't smuggle a row-hungry loop past the budget — and snapshot `SessionInformation.SqlRowsRead` around a second call to each procedure.

## Learn More

- [SumIndexField Technology (SIFT)](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-sift-technology)
- [SIFT and SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-sift-and-sql-server)
- [SumIndexFields Property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sumindexfields-property)
- [MaintainSiftIndex Property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maintainsiftindex-property)
- [Table keys](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys)
