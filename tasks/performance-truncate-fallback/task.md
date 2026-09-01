# Wipe It Fast, Empty It Always

A marketplace connector fills the `Staging Entry` table by the hundred thousand every night, and after each processed import the cleanup job wipes it. The old cleanup deleted row by row and took minutes, so somebody switched it to the platform's one-stroke wipe — and now the nightly job dies: the platform can clear a whole table in one stroke, but not every table, and not in every state. Sometimes operations wants the entry numbering to start over from 1 for a clean reprocess, sometimes it must keep counting so old log references stay unambiguous. And the same cleaner is called with temporary buffers and on systems where other extensions hook into the table's delete events — it must never crash, and it must always leave zero rows behind.

## Requirements

Your submission is the shipped table plus one codeunit — keep the table `"Staging Entry"` exactly as given (the tests seed and read it by name, and the numbering rule below leans on its self-numbering `"Entry No."` column), keep all object IDs in the 50100–50199 range, and reference objects by name, never by ID.

Create a **codeunit** named `"Staging Cleaner"` with one public procedure:

```al
procedure ClearStaging(var StagingEntry: Record "Staging Entry"; ResetNumbering: Boolean)
```

Rules:

1. Every `Staging Entry` row inside the current filters on `StagingEntry` is removed; rows outside the filters survive completely untouched. An unfiltered call leaves the table empty.
2. With `ResetNumbering` = `false`, the numbering keeps counting: the next row inserted after the clear gets a number **above** the previous maximum. With `ResetNumbering` = `true`, the clear asks the platform to start the numbering over from 1 — which the platform only does where its one-stroke wipe is available (see rule 3); elsewhere the numbering keeps counting, and that is fine.
3. The procedure never raises an error. It may be handed a **temporary** instance of `Staging Entry`, run while another extension holds an **active subscriber to the table's delete events**, or run **inside a try function** — states in which the fastest way to clear a table is not available and the platform refuses it. The rows must still be removed, whichever way gets them removed.
4. Grading runs every test inside a try function, so the one-stroke wipe is refused in every graded call: the tests can only ever see your fallback path, and the numbering restart of rule 2 is therefore not graded. Use the fast wipe all the same — on the nightly job it is the difference between seconds and minutes — and make sure it never turns a refusal into a runtime error.

## What the tests check

The grading tests seed `Staging Entry` rows under `TRYAL-*` source codes, with row counts generated fresh every run. They assert that an unfiltered `ResetNumbering` = `true` clear leaves zero rows without an error; that after a `ResetNumbering` = `false` clear the table is empty and a fresh insert gets a number above the previous maximum; that a clear on a record filtered to one `"Source Code"` removes exactly the filtered rows and leaves the others untouched; that a temporary instance is emptied without a runtime error while a real row survives; and that a clear executed while the tests hold an active subscriber to the table's delete events still empties the table without an error. Every one of those calls runs inside the test runner's try function, so a cleaner that does not fall back when the fast wipe is refused fails all of them with a runtime error. Raw wall-clock speed is not measured — the never-crash contract and the numbering contract are what grade your choice of mechanism.

## Learn More

- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server) — what each write method costs on the wire, and when set-based deletes fall back to row-by-row.
- [AutoIncrement property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoincrement-property) — how the self-numbering column behaves, and why deleted numbers are normally never reused.
- [Record.DeleteAll method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-deleteall-method) — the row-by-row wipe that works on any writable table.
- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — every way of removing rows side by side, including when each one is and is not available.
