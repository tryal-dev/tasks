# Rename Follows the Relation

Finance is renumbering customers next month: every `Customer` moves from the old five-digit numbers to a new scheme, one `Rename` at a time. Your team keeps a small `"Customer Note"` table, and the question on the table is whether the notes will follow their customers or be orphaned under numbers that no longer exist.

The documentation for the OnRename trigger says that when you rename a record in one location, "it is updated in all other locations". That sentence hides a condition: the platform only knows a field is a *location* of the customer number when the field declares a `TableRelation` to the `Customer` table. A `Code[20]` that merely happens to contain a customer number is text as far as the rename is concerned, and it stays exactly as it was written.

Your table needs one field of each kind. `"Customer No."` is the live reference and must move with the customer. `"Legacy Customer No."` is the number the note was filed under when it was written, kept so the notes can be reconciled with the old system, and it must never change, rename or not.

## Requirements

The starter contains the table with all four fields and the codeunit with both procedure shells. Keep every name and signature.

A **table** named `"Customer Note"`:

| Field | Type | Notes |
|---|---|---|
| `"Entry No."` | `Integer` | primary key, assigned by the platform (`AutoIncrement`) |
| `"Customer No."` | `Code[20]` | the live reference: declare a table relation to `Customer` |
| `"Legacy Customer No."` | `Code[20]` | the snapshot: **no** table relation |
| `Note` | `Text[250]` | |

A **codeunit** named `"Customer Notes"` with two public procedures:

```al
procedure AddNote(CustomerNo: Code[20]; NoteText: Text[250])
procedure NotesFor(CustomerNo: Code[20]): Integer
```

Rules:

1. `"Customer No."` declares a table relation to the `Customer` table. That single property is what gives the field its lookup, its validation, and the behaviour this task is about: when a customer is renamed, the platform rewrites this field on every note that pointed at the old number.
2. `"Legacy Customer No."` declares no table relation at all. It is a plain `Code[20]`, so a rename never touches it. Adding a relation here would make the rename overwrite the very number the field exists to preserve.
3. `AddNote` inserts exactly one `"Customer Note"` row. `"Customer No."` is validated against its relation, so a number that no customer carries is refused by the relation check itself (the error text contains `cannot be found in the related table`). `"Legacy Customer No."` receives the same number as passed, and `Note` is stored exactly as passed. A customer can carry any number of notes.
4. `NotesFor` returns how many `"Customer Note"` rows have `"Customer No."` equal to `CustomerNo`. It goes by that field alone; the legacy number plays no part in the count. A customer without notes counts 0, whatever notes other customers have.
5. The behaviour you are building towards, with no code of your own: after `Customer.Rename(NewNo)`, `NotesFor(NewNo)` returns every note that was filed under the old number, `NotesFor(OldNo)` returns 0, each of those rows reads the new number in `"Customer No."`, and still reads the old number in `"Legacy Customer No."`. Notes of other customers are untouched. There is no rename trigger, event subscriber or `ModifyAll` to write; if you find yourself writing one, the relation is missing.

Pick object IDs in the range **50100–50199**, and reference other objects **by name, never by ID**. Captions are good practice but not graded.

## What the tests check

The grading tests create customers through the standard test library, add notes with generated texts, and read the rows back by text. They check that each `AddNote` call inserts exactly one row with that text, storing the customer number in both fields and the text as passed, that a generated number no customer carries is refused with the relation's `cannot be found in the related table` error, that `NotesFor` counts a random number of notes for one customer and exactly one for another, and 0 for a customer without notes while another customer has one. The rename tests add notes, confirm `NotesFor` finds them under the current number, then call `Customer.Rename` with a generated `TRYAL-…` number and expect `NotesFor` to find all of them under the new number and none under the old one, the row's `"Customer No."` to read the new number and its `"Legacy Customer No."` to still read the old one, and a second customer's note to be untouched. Two tests read the field declarations through a `FieldRef`: `"Customer No."` must relate to the `Customer` table, and `"Legacy Customer No."` must relate to no table at all.

## Learn More

- [OnRename (Table) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/table/devenv-onrename-table-trigger) — the sentence this task is about: a renamed record "is updated in all other locations".
- [Record.Rename method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method) — what a primary-key rename does, including updating the key "in all related tables".
- [TableRelation property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property) — the property that turns a Code field into a reference the platform understands.
- [Setting relationships between tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-set-relationships-between-tables) — the three things a relation buys you: validation, lookups, and propagating changes from one table to another.
