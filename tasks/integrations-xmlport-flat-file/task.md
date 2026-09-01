# Fixed-Width File, the Platform Way

The bank that handles your customer's supplier payments has never heard of XML. It wants a fixed-width text file — every column at a byte offset printed in a PDF from 1998 — and it answers with a semicolon-separated return file listing what it booked and what it bounced. This is still how most bank, payroll and government interfaces work, and Business Central has carried a purpose-built object for it since forever: the same one you use for XML, switched into text mode.

Two tables come with the starter and are already finished — `"Payment Batch Line"` (fields `"Line No."`, `"Recipient No."`, `"Recipient Name"`, `Amount`, `"Due Date"`) and `"Bank Return Line"` (fields `"Reference No."`, `"Payer Name"`, `"Amount (Cents)"`, `"Status Code"`, `"Bank Message"`). Keep their names and fields exactly as they are; the grading tests read and write them.

## Requirements

Create two **XMLport** objects. The tests invoke them with `Xmlport.Export` and `Xmlport.Import`, so their names must match character for character.

### 1. `"Payment Batch Export"` — the payment file

The tests call `Xmlport.Export` on a stream with no record parameter, so the XMLport exports **every** `"Payment Batch Line"` record in the table, in ascending `"Line No."` order.

One payment record per payment line, 63 characters wide:

| Columns | Width | Content |
|---|---|---|
| 1–3 | 3 | the literal `PMT` |
| 4–13 | 10 | `"Recipient No."`, filled up on the right with spaces |
| 14–43 | 30 | `"Recipient Name"`, filled up on the right with spaces |
| 44–55 | 12 | `Amount` in cents — the amount times 100, rounded to a whole number — digits only, filled up on the left with zeros |
| 56–63 | 8 | `"Due Date"` as `yyyymmdd`: four-digit year, two-digit month, two-digit day, nothing between them |

Then exactly one trailer record, after all payment records, 21 characters wide:

| Columns | Width | Content |
|---|---|---|
| 1–3 | 3 | the literal `TRL` |
| 4–9 | 6 | how many payment records the file holds, filled up on the left with zeros |
| 10–21 | 12 | the sum of all payment amounts in cents, filled up on the left with zeros |

Rules:

1. The trailer is written even when there is not a single payment line — then it reports a count of `000000` and a total of `000000000000`.
2. The field lengths of `"Payment Batch Line"` are exactly the column widths, so no value ever has to be truncated. Graded amounts are never negative and never carry more than two decimals.
3. The amount and the date columns must come out the same in any language — a session running in another locale must not turn `1234.56` into `1.234,56` or the date into `03/07/26`.

### 2. `"Bank Return Import"` — the return file

The tests call `Xmlport.Import` on a stream holding a return file, and the XMLport inserts one new `"Bank Return Line"` per line of it. `"Reference No."` is the primary key of that table, and the file supplies it.

The return file is a text file with one record per line and five columns separated by a semicolon (`;`), in this order:

1. reference no. → `"Reference No."` — up to 20 characters, written with leading zeros in some files, and those zeros are part of the value.
2. payer name → `"Payer Name"`.
3. amount in cents → `"Amount (Cents)"` — a whole number, padded with leading zeros to ten digits: `0000012345` means 12345 cents.
4. status code → `"Status Code"` — for example `ACCP` or `RJCT`.
5. bank message → `"Bank Message"` — sometimes empty, so the line ends right after its last semicolon.

Rules:

1. A value may be wrapped in double quotes (`"`). The quotes are then **not** part of the value, and a semicolon inside them is data, not a column break: `"Meyer; Sons GmbH"` is one payer name.
2. The file is UTF-8, and payer names carry non-ASCII characters (`Zürich Süd AG`) that must survive the import unchanged.
3. The graded files have no header line and no line break after the last record.

Not graded: captions, and whether the XMLports offer a request page.

Pick object IDs in the house range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

For the export the tests seed `"Payment Batch Line"` records, run `Xmlport.Export` into a stream, drop blank lines and any trailing line break, and then compare the remaining records **character for character** — so a column one space too wide, a missing leading zero or a swapped column order fails. The records are compared as plain single-byte characters, and a UTF-8 byte order mark at the start of the file is ignored. There are separate tests for the fixed positions of all five columns of a payment record, for short values being filled up to their full column width, for the cents and the `yyyymmdd` date columns, for three payment lines coming out in `"Line No."` order, for the trailer's count and total, and for an empty batch exporting the trailer alone. Amounts and recipient names are randomly generated in several tests, so a hardcoded line will not pass. For the import the tests feed one return file per test through `Xmlport.Import` and then read the created `"Bank Return Line"` records: a three-line file must create three records; a reference of `0000004217` must be stored with its leading zeros; a zero-padded amount column must arrive as the number it spells out; a quoted payer name containing a semicolon must arrive as one value without its quotes and with the columns after it still in place; a `ü` must come back as a `ü`; the bank message of a rejected line must arrive in `"Bank Message"`; and a column with nothing between its separators must arrive empty.

## Learn More

- [XMLport overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-overview) — what the object is made of, and the two properties you always set first.
- [Defining an XMLport schema](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-schema) — the node types (`textelement`, `tableelement`, `fieldelement`) and how they nest.
- [Xmlport.Export(Integer, var OutStream [, var Record]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-export-method) — exactly how the tests run your export port.
- [Xmlport.Import(Integer, var InStream [, var Record]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-import-method) — and your import port.
