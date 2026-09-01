# FIFO Cost of a Shipment

When an item's Costing Method is FIFO, Business Central answers one question on every outbound posting: what did the units you just shipped originally cost? Each receipt creates a cost layer — a quantity at a unit cost — and each shipment consumes those layers oldest-first, which is why two identical shipments can carry different costs. That layer bookkeeping is the heart of the inventory costing engine, and you are going to build it in miniature.

## Requirements

Create a **codeunit** named `"FIFO Cost Calculator"` with one public procedure:

```al
procedure ComputeShipmentCosts(Quantities: List of [Decimal]; UnitCosts: List of [Decimal]): List of [Decimal]
```

The two lists describe one item's ledger in strict chronological order: entry `i` pairs `Quantities.Get(i)` with `UnitCosts.Get(i)`.

What you may rely on — the tests never violate this:

- Both lists always have the same length, and no quantity is ever zero.
- A **positive** quantity is a receipt of that many units at the entry's unit cost. Unit costs of receipts are always `> 0`.
- A **negative** quantity is a shipment of `Abs(quantity)` units; the entry's unit cost is always `0` and carries no information.
- Quantities and unit costs have at most three decimal places — units can be fractional (kilograms ship in tenths).

What the returned list must guarantee — all of it is graded:

1. Exactly one amount per **shipment** entry, in chronological order — receipts produce no output. A ledger with no shipments returns an empty list.
2. Each amount is the cost of the goods shipped by that entry, as a positive number: the shipment consumes the item's cost layers strictly oldest-first. A shipment may span several layers, and a layer partially consumed by one shipment keeps only its remaining quantity for the next.
3. A receipt posted after a shipment joins the back of the queue: it can only ever be consumed by shipments that come later in the ledger.
4. Each shipment's cost is rounded to the nearest cent, ties away from zero — and the rounding happens exactly once per shipment, on the exact accumulated cost. Rounding each layer's piece separately produces a different (wrong) answer on some ledgers.
5. If a shipment asks for more units than are on hand at that point in the ledger, the whole call must fail with an error message that contains the phrase `Insufficient inventory` (matched exactly, including capitalization). A receipt further down the ledger does not excuse the shortfall — inventory that has not arrived yet cannot ship.

## What the tests check

The tests call `ComputeShipmentCosts` on fixed ledgers that cover each rule — a single layer, a shipment spanning two layers (where LIFO and average costing give different answers), a layer served across two shipments, a layer exhausted exactly at its boundary, a receipt arriving between shipments, a shipment that drains inventory to exactly zero and succeeds (followed by a restock and another shipment), fractional quantities whose per-layer pieces round differently than the total, a cost landing exactly on a half cent (where ties-to-even rounds the wrong way), a receipts-only ledger, and the two over-shipment error cases — plus one randomized 24-entry ledger whose expected costs are recomputed independently inside the test, so hardcoding the examples fails. All cost comparisons are exact to the cent.

## Learn More

- [Design details: Costing methods](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-costing-methods)
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
- [System.Round(Decimal [, Decimal] [, Text]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method)
- [Decimal data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type)
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling)
