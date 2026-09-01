# Zip In, Zip Out

Your company exchanges document batches with a logistics partner. Outgoing batches leave as one zip archive whose entries keep a folder structure the partner's system relies on. Incoming payloads are less disciplined: the same document sometimes arrives inside a one-file zip, sometimes as a gzip stream, and sometimes as bare text — your code has to look at the bytes and route accordingly. Everything happens in memory; no files ever touch a disk.

## Requirements

Create a **codeunit** named `"Zip Archive Manager"` with four public procedures:

```al
procedure BuildArchive(Documents: Dictionary of [Text, Text]; var ArchiveBlob: Codeunit "Temp Blob")
procedure ListEntries(var ArchiveBlob: Codeunit "Temp Blob"): List of [Text]
procedure ExtractDocument(var ArchiveBlob: Codeunit "Temp Blob"; EntryPath: Text; var DocumentBlob: Codeunit "Temp Blob"): Integer
procedure GetDocumentText(var PayloadBlob: Codeunit "Temp Blob"): Text
```

Rules:

1. `BuildArchive` writes a zip archive into `ArchiveBlob` with exactly one entry per `Documents` pair: the key is the entry's full path inside the archive and the value is that entry's content, written as UTF-8 text.
2. Entry paths may contain `/` folder separators (for example `invoices/2026/INV-1001.txt`) and must be stored in the archive character for character.
3. An empty `Documents` dictionary still produces a valid zip archive — one with zero entries.
4. `ListEntries` returns the full entry paths of the zip archive stored in `ArchiveBlob` — any zip handed to you, not just one your `BuildArchive` made — in archive order (the order the entries were added).
5. `ExtractDocument` writes the uncompressed bytes of the entry at `EntryPath` into `DocumentBlob` and returns the exact uncompressed byte count. Extraction must be byte-perfect: entries can hold raw binary bytes that are not valid text, and they must survive untouched.
6. `GetDocumentText` detects the payload's shape from its bytes and returns the document text: a zip archive holds exactly one document — return that document's text; a gzip-compressed payload — return the decompressed text; anything else is already plain UTF-8 text — return it unchanged.
7. Document contents in this task are single-line UTF-8 text (no CR or LF); only `ExtractDocument` must additionally cope with raw binary entries.

Pick your object IDs in the range 50100–50199, and reference other objects by name — never by numeric ID.

## What the tests check

The grading tests unpack your archives with their own independent zip reader and hand you archives you didn't build: they verify that a built archive is recognized as a genuine zip, holds exactly the given entry paths (folder separators and all — the paths must match character for character), and round-trips every document's content — one document and one plain-text payload contain non-ASCII characters (for example `ü`, `€`), so the UTF-8 promise is graded, not just ASCII; that an empty dictionary yields a zero-entry archive; that `ListEntries` reports a foreign archive's full paths in archive order; that `ExtractDocument` reproduces a named entry's content and returns the exact byte count — including a 4-byte binary entry that is not valid text; and that `GetDocumentText` returns the same text whether the payload arrives as a one-document zip, a gzip stream, or bare UTF-8 text. Several document contents are randomly generated, so pattern-matching the examples won't pass.

## Learn More

- [Using streams in Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-streams-overview) — how InStream/OutStream move bytes between in-memory data sources, the backbone of every procedure here.
- [Temp Blob codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.temp-blob) — the in-memory byte container every signature above passes around, and the streams it hands out.
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — iterating the path→content pairs `BuildArchive` receives.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — building the ordered entry-path list `ListEntries` returns.
