# Enforce a Customer Order Cap at Release

Credit control has negotiated a hard ceiling with some customers: no single sales order above an agreed amount. Sales users keep releasing orders past that ceiling, and by the time anyone notices, the warehouse has already picked the goods. The release step is handled by base code — codeunit 414 `"Release Sales Document"` — which you cannot modify. Your job is to make an over-cap order impossible to release, from the outside.

## Requirements

1. Create a **table extension** for the `Customer` table with a field named `"Max Order Amount (LCY)"` of type `Decimal`.
2. Create a new **codeunit** — its name is up to you (not graded) — that blocks the release of a sales order whose amount exceeds the sell-to customer's `"Max Order Amount (LCY)"`. Do not try to change base objects; extend them from the outside.

Rules the tests enforce:

- The cap applies only when a sales document of type **Order** is released. Other document types (quotes, invoices, credit memos, ...) must release regardless of the cap.
- The cap is read from the order's **sell-to** customer.
- The order's amount is the sales header's `Amount` — the sum of its line amounts **excluding VAT**. The graded documents carry no currency code, so that amount is already in LCY; currency conversion is out of scope and not graded.
- Over the cap means **strictly greater**: an order whose amount equals the cap exactly must still release.
- A `"Max Order Amount (LCY)"` of 0 means the customer has no cap — any amount releases.
- Blocking must happen by raising an error, and the error message must contain the exact text `Max Order Amount (LCY)` (the rest of the wording is up to you).
- A blocked order must be left untouched: its `Status` stays `Open`.

Pick all object and field IDs in the 50100–50199 range, and reference other objects by name, never by ID. No page extensions are needed — grading reads and writes the field in code. Captions and tooltips are good practice but not graded.

## What the tests check

The tests create customers with generated caps and sales documents whose line amounts they control exactly, then release them through the standard release routine. They assert that releasing an over-cap order fails with an error containing `Max Order Amount (LCY)` and that the order's `Status` is still `Open` afterwards; that an under-cap order and an order exactly at the cap both reach `Status` `Released`; that a customer with a cap of 0 can release an order of any amount; that an over-cap sales **invoice** and an over-cap **quote** both still release, because the cap governs orders only; and that an order is still blocked when its **bill-to** customer differs from the sell-to customer and has no cap — the cap must come from the sell-to customer.

## Learn More

- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — adding your field to the `Customer` table.
- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — how publishers, subscribers, and raised events let you hook into base code you cannot modify.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — writing a subscriber method in your own codeunit.
- [FlowFields overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields) — why some header amounts are 0 until you ask the system to calculate them.
