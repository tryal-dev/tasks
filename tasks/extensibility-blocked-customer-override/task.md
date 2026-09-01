# The Cash-on-Delivery Exemption

Credit control sets a customer's `Blocked` field to `Ship` when invoices go unpaid, and from that moment standard Business Central refuses to post shipments for them. But sales has struck a deal: customers approved for cash on delivery still get their goods — they pay the driver at the door. Your job is to lift exactly that one guard for exactly those customers, without modifying the base application and without widening the hole: every other blocked check must keep working as if your extension did not exist.

## Requirements

1. Create a **table extension** that extends the `Customer` table and adds a field named `"Cash-on-Delivery Approved"` of type `Boolean`.
2. Create a **codeunit** named `"COD Shipment Exemption"` that implements the exemption. Base application objects must not be modified — your code has to attach itself to the standard blocked-customer check from the outside.
3. When a customer has `Blocked` = `Ship` **and** `"Cash-on-Delivery Approved"` is `true`, posting a **shipment** for that customer must succeed: shipping a sales order through the standard sales posting routine completes, a posted sales shipment exists for the order, and the item ledger entries for the shipped item are written.
4. When `"Cash-on-Delivery Approved"` is `false`, nothing changes: shipping a sales order for a `Blocked::Ship` customer fails with the standard error (its text contains `is blocked with type`), and no posted sales shipment exists for the order afterwards.
5. The exemption applies **only** to shipment posting of a `Blocked::Ship` customer. All of the following must still fail with their standard base-application errors even when `"Cash-on-Delivery Approved"` is `true`:
   - shipping a sales order for a customer with `Blocked` = `All` — the `is blocked with type` error, and no posted shipment;
   - shipping a sales order for a customer with `Blocked` = `Invoice` — the `is blocked with type` error, and no posted shipment (in the base application an invoice block also forbids new shipments);
   - shipping a sales order for a customer with `"Privacy Blocked"` = `true` — the standard privacy error (its text contains `blocked for privacy`), and no posted shipment. Note that the grading tests construct the trickiest combination: a customer whose `Blocked` is `Ship`, whose flag is set, **and** who is privacy-blocked — that customer must still be stopped;
   - document entry: validating `"Sell-to Customer No."` on a new sales order with a `Blocked::Ship` customer — the standard check must still raise the `is blocked with type` error;
   - journal posting: posting a general journal line for a customer with `Blocked` = `All` through the standard journal posting routine — the `is blocked with type` error.

Because a `Blocked::Ship` customer cannot be put on a new order, the grading tests always build the sales order first and set `Blocked` afterwards — the realistic sequence, since the block usually arrives after the order exists.

Pick object IDs in the range **50100–50199** and reference other objects **by name, never by ID**. The codeunit name `"COD Shipment Exemption"` is where your exemption code is expected to live, but the tests grade posting behavior, not the codeunit's name.

## What the tests check

The tests write and read back `"Cash-on-Delivery Approved"` on a customer, then drive the standard flows: a sales order is built, the customer is then set to `Blocked::Ship`, and shipping the order must fail with the `is blocked with type` error and leave no posted sales shipment while the flag is off — and must succeed, creating the posted sales shipment and the item ledger entries, once the flag is on. With the flag on, they further verify that a `Blocked::All` customer, a `Blocked::Invoice` customer, and a privacy-blocked `Blocked::Ship` customer still cannot ship (the last with the `blocked for privacy` error), that validating `"Sell-to Customer No."` with a `Blocked::Ship` customer still errors, and that posting a general journal line for a `Blocked::All` customer still errors. Error checks are substring matches against the standard base-application messages quoted above.

## Learn More

- [Block customers](https://learn.microsoft.com/en-us/dynamics365/business-central/receivables-how-block-customers) — what `Ship`, `Invoice`, and `All` block in daily operations.
- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — how extensions hook into standard application logic without modifying it.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — the `[EventSubscriber]` syntax, including subscribing to events published by tables.
- [Discoverability of events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-discoverability) — the Event Recorder, a practical way to find which events fire during posting.
