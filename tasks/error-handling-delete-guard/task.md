# No Deleting Released Orders

A released sales order is a promise: the warehouse is already picking against it, and availability calculations count on it. Last week someone deleted a released order by accident, and a picker spent an hour hunting for a shipment that no longer existed. Standard Business Central happily deletes released orders — your job is to close that hole without touching a single base object.

## Requirements

1. Create a **codeunit** named `"Order Delete Guard"`. Base application objects must not be modified — the guard has to attach itself to the standard deletion flow from the outside.
2. When a sales order (a `Sales Header` record with `"Document Type"` = `Order`) whose `Status` is `Released` is deleted, the deletion must fail with an error.
3. The error message must contain the exact phrase `is released and cannot be deleted` (note the casing) and the `"No."` of the order. A message like `Sales order 1017 is released and cannot be deleted. Reopen it first.` satisfies both.
4. A blocked deletion must leave the order untouched: afterwards the order still exists and all of its sales lines are still there.
5. An order whose `Status` is `Open` — never released, or released and then reopened — must delete exactly as standard Business Central would, its lines included.
6. Only sales **orders** are guarded: other sales documents (quotes, invoices, credit memos) must stay deletable even when released.

The codeunit name `"Order Delete Guard"` is where your guard code is expected to live, but the tests grade deletion behavior, not the codeunit's name.

## What the tests check

The tests create real sales orders with lines and release them through the standard release flow: deleting a released order must fail with the message from rule 3, and the order and its lines must still exist afterwards; deleting an order that was never released, and one that was released and then reopened, must succeed and remove both the header and its lines; and deleting a **released sales invoice** and a **released sales credit memo** must succeed — a guard that blocks every released sales document fails those tests.

Pick object IDs in the range **50100–50199** and reference other objects **by name, never by ID**.

## Learn More

- [Status Field on Documents](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-document-status) — what the Released status means and why released documents are protected.
- [Release and reopen sales and purchase documents](https://learn.microsoft.com/en-us/dynamics365/business-central/release-reopen-documents) — the release/reopen flow the tests drive.
- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — how extensions hook into standard application flows without modifying them.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — the syntax for attaching your own method to a published event.
