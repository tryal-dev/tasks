# Buffer-Only API

An import wizard builds up staging lines in memory, lets the user preview them, and only writes anything once the user confirms. The staging API underneath must therefore work purely on an in-memory buffer — and a colleague who accidentally passes a real record variable into it must hit a clear error, not silently fill the physical staging table on every preview click.

## Requirements

The starter ships a table `"Import Staging Line"` (primary key `"Line No."` of type `Integer`, plus `"Item Code"` of type `Code[20]`, `Quantity` of type `Decimal`, and `Processed` of type `Boolean`). Keep it exactly as given — the tests read it by name.

Implement the **codeunit** named `"Staging Buffer"` with two public procedures:

```al
procedure AddLine(var StagingLine: Record "Import Staging Line"; ItemCode: Code[20]; Quantity: Decimal)
procedure ProcessBuffer(var StagingLine: Record "Import Staging Line"): Decimal
```

Rules:

1. Both procedures accept only a temporary record variable. Called with a record variable that is not temporary, each must refuse the call with an error message that contains the phrase `must be temporary` (note the exact spelling and casing).
2. `AddLine` appends one row to the buffer: `"Line No."` is the highest line number already in the buffer plus one (1 when the buffer is empty), `"Item Code"` and `Quantity` come from the parameters, and `Processed` starts as `false`.
3. `ProcessBuffer` visits every row in the buffer, sets `Processed` to `true` on each, and returns the sum of `Quantity` over those rows. An empty buffer is not an error: it simply returns 0.
4. Neither procedure may ever write to the physical `Import Staging Line` table — every row lives and dies in the caller's in-memory buffer.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The tests call both procedures with a temporary record variable and with a plain database record variable. The refusal path uses `asserterror` and checks for the phrase from rule 1 in the error message. The happy path checks the numbering of rule 2 (a first line, and a line added to a buffer already holding lines 2 and 5 — the highest line number counts no matter which row the record variable is positioned on), the stored field values for generated inputs, the `Processed` flags and the returned total after processing, zero for an empty buffer — and, after each successful call, that the physical `Import Staging Line` table holds no rows at all.

## Learn More

- [Temporary tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables) — how a record variable can hold rows in memory only, and why buffers are built that way.
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling) — the strategies and methods for raising and handling errors in AL.
- [Progress Windows, Message, Error, and Confirm Methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-progress-windows-message-error-and-confirm-methods) — the `Error` method that stops execution with a message.
