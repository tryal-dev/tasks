# Return It at the Cost You Sold It

Two deliveries of the same item arrive weeks apart, one cheap and one expensive. A customer buys four pieces off the cheap pile, then sends two of them back. What are those two pieces worth?

Left alone, Business Central answers with its costing method: FIFO, average, standard — whatever the item card says. That answer is wrong here. The goods that came back are the very goods that left, and inventory only stays honest if they re-enter at the cost they left at. Get it wrong and you have quietly invented profit on a return, which is the kind of thing auditors find.

Your job is to build the return in AL so the costing method never gets a vote.

## Requirements

Implement the codeunit `"Exact Cost Return Mgt."` with exactly these two public procedures — the grading tests bind to every name below character for character:

```al
procedure FindSaleEntryNo(PostedShipmentNo: Code[20]): Integer
procedure PostExactCostReturn(PostedShipmentNo: Code[20]; ReturnQty: Decimal): Code[20]
```

Rule for `FindSaleEntryNo`:

1. Return the `"Entry No."` of the item ledger entry that the posted sales shipment created — the outbound Sale entry whose document is that shipment. Every graded shipment has exactly one item line, so exactly one such entry exists.

Rules for `PostExactCostReturn`:

2. Before creating or posting anything, refuse a return bigger than the delivery: if `ReturnQty` is greater than the `Quantity` on the posted shipment's item line, raise an error with a message that contains the phrase `exceeds the shipped quantity` — matched exactly, lower case, as one contiguous phrase. Nothing may be posted in that case.
3. Otherwise create a sales credit memo for the shipment's `"Sell-to Customer No."` with exactly one line: type `Item`, the shipped item, quantity `ReturnQty`.
4. Post the credit memo — received and invoiced — and return the number of the posted sales credit memo.
5. The returned goods must re-enter inventory at the cost they left at. The item ledger entry the credit memo creates must carry a `"Cost Amount (Actual)"` of `ReturnQty` × the original sale entry's cost per unit, and an **item application entry** must record the pair: the return's entry as the inbound entry, the shipment's entry as the outbound entry. The item's costing method must not decide this cost — the fixtures are built so that FIFO's next layer and the item's blended unit cost both give a different answer, and both fail.
6. The shipment's own item ledger entry keeps its cost. A return posts a new inbound entry; it never revalues, rewrites or replaces the sale.

Environment notes — the tests never violate these:

- The graded item uses the **FIFO** costing method and has two purchase layers of 10 pieces at different unit costs, both received and invoiced before any sale is posted.
- Every graded shipment carries exactly one item line, with no location code, no variant, and no item tracking.
- `ReturnQty` is always positive; the only error case graded is a quantity larger than the shipment's.
- The grading company has `"Ext. Doc. No. Mandatory"` switched off, so neither the shipment nor your credit memo needs an external document number.
- The tests run the **Adjust Cost - Item Entries** batch job before reading any cost, so you never have to force a cost adjustment yourself.
- Pick object IDs in 50100–50199 and reference other objects by name, never by ID.

## What the tests check

A sale of 4 pieces is drawn from a 10.00 layer while a 25.00 layer sits behind it; 2 pieces are returned, and the return's item ledger entry must show `"Cost Amount (Actual)"` of exactly 20.00 — FIFO's next layer and the item's blended unit cost both give something else; the same case runs again with generated layer costs and a 3-piece return, so a hardcoded amount cannot survive. A test posts two shipments that drew from different layers and returns against the second one, so resolving the item's first sale entry instead of the given shipment's fails; another sells 14 pieces across both layers and returns all 14 — the largest quantity the guard may accept — and requires the return to carry the sale's blended cost and the two entries to cancel out, both to the cent. Further tests check the item application entry that pairs the return's entry (inbound) with the sale's entry (outbound) for the returned quantity, check that the returned number is a posted sales credit memo for the shipment's customer holding an item line of the returned quantity, check that `FindSaleEntryNo` resolves the shipment it was handed rather than the item's first sale, check that the return still posts and still carries the original cost when `"Exact Cost Reversing Mandatory"` is switched on in Sales & Receivables Setup, and check that the shipment's own entry keeps its cost afterwards. Returning 5 pieces of a 4-piece shipment must fail with a message containing `exceeds the shipped quantity` and must leave no inbound entry behind.

## Learn More

- [Design details: Costing methods](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-costing-methods) — what FIFO would decide on its own, and why that is the answer you have to override.
- [Design details: Inventory posting](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-inventory-posting) — the split between item ledger entries, item application entries and value entries that every posting produces.
- [Design details: Inventory valuation](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-inventory-valuation) — what `"Cost Amount (Actual)"` actually sums up.
- [Design details: Cost adjustment](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-cost-adjustment) — why an entry's cost is only final once the adjustment batch job has run.
