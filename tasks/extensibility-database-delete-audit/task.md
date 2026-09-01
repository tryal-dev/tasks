# Audit Every Deleted Document

The compliance team asked a simple question about the document vault: *who removed this document, and when?* Nobody could answer, because there is no answer to be had — documents leave the vault through half a dozen code paths. The archiving job deletes in bulk over a filter. The folder cleanup wizard deletes a folder and lets the cascade take its children. A data-fix codeunit written years ago deletes records with the table triggers switched off on purpose. Some of that code you don't own and can't change.

An audit trail that only catches the polite deletions is worse than none at all, so this one has to sit below all of them: Business Central lets a table ask the platform to raise a **database delete trigger** for it, and the platform then raises that trigger for every row that leaves the table, whatever AL statement removed it. That is exactly how the standard Change Log records deletions. Your job is to wire the vault into it.

## Requirements

Create three **tables** and one **codeunit**. The names and types below are the contract the grading tests bind to — match them character for character.

Table `"Vault Folder"`:

- `"Folder Code"` of type `Code[20]` — the primary key
- `Description` of type `Text[100]`
- an `OnDelete` trigger that deletes every `"Vault Document"` belonging to the folder

Table `"Vault Document"`:

- `"Document Code"` of type `Code[20]` — the primary key
- `"Folder Code"` of type `Code[20]`
- `Title` of type `Text[100]`

Table `"Vault Delete Log"` — the audit trail:

- `"Entry No."` of type `Integer` with `AutoIncrement = true` — the primary key, so the platform numbers each row and your code never assigns this field
- `"Table No."` of type `Integer`
- `"Document Code"` of type `Code[20]`
- `Title` of type `Text[100]`

Codeunit `"Vault Delete Audit"` — the audit itself. The tests never call it directly; they delete `"Vault Document"` rows and then look at `"Vault Delete Log"`.

Rules:

1. Whenever a `"Vault Document"` row is removed from the database, exactly **one** `"Vault Delete Log"` row appears for it — no matter how it was removed. `Delete(true)`, `Delete(false)`, a `DeleteAll` over a filter, and a cascade from `"Vault Folder"`'s own `OnDelete` all count, and all must produce the same single row.
2. That log row carries the vanished document's data: `"Table No."` is the table number of `"Vault Document"`, `"Document Code"` and `Title` are copied from the row that was deleted.
3. Nothing else writes to the log. Inserting or modifying a `"Vault Document"` writes no row, and deleting a `"Vault Folder"` writes no row — only `"Vault Document"` is audited.
4. `"Vault Delete Audit"` must opt `"Vault Document"` into the platform's **database delete trigger** — no table gets it by default — and must take the vanished row from that trigger. Both halves are event subscriptions on one base application codeunit, and both must live in `"Vault Delete Audit"`: the tests look them up in the platform's registry of active event subscriptions (the `Event Subscription` system table) and assert that your codeunit subscribes to the question the platform asks about a table's database triggers, and to the database delete trigger itself. A solution built only on the table's own `OnBeforeDeleteEvent` / `OnAfterDeleteEvent` fails both. Opt in only what the audit needs — the trigger adds cost to every delete on a table that raises it, so leave `"Vault Folder"` out. That last part is good practice and not graded: the grading environment's test toolkit switches the database triggers on for every table, so which tables your code opted in cannot be observed there.

Finding *where* a table asks the platform for its database triggers, and *where* the platform hands you the vanished row, is the exercise. Expect that row to arrive generically: one hook serves every table in the database, so it cannot be typed to yours.

## What the tests check

The tests seed a folder with three documents and delete them four ways — one by one with `Delete(true)`, one by one with `Delete(false)`, in bulk with `DeleteAll` over a `"Folder Code"` filter, and by deleting the parent folder so its `OnDelete` cascade removes them — and after each path assert **exactly one** log row per document and exactly three in total, so a missed path and a double-logged one both fail. Another test deletes a single document whose code and title are randomly generated and compares the log row's `"Table No."`, `"Document Code"` and `Title` against those values, so a hardcoded row fails. Two negative tests assert that inserting and then modifying a document writes nothing, and that deleting an empty `"Vault Folder"` adds no log row at all. A final pair of tests reads the `Event Subscription` system table: one asserts that `"Vault Delete Audit"` subscribes to the platform's database-trigger setup question, the other that it subscribes to the platform's database delete trigger. Those two are what enforce rule 4; the four delete-path tests read the log only.

Pick object IDs in the range **50100–50199** and reference other objects **by name, never by ID**.

Captions on tables and fields are good practice and not graded.

## Learn More

- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — the delete paths your audit has to survive, and what each of them runs.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — the `[EventSubscriber]` syntax for hooking into a base application codeunit's events.
- [RecordRef data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type) — a record you hold without knowing its table at compile time; `Number` tells you which table it turned out to be.
- [FieldRef data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-data-type) — reading a single field value out of such a record.
