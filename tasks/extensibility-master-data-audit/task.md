# A Change Log for Item Master Data

It is the week before go-live and the purchasing manager asks the question every consultant hears on every project: *who changed this price, and what was it before?* The standard Change Log could be switched on, but the customer wants a small, code-owned trail for exactly two Item fields — one your extension writes itself, so their reporting can query it like any other table.

The catch: prices are changed from the item card, from a pricing import that deliberately skips the table triggers, and from code you don't own. Your audit never gets called by any of them — it has to notice every insert and every modify of an `Item` record on its own, see what the database actually stored, and write the difference down. Business Central raises events for exactly this; finding the right ones — and understanding what the platform hands you there — is the exercise.

## Requirements

Create one **table** and one **codeunit**. The names and types below are the contract the grading tests bind to — match them character for character.

Table `"Item Change Entry"` — the trail (given complete in the starter):

- `"Entry No."` of type `Integer` with `AutoIncrement = true` — the primary key, so the platform numbers each row and your code never assigns this field
- `"Item No."` of type `Code[20]`
- `"Field Name"` of type `Text[30]`
- `"Old Value"` of type `Text[100]`
- `"New Value"` of type `Text[100]`

Codeunit `"Item Change Log"` — the audit itself. The tests never call it; they insert and modify `Item` records with ordinary record operations and then read `"Item Change Entry"`.

The audited fields are `"Unit Price"` and `Description` of the standard `Item` table. Rules:

1. When an `Item` row is **inserted** into the database, write one row per audited field: `"Old Value"` blank, `"New Value"` holding the inserted value.
2. When an `Item` row is **modified** in the database, write one row per audited field whose stored value actually changed: `"Old Value"` holding the value the database had before the write, `"New Value"` the value after. A modify that changes neither audited field writes nothing; a modify that changes both writes two rows.
3. Read in `"Entry No."` order, the rows for one field on one item form a chain: each row's `"Old Value"` equals the previous row's `"New Value"`, starting from the blank insert row.
4. The audit sits **below** the `RunTrigger` parameter: `Insert(false)` and `Modify(false)` must be logged exactly like `Insert(true)` and `Modify(true)`. Whether the caller ran the table triggers is information, not a gate.
5. Only what the database saw: a `Validate` that is never followed by `Modify` must write nothing — the change never reached the table, so there is nothing to audit.
6. Changes to any other `Item` field write no row.
7. `"Item No."` holds the item's `"No."`. `"Field Name"` holds exactly `Unit Price` or `Description` — the field names, character for character. Values are stored as text: `Description` as-is, `"Unit Price"` exactly as the default `Format` of the decimal renders it (the tests compare against `Format` of the same number).

## What the tests check

The tests insert an item with a generated price and description and assert exactly two rows, one per audited field, each with a blank `"Old Value"` and the inserted value in `"New Value"`. One test changes the price twice with `Modify(true)` and walks the three `Unit Price` rows in `"Entry No."` order, asserting the full blank → insert price → first change → second change chain — an `"Old Value"` taken from anywhere but the record's previous database state fails here. Another changes the price with `Modify(false)` and still expects the change row, old and new values intact. Negative tests assert that a `Modify` changing neither audited field writes nothing, that a `Validate` never followed by `Modify` writes nothing, and that changing only a non-audited field (`"Vendor Item No."`) writes nothing. Two more tests check per-field granularity: a description change is logged with its old and new text, and a single `Modify` changing both fields writes exactly one row per field.

Pick object IDs in the range **50100–50199** and reference other objects **by name, never by ID**.

Captions are good practice and not graded; so is skipping temporary `Item` records, which never reach the database.

## Learn More

- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — the event model, and which kinds of events exist beyond the ones application code publishes.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — the `[EventSubscriber]` syntax, including the form used for events on tables.
- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — what the `RunTrigger` parameter actually controls on each write method.
