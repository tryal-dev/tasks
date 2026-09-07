# Bigger Than 2048

The warehouse wants free-form delivery instructions on every shipment note: gate codes, "ring twice and wait", three paragraphs of directions pasted from the customer portal. The first attempt added a `Text[2048]` field and lasted a week — the longer instructions did not fit, and the umlaut in `Zürich` came back as a question mark. In AL a `Text` field tops out at 2,048 characters; text of any length lives in a **Blob**. A Blob behaves unlike every other field: it does not travel with the row on `Get` or `Find` but is fetched on request, and it is read and written through streams that carry a text encoding — whose default is not the one you want.

## What you are given

The starter ships table `"Shipment Note"` — submit it unchanged: `"No."` (`Code[20]`, primary key), `"Ship-to Name"` (`Text[100]`) and `"Delivery Instructions"` (`Blob`). It also ships codeunit `"Shipment Instructions"` with three empty procedures — keep the names and these exact signatures:

```al
procedure SetInstructions(NoteNo: Code[20]; Instructions: Text)
procedure GetInstructions(NoteNo: Code[20]): Text
procedure HasInstructions(NoteNo: Code[20]): Boolean
```

## Requirements

1. `SetInstructions` stores `Instructions` in the `"Delivery Instructions"` Blob of the note whose `"No."` is `NoteNo`, encoded as UTF-8, and saves the record — afterwards any other record variable that reads the table finds the text there. Only the Blob changes: the note's other fields, `"Ship-to Name"` included, are left exactly as they were.
2. A later `SetInstructions` on the same note replaces the earlier text entirely — nothing of the old text remains, however much longer it was.
3. An empty `Instructions` removes the stored text: afterwards `HasInstructions` returns `false` and `GetInstructions` returns the empty text.
4. `GetInstructions` returns exactly the text that was stored, decoded as UTF-8 — every character and every line break, CRLF and bare LF alike, with nothing trimmed and no line ending added at the end. For a note that holds no instructions it returns the empty text.
5. `HasInstructions` returns `true` when the note holds instructions and `false` when it holds none.
6. The texts are long — 5,000 characters in one test, well beyond any `Text` field — and contain characters from outside ASCII such as `Zürich — O'Brien`. Every comparison is character for character.
7. Every `NoteNo` the tests pass belongs to an existing note; what happens for an unknown number is not graded.

## Where the naive version goes wrong

Three mistakes fail silently — no error, just wrong data — so know them before you start:

- A record fetched with `Get` carries an **empty** Blob. `CalcFields` on the Blob field fetches its content; without it `HasValue` is `false` and a stream over the field reads nothing. This applies to `GetInstructions` and `HasInstructions` alike.
- `CreateOutStream` and `CreateInStream` on a Blob take an optional `TextEncoding`, and their default is `MSDos` — an OEM code page with no room for an em dash, a `ł` or a `€`. The tests write and read the Blob as `TextEncoding::UTF8`, so your streams must use it on both the write side and the read side.
- `InStream.ReadText` stops at the first line ending, so a three-line text comes back as one line. `InStream.Read` into a `Text` variable reads until a zero byte or the end of the stream — and `OutStream.WriteText` writes no zero byte, so that pair returns the text whole.

Two more things the row never does for you: writing into the stream changes only your record variable — the table sees nothing until `Modify` — and clearing a Blob is `Clear` on the field followed by `Modify`, not a stream with nothing written to it. And fetch the row with `Get` before you write to it: a record variable that only had its `"No."` assigned still `Modify`s without complaint, and saves blanks into every other field of the note.

Pick object IDs in the house range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The tests create `"Shipment Note"` rows and grade each procedure against the table itself, not only against its sibling: one test stores a generated 5,000-character text through `SetInstructions` and reads the Blob straight from the table (with `CalcFields` and a UTF-8 stream); another calls `SetInstructions` and then checks that the note's `"Ship-to Name"` still holds the value it was created with; another writes a 3,000-character text straight into the Blob and expects `GetInstructions` to return it. `Zürich — O'Brien & Søn, Łódź (€25 COD)` is checked in both directions the same way, so an MSDos stream on either side fails. A text with CRLF breaks, an empty line and a bare LF must round-trip through `SetInstructions` and `GetInstructions` unchanged; a second `SetInstructions` with a shorter text must leave only the shorter text; an empty text must clear the note; and `HasInstructions` is checked against a Blob the test filled directly, against a bare note, and after clearing. Failure messages report both lengths and a window around the first differing character, with CR and LF shown as `<CR>` and `<LF>`.

## Learn More

- [Blob data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-data-type) — the field type for text of any length, and the stream methods that read and write it.
- [Blob.CreateOutStream method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-createoutstream-method) — the optional encoding argument and its MSDos default; `CreateInStream` mirrors it.
- [Record.CalcFields method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method) — also the way to retrieve a Blob's content into a record variable.
- [Write, WriteText, Read, and ReadText method behavior for line endings and zero terminators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-write-read-methods-line-break-behavior) — which read method stops where, with a worked Blob example.
