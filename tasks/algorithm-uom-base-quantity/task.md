# Qty. per Unit Without the Drift

An item is stocked in pieces and sold in boxes of six. Document lines carry the quantity in the selling unit, but inventory, reservations, and item tracking all live in the base unit — so every line also carries a base quantity, derived from Qty. per Unit of Measure. Get the rounding wrong and the warehouse that ships five of a six-piece box posts 4.99998 pieces, and an order split over several shipments never closes to the piece.

You are building that conversion in miniature: the base-quantity math Business Central runs on every document line, plus the invariant that keeps split postings honest.

## Requirements

Create a **codeunit** named `"Base Qty Calculator"` with two public procedures:

```al
procedure CalcBaseQty(Qty: Decimal; QtyPerUnitOfMeasure: Decimal; QtyRoundingPrecision: Decimal): Decimal

procedure CalcBaseQtyToPost(QtyToPost: Decimal; QtyPostedSoFar: Decimal; QtyPerUnitOfMeasure: Decimal; QtyRoundingPrecision: Decimal): Decimal
```

What you may rely on — the tests never violate this:

- `Qty`, `QtyToPost`, and `QtyPostedSoFar` are `>= 0` and carry at most five decimal places.
- `QtyPerUnitOfMeasure` is `> 0` and carries at most five decimal places.
- `QtyRoundingPrecision` is `0` or a positive rounding step; the tests use `0`, `0.1`, and `1`.

`CalcBaseQty` converts a document-line quantity into the base unit of measure:

- The effective rounding step is `QtyRoundingPrecision` when it is not `0`; otherwise it is `0.00001`, the finest precision BC ever stores a quantity with.
- The result is the exact product `Qty` × `QtyPerUnitOfMeasure` rounded to the nearest multiple of the effective step; a product exactly halfway between two steps rounds away from zero.

`CalcBaseQtyToPost` returns the base quantity for one partial posting of a line: `QtyToPost` is being posted now; `QtyPostedSoFar` is the line quantity already posted in earlier splits (`0` on the first posting). All three guarantees are graded:

1. The result is a multiple of the effective rounding step.
2. Split postings never drift: after every posting in a split sequence — not only the last one — the base quantities returned so far sum to exactly `CalcBaseQty` of the total quantity posted so far.
3. Every posting stays honest: the result differs from the exact product `QtyToPost` × `QtyPerUnitOfMeasure` by strictly less than one effective step.

Guarantee 2 has teeth. With 1 CAN = 0.33333 KG, posting 0.5 CAN six times must leave exactly 0.99999 KG posted — the base quantity of 3 CAN — yet converting each posting on its own hands out 0.16667 KG six times, which is 1.00002 KG. Some posting has to absorb the rounding of its predecessors, and guarantee 3 forbids parking the whole correction on one posting of a long sequence.

The box story works the same way: a customer orders 1 BOX of a six-piece item whose base unit snaps to whole pieces (`QtyRoundingPrecision` = 1). Posting 0.83333 BOX must yield 5 pieces — not 4.99998 — and the closing posting of 0.16667 BOX must yield exactly the 1 piece that is left.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

`CalcBaseQty` is graded on fixed fixtures — whole units, products that need the 0.00001 rounding including an exactly-halfway product and a below-the-midpoint product that must round down, the five-of-a-six-piece-box snap with precision 1, a precision of 0.1, zero quantity, and a two-step conversion chain that feeds one conversion's rounded result into the next — plus a randomized quantity with the expected value computed independently, so hardcoding the examples fails. `CalcBaseQtyToPost` is graded on the box postings and the CAN splits above, value by value, on a first posting whose exact product must round down, and on a randomized split sequence where all three guarantees are checked after every posting. All equality comparisons are exact.

## Learn More

- [Set up units of measure](https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-setup-units-of-measure) — the five-of-six-pieces story and the Quantity Rounding Precision field this task models.
- [System.Round(Decimal [, Decimal] [, Text]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method) — precision steps and rounding directions in AL.
- [Decimal data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type) — what AL decimals can and cannot represent.
