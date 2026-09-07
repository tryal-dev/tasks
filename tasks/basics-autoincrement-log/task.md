# The Entry No. You Don't Assign

An integration writes one line to a `"Sync Activity Log"` table every time it syncs something — from web-service sessions, background jobs and interactive users at the same time. The first version numbered the entries in AL: find the last entry, add one, insert. Under load, two sessions read the same last number and one of them died with "already exists". The fix is to stop assigning the number at all and let the database do it: SQL Server has an identity column for exactly this, and AL exposes it as a single field property.

## Requirements

The starter ships the table `"Sync Activity Log"` — `"Entry No."` of type `Integer` as the primary key, and `Message` of type `Text[250]` — and the codeunit `"Sync Activity Logger"` with an empty `Log`. Keep the object names, the field names and types, and the key: the tests read the table by name.

1. Set `AutoIncrement = true` on `"Entry No."`, so that a row inserted with the field at 0 comes back numbered by the database.
2. Implement the public procedure of the codeunit `"Sync Activity Logger"`:

```al
procedure Log(var ActivityLog: Record "Sync Activity Log"; MessageText: Text[250]): Integer
```

Rules:

- `Log` inserts one `"Sync Activity Log"` row whose `Message` is `MessageText`, stored in full (up to 250 characters), and returns the `"Entry No."` the database assigned. When the call returns, `ActivityLog` is positioned on the new row — same `"Entry No."`, same `Message` — because that is where the number is read from: the record variable, right after `Insert`.
- The number comes from the database, never from AL. `"Entry No."` must be 0 when you insert; a non-zero value is written as given and the numbering is skipped. Mind that `Init` does not clear primary-key fields: a variable still positioned on the previous entry carries that number into the next `Insert`, which then collides with the existing row ("already exists"). Set the field to 0 yourself, on every call.
- Numbers only ever go up. Called repeatedly, `Log` returns strictly increasing values, and a number that has been handed out once is never handed out again — not even after the row that carried it is deleted. Any scheme that computes "highest existing number plus one" in AL breaks this rule the moment the highest row is gone; the database's own numbering never does.
- The property does not work on temporary tables: the number stays 0 there. `Log` therefore accepts only a database record variable — called with a temporary `ActivityLog` it must refuse with an error whose message contains the phrase `must not be temporary` (note the exact spelling and casing), before writing anything to the buffer.

Worth knowing, not graded: a table can carry only one AutoIncrement field (a second one is compile error AL0746), the property is allowed only on `Integer` and `BigInteger` fields of a table object (never in a table extension), and a rolled-back transaction burns the number it was handed — gaps in the log are normal.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID. Captions are good practice but not graded.

## What the tests check

The grading tests first insert a `"Sync Activity Log"` row directly with `"Entry No."` at 0 and expect the record variable to hold a positive number afterwards — the property on its own, independent of your codeunit. Then they call `Log` with a generated message and expect a positive return value under which a row with that message can be fetched from the table; call `Log` and expect the passed record variable to sit on the new row (same `"Entry No."`, same `Message`); call `Log` three times with the **same** record variable and expect three strictly increasing numbers and three rows (an un-zeroed key dies here with "already exists"); insert a row directly, delete it, call `Log` with a fresh record variable and expect a number higher than the deleted one; round-trip a generated 250-character message; and pass a temporary record variable, expecting the error phrase above and a buffer that is still empty.

## Learn More

- [AutoIncrement property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoincrement-property) — the rules of the property: one per table, leave the field blank before Insert, deleted and rolled-back numbers are never reused, no temporary tables.
- [RecordRef.Insert() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-insert--method) — its remarks spell out what an insert does with a zero versus a non-zero AutoIncrement field; `Record.Insert` behaves the same way.
- [Record.Init() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method) — the note that primary-key fields are not initialized, which is why `"Entry No."` has to be zeroed by hand.
- [Record.IsTemporary() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-istemporary-method) — the one call that tells a database record variable from an in-memory buffer.
