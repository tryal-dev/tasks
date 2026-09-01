# Base64 In, Base64 Out

Your company archives scanned delivery notes with an external document service. Its REST API is strict about payloads: outgoing file bytes travel as a Base64 string inside a JSON field, and every response carries a Base64 string you must turn back into the original bytes. One stray line break — or one wrong padding character — and the archive rejects the request. You are building the codec that both directions run through; the HTTP plumbing is out of scope.

## Requirements

Create a **codeunit** named `"Base64 Document Codec"` with two public procedures:

```al
procedure EncodeDocument(var TempBlob: Codeunit "Temp Blob"): Text
procedure DecodeDocument(Base64Payload: Text; var TempBlob: Codeunit "Temp Blob")
```

Rules:

1. `EncodeDocument` returns the standard Base64 encoding of the bytes stored in `TempBlob`, as a single line — no CR or LF characters anywhere, with `=` padding exactly where Base64 requires it.
2. `DecodeDocument` writes the bytes encoded in `Base64Payload` into `TempBlob` — byte-perfect, so decoding what `EncodeDocument` produced reproduces the original document exactly, byte count included.
3. An empty document encodes to an empty string, and decoding an empty payload leaves the document empty (zero bytes).

## What the tests check

The grading tests write known ASCII content into a `"Temp Blob"` and compare your Base64 output character for character (the one-, two- and three-byte documents `M`, `Ma` and `Man` must become exactly `TQ==`, `TWE=` and `TWFu` — the three padding shapes). They decode known payloads and verify both the content and the exact byte count, check that a 300-byte document encodes to exactly 400 characters containing no CR or LF, and round-trip a randomly generated document through encode then decode expecting byte-for-byte equality. They also feed the codec raw binary bytes that are not valid text in both directions and expect the exact Base64 payload and the exact byte count back, and cover the empty-document and empty-payload cases.

## Learn More

- [Base64 Convert codeunit (System Application)](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.text.base64-convert)
- [Temp Blob codeunit (System Application)](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.temp-blob)
- [Using streams in Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-streams-overview)
- [InStream data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type)
- [OutStream data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type)
