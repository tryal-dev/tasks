# Survive Quote-to-Order

Sales reps tag every quote with the marketing campaign that produced it, and when a deal is won the quote is turned into a sales order by the standard conversion routine, codeunit 86 `"Sales-Quote to Order"` — base code you cannot modify, and it deletes the quote when it is done. Marketing wants the campaign trail to survive: the created order must still carry the tag, and it must be permanently marked as having been won from a quote.

## Requirements

1. Create a **table extension** for the `Sales Header` table with a field named `"Campaign Tag"` of type `Text[30]` and a field named `"Converted From Quote"` of type `Boolean`.
2. When a sales quote is converted to a sales order by codeunit 86 `"Sales-Quote to Order"` (the routine behind the **Make Order** action), the created order must carry the same `"Campaign Tag"` value the quote had at conversion time; a blank tag must stay blank.
3. The created order's `"Converted From Quote"` must be `true`.
4. A sales order created directly — not by converting a quote — must keep `"Converted From Quote"` as `false`.
5. The standard conversion result must stay intact: every item line of the quote must arrive on the created order with its item and quantity unchanged, and no extra lines may appear.
6. Put your logic in a new **codeunit** — its name is up to you (not graded). Do not try to change base objects; extend them from the outside.

Pick all object and field IDs in the 50100–50199 range, and reference other objects by name, never by ID. No page extensions are needed — grading reads and writes the fields in code. Captions are good practice but not graded.

## What the tests check

The tests build real sales quotes with the standard libraries and convert them by running codeunit 86 `"Sales-Quote to Order"` directly. They convert a quote carrying a generated 30-character tag and assert the created order's `"Campaign Tag"` matches character for character, assert `"Converted From Quote"` is `true` on the created order and `false` on an order created directly, and convert a quote whose tag was never filled in to check the order's tag stays blank. They also convert a quote with two item lines carrying generated quantities and assert the order has exactly those two lines with matching items and quantities, and they verify `"Campaign Tag"` is declared as exactly `Text[30]` by checking its type and maximum length, and `"Converted From Quote"` as a `Boolean`.

## Learn More

- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — adding the two fields to `Sales Header`.
- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — how publishers, subscribers, and raised events fit together.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — writing a subscriber method in your own codeunit.
- [EventSubscriber attribute](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-eventsubscriber-attribute) — the attribute syntax, and the Shift+Alt+E event lookup in VS Code.
