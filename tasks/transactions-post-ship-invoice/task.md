# Ship Now, Invoice Later

The warehouse ships today; finance invoices at the end of the month. In Business Central that is one sales order posted twice — first with **Ship**, later with **Invoice** — and the integration that triggers both passes has to report the numbers of the two posted documents back to the system that asked for them.

Getting the posted number back is the part every "how to post from code" example leaves out, and the invoice pass is where it bites: once an order is fully shipped and fully invoiced, the posting routine deletes it, so there is no order left to read the number from afterwards.

## Requirements

Create a **codeunit** named `"Ship Then Invoice"` with two public procedures:

```al
procedure PostShipment(OrderNo: Code[20]): Code[20]
procedure PostInvoice(OrderNo: Code[20]): Code[20]
```

Both are given the `"No."` of a sales order (document type `Order`) and post it through Business Central's standard sales posting routine — the same code the **Post** action on the Sales Order page runs. Writing `Sales Shipment Header` / `Sales Invoice Header` records yourself is not a solution.

Rules:

1. `PostShipment` posts the order **shipping only**: it creates a posted shipment, posts no invoice, and leaves the order in place with the shipped quantity recorded on its lines.
2. `PostShipment` returns the `"No."` of the shipment **that call** posted — the primary key of a `Sales Shipment Header` that exists when the procedure returns. An order may be shipped in several passes; each call returns its own shipment, never an earlier one.
3. `PostInvoice` posts the same order **invoicing only**: it creates a posted invoice and ships nothing further. Watch out — posting leaves its flags behind on the order header, so a pass that shipped leaves "ship" switched on for the next one and a pass that invoiced leaves "invoice" switched on. Each pass has to state both flags, not inherit them: "invoice only" and "ship only" are things your code says, in both procedures.
4. `PostInvoice` returns the `"No."` of the invoice **that call** posted — the primary key of a `Sales Invoice Header` that exists when the procedure returns, even though the order it came from may be gone by then. An order may be invoiced in several passes; each call returns its own invoice, never an earlier one.
5. Only what has been shipped gets invoiced: after a partial shipment, the invoice pass covers the shipped quantity and leaves the rest of the order open for a later shipment.
6. Nothing to post: when no sales order with that `"No."` exists — usually because it was fully shipped and invoiced and posting deleted it — both procedures return an empty `Code[20]` (`''`), post nothing and raise no error. The caller must get that defined answer, not a platform "record does not exist" error. This is the only nothing-to-post case you have to handle: you may assume every order that still exists has something left to ship or to invoice.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The tests build real sales orders with the standard test library, in generated quantities, and drive your two procedures against the real posting routine. They assert that the returned shipment and invoice numbers are the primary keys of posted headers that exist and carry that order's `"Order No."`; that the ship pass posts no invoice and leaves the order open with the quantity shipped and nothing invoiced — including when it runs after an invoice pass, whose flags it must not inherit; that a second ship pass and a second invoice pass each return the document that call posted, not the earlier one; that after a partial shipment the invoice covers exactly the shipped quantity and the order stays open for the remainder; and that both procedures answer `''` — with no error and no new posted document — for an order that was posted away, as does the ship pass for an order number that never existed at all.

## Learn More

- [Posting sales](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-post-sales) — what shipping and invoicing a sales order each produce, and when the order disappears.
- [Process partial shipments](https://learn.microsoft.com/en-us/dynamics365/business-central/sales-how-send-partial-shipments) — the business rules the posting routine enforces between shipped and invoiced quantities.
- [Codeunit.Run(var Record) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunitinstance-run-method) — running a codeunit that is bound to a table, and how the record parameter is passed to it.
- [Record.Get([Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method) — reading a record by primary key and taking the boolean return instead of an error.
