# Trace an Order's Fulfilment Across Posted Documents

"What actually happened to order S-1042?" is a question your support team answers every day, and Business Central makes them earn it: the order was shipped in two parts, invoiced from a separate document, and the base app offers no single view that ties it all together. The order's own lines only show totals — the per-document story lives in the posted tables, which record exactly which order line each posted line came from.

Your job is a codeunit that reconstructs that story for one order line: which posted shipments delivered it, which posted invoices billed it, how an invoice traces back to a specific shipment, and what still has not left the warehouse.

## Requirements

Create a **codeunit** named `"Order Fulfilment Trace"` with four public procedures:

```al
procedure ShippedQuantityByDocument(OrderNo: Code[20]; OrderLineNo: Integer; var QtyByDocument: Dictionary of [Code[20], Decimal])
procedure InvoicedQuantityByDocument(OrderNo: Code[20]; OrderLineNo: Integer; var QtyByDocument: Dictionary of [Code[20], Decimal])
procedure InvoicedQuantityForShipmentLine(ShipmentNo: Code[20]; ShipmentLineNo: Integer): Decimal
procedure OutstandingQuantity(OrderNo: Code[20]; OrderLineNo: Integer): Decimal
```

Rules:

1. `ShippedQuantityByDocument` fills `QtyByDocument` with one entry per posted sales shipment that shipped the given order line: the key is the posted shipment's document number, the value is the quantity of that order line shipped on that document. Posted shipment lines record their origin in `Sales Shipment Line`'s `"Order No."` and `"Order Line No."` fields.
2. `InvoicedQuantityByDocument` does the same for posted sales invoices: `Sales Invoice Line` carries the same `"Order No."`/`"Order Line No."` pair. If one posted invoice carries several lines for the same order line — an invoice assembled from several shipments does — their quantities are **summed into that invoice's single entry**.
3. Both dictionary procedures start from a clean slate: whatever the caller left in `QtyByDocument` is discarded, and an order line with no posted documents yields an empty dictionary.
4. `InvoicedQuantityForShipmentLine` answers the reverse question — how much of one posted shipment line has been billed. Posted invoice lines record which shipment line they invoice in `Sales Invoice Line`'s `"Shipment No."` and `"Shipment Line No."` fields; return the total invoiced quantity pointing at the given shipment line, or `0` if nothing does.
5. `OutstandingQuantity` returns the part of the order line's quantity that has not been shipped yet. It must agree with what the order line itself reports: an order line of 10 with 7 shipped has 3 outstanding. You may assume the order line exists.
6. Matching is always per order **line**, not per order: two lines of the same item on one order must keep their own separate trace.
7. Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The tests build real orders and post them in parts — ship some, ship more, then invoice the shipped quantity, both directly from the order and via a separate invoice pulled from the shipments — and assert the exact content of each dictionary: number of entries, keys, and per-document quantities. They pre-load a stale entry into the dictionary to check it gets discarded, put two lines of the same item on one order to check the traces stay separate — in the shipped map, in the invoiced map, and in the per-shipment-line invoiced total — sum a two-shipment invoice into one entry, ask for the invoiced quantity of a specific shipment line (including one that was never invoiced, expecting 0), and cross-check `OutstandingQuantity` against the order line's own quantity fields — including a fully shipped line, expecting 0.

## Learn More

- [Process partial shipments](https://learn.microsoft.com/en-us/dynamics365/business-central/sales-how-send-partial-shipments) — the business flow the tests replay: one order, several shipments.
- [Posting sales](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-post-sales) — what posting a sales order actually creates, and where it lands.
- [Combine shipments on a single invoice](https://learn.microsoft.com/en-us/dynamics365/business-central/sales-how-to-combine-shipments-on-a-single-invoice) — how one invoice ends up carrying lines from several shipments.
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — the type your procedures fill, and what its methods do when a key already exists.
