# Default the Line from the Item Card

Your warehouse assigns every item a quality grade, and sales wants that grade stamped on each order line automatically — no retyping, no lookups. In Business Central this is a classic pairing: two table extensions carry the field, and an event subscriber copies it the moment an item lands on a line.

## Requirements

1. Create a **table extension** that extends the `Item` table and adds a field named `"Quality Grade"` of type `Code[10]`.
2. Create a **table extension** that extends the `"Sales Line"` table and adds a field named `"Quality Grade"` of type `Code[10]`.
3. Create a **codeunit** with an event subscriber to the `"Sales Line"` table's `OnAfterAssignItemValues` integration event, so that validating `"No."` on an item line copies the item's `"Quality Grade"` onto the line.

The copy is unconditional — the line always mirrors the item that is on it:

- An item with a blank grade produces a line with a blank grade.
- Re-validating `"No."` to a different item replaces the line's grade with the new item's grade.
- Re-validating `"No."` to an item without a grade leaves the line's grade blank.

The subscriber must fire during ordinary validation, without anyone binding or calling your codeunit first.

Pick object and field IDs in the range **50100–50199**, and reference other objects **by name, never by ID**. Captions are good practice but not graded.

## What the tests check

The grading tests create items and sales orders with the standard libraries: an item with a **generated** grade lands that grade on a new order line (so a hardcoded value fails); a grade-less item leaves the line blank; re-validating `"No."` to a second item overwrites the grade, and to a grade-less item clears it; the tests reach both fields by name at run time (a missing or misspelled field fails with a message saying so), and finally both fields must be declared as type `Code` with a maximum length of exactly 10 — a `Text[10]` field fails, and note the exact field name `"Quality Grade"` on both tables.

## Learn More

- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — how to add fields to Item and Sales Line.
- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — publisher/subscriber model in one page.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — how to write a subscriber method step by step.
- [EventSubscriber attribute](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-eventsubscriber-attribute) — the attribute's arguments, including the `Database::` syntax for table publishers.
