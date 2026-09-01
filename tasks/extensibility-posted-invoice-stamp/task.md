# Stamp the Posted Invoice

Sales operations records a deal reference on every sales document, and finance wants that reference on the posted invoice so they can trace each invoice back to the deal that produced it. The catch: posted documents are created by the standard posting routine, codeunit 80 `"Sales-Post"` — base code you cannot modify. Your job is to carry the field across from the outside.

## Requirements

1. Create a **table extension** for the `Sales Header` table with a field named `"Deal Reference"` of type `Text[30]`.
2. Create a **table extension** for the `Sales Invoice Header` table with a field named `"Deal Reference"` of type `Text[30]`. Give the two fields **different field IDs**: the posting routine happens to copy same-numbered fields between these two tables, and relying on that accidental ID collision is exactly the fragile shortcut this task exists to replace.
3. When a sales document is posted, the resulting posted `Sales Invoice Header` must carry the same `"Deal Reference"` value the sales document had at posting time — both when a **sales order** is posted (ship and invoice) and when a **sales invoice** document is posted directly.
4. When the sales document's `"Deal Reference"` is blank, the posted invoice's field must stay blank.
5. Put your logic in a new **codeunit** — its name is up to you (not graded). Do not try to change base objects; extend them from the outside.

Pick all object and field IDs in the 50100–50199 range, and reference other objects by name, never by ID. No page extensions are needed — grading reads and writes the fields in code. Captions are good practice but not graded.

## What the tests check

The tests create real sales documents with the standard library and post them through the standard posting routine. They post a sales order carrying a generated 30-character reference and a directly posted sales invoice carrying another, and assert that the posted `Sales Invoice Header`'s `"Deal Reference"` matches character for character. They post an order whose reference was never filled in and assert the posted field stays blank. Finally they verify both fields are declared as exactly `Text[30]` by checking their maximum length, and that the two `"Deal Reference"` fields are declared with **different field IDs** — a submission that relies on the accidental same-ID copy fails.

## Learn More

- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — adding fields to `Sales Header` and `Sales Invoice Header`.
- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — how publishers, subscribers, and raised events fit together.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — writing a subscriber method in your own codeunit.
- [EventSubscriber attribute](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-eventsubscriber-attribute) — the attribute syntax, and the Shift+Alt+E event lookup in VS Code.
