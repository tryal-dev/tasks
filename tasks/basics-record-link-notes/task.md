# Customer Notes via Record Links

Every card in Business Central carries an Attachments FactBox where users scribble notes and pin web links — on customers, items, documents, anything. Under the hood they all land in one system table, `"Record Link"`: one row per note or link, attached to its owner through the `"Record ID"` field and keyed by an auto-incrementing `"Link ID"`. Your team wants a small, safe API around that table for customers.

There is a catch that trips almost everyone: **the note text is not stored as plain text**. The `Note` BLOB starts with a binary length header, and everything that reads notes — the FactBox, the base app, the grading tests — expects exactly that format. Writing the text into the BLOB with a bare `OutStream` produces a note your own code can read back, but nothing else can. Codeunit `"Record Link Management"` owns the format: its `WriteNote` and `ReadNote` procedures are the only safe way in and out of the `Note` BLOB.

## Requirements

Create a **codeunit** named `"Record Note Manager"` with five public procedures:

```al
procedure AddNote(Customer: Record Customer; NoteText: Text): BigInteger
procedure ReadNote(LinkID: BigInteger): Text
procedure CountNotes(Customer: Record Customer): Integer
procedure CopyLinks(FromCustomer: Record Customer; ToCustomer: Record Customer)
procedure DeleteDanglingLinks()
```

Rules:

1. `AddNote` inserts one `"Record Link"` row attached to the customer via `"Record ID"`, with `Type` = `Note` and `NoteText` stored in the `Note` BLOB in the standard format, and returns the `"Link ID"` the platform assigned to the new row.
2. `ReadNote` returns the decoded note text of the link with that `"Link ID"`, or an empty text when no such link exists — it never raises an error. Remember that `Get` does not load BLOB fields.
3. `CountNotes` returns how many links of type `Note` the customer has. The customer's web links (`Type` = `Link`) and other records' notes must not count.
4. `CopyLinks` gives the target customer its own copy of every record link of the source — notes and web links alike, note text preserved — and leaves the source's links untouched.
5. `DeleteDanglingLinks` deletes every record link whose `"Record ID"` points to a record that no longer exists. Only links whose `Company` is empty or equal to the current company are candidates — links stamped with another company's name must be left alone.
6. Dead-end warning: the base app ships `RemoveOrphanedLinks` in the same `"Record Link Management"` codeunit, but it raises a confirmation dialog and a message — under grading, any unhandled dialog fails the test. Write the sweep yourself against the `"Record Link"` table, checking record existence with a `RecordRef`.

Pick your codeunit's object ID in the 50100–50199 range and reference every other object by name, never by ID.

## What the tests check

The tests use the standard `WriteNote`/`ReadNote` of codeunit `"Record Link Management"` as an independent oracle: notes written by your `AddNote` are read back with the standard reader, and notes written by the standard writer are handed to your `ReadNote` — so a private, symmetric encoding of your own passes your desk test but fails grading. Round-trips include special characters (`Zürich`, `O'Brien`, `—`) and freshly generated text. The tests also assert exact link counts (a freshly generated number of notes vs. web links, per customer), that copied links land on the target while the source keeps its own readable rows, that `ReadNote` returns an empty text for an unknown `"Link ID"`, and that after `DeleteDanglingLinks` the rows of deleted records are gone — customers and other tables such as items alike, so a customer-only sweep fails — while a live customer's note and a foreign-company row both survive.

## Learn More

- [Record.AddLink Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-addlink-method) — how the platform itself files web links into the `"Record Link"` system table.
- [Record.CopyLinks Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copylinks-table-method) — copies all links from one record to another, note BLOBs included.
- [Record.CalcFields Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method) — BLOB fields must be calculated before you can read them.
- [RecordRef.Get Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-get-method) — checks whether the record behind a `RecordId` still exists.
