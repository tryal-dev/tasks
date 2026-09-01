# On Hand, Per Location

The warehouse team keeps asking the same question: "how much of item X is sitting where?" The Item card's **Inventory** field only shows the grand total across the whole company, so they want one number per location, straight from the ledger — the same ledger every posted receipt, shipment and adjustment writes to.

## Requirements

Create a **codeunit** named `"Stock By Location"` with a public procedure:

```al
procedure OnHandByLocation(ItemNo: Code[20]): Dictionary of [Code[10], Decimal]
```

Rules:

1. Every posted inventory movement of an item is recorded as an `"Item Ledger Entry"` carrying the item number, a `"Location Code"` and a signed `Quantity` — the on-hand quantity of `ItemNo` at a location is the sum of `Quantity` over the item's entries at that location, and negative entries subtract.
2. The dictionary contains exactly one key per location code that appears on at least one of the item's ledger entries — a location where the item has never moved must not appear, even if the Location record exists.
3. A location whose entries net to exactly 0 **stays in the dictionary with value 0** — "we track it here and the shelf is currently empty" is information; dropping the key is not.
4. Entries posted without a location code belong to no location: ignore them — the dictionary must never contain a blank key.
5. An item with no ledger entries at all (or an item number that matches no item) yields an empty dictionary — never an error.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The tests create fresh items and fresh locations, post real item-journal adjustments across them — positive and negative, with quantities generated at run time, so no constant can pass — and compare your dictionary key by key: the exact key count, the exact on-hand quantity per location, a location whose postings net to exactly zero, entries of another item at the same location, the blank-location rule, and the empty-dictionary case. The tests run in a real company where other items and locations already have ledger entries, so your result must be driven purely by the given item's entries.

## Learn More

- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — the type you return the totals in, with its methods for adding, updating and looking up keys.
- [Design details: Inventory posting](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-inventory-posting) — where item ledger entries come from and what they record.
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method) — narrowing a table to exactly the rows you care about.
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods) — reading through a filtered set safely.
