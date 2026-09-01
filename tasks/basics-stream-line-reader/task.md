# Read Lines, Not Bytes

Your extension imports text files that customers upload — a payment file from one bank, a product list exported from another system. Depending on which machine produced the file, lines end in CRLF (Windows) or LF (Unix), sometimes both styles inside the same file, and the last line often has no line ending at all. The import logic downstream needs the logical lines, exactly as a text editor would show them — including the blank ones.

## Requirements

Create a **codeunit** named `"Stream Line Reader"` with one public procedure:

```al
procedure ReadLines(LineStream: InStream): List of [Text]
```

Rules:

1. A line ends at LF (character 10) or at CRLF (character 13 immediately followed by character 10). Both styles can occur in the same stream.
2. Every line ending closes exactly one line, and the text before it — even when that text is empty — is that line. A blank line in the payload must appear in the list as an empty text entry, and several blank lines in a row produce that many empty entries.
3. If the stream does not end with a line ending, whatever follows the last line ending is still a line — the final entry of the list.
4. If the stream does end with a line ending, that ending closes the last line and nothing more: no extra empty entry at the end.
5. A stream with no content at all yields an empty list.
6. Returned lines never contain CR or LF characters. In the graded payloads CR appears only immediately before LF, never on its own, and all content is plain ASCII text.

A word of warning before you reach for `ReadText`: its documented stop conditions are a zero byte, an end of line, the requested number of bytes, or the maximum string length — and it never tells you *which* of them ended the read. Inside the obvious `while not LineStream.EOS() do LineStream.ReadText(Line)` loop you cannot tell a blank line from the end of the stream, nor whether the final line had a line ending — and the grading payloads target exactly those cases. `InStream.Read` also has overloads that read a single byte at a time; at that level, CR and LF are just the values 13 and 10.

## What the tests check

Each test writes one payload into a temporary blob, opens an `InStream` on it, calls `ReadLines` once, and compares the entire returned list — the count and every entry, in order — against the expected lines. The payloads cover: CRLF-only, LF-only, and mixed line endings; a single blank line and consecutive blank lines; a payload ending with a line ending; a payload whose final line has no line ending; a payload that is nothing but a single LF (expected result: one empty line); and an empty stream (expected result: an empty list). One payload's lines contain leading and trailing spaces, digits, punctuation, and mixed case — the comparison is exact, so trimming, lowercasing, or otherwise normalizing line content will fail. Some line texts are randomly generated, so returning hardcoded lines will not pass.

Pick object IDs in the house range 50100–50199 and reference other objects by name, never by ID.

## Learn More

- [Write, WriteText, Read, and ReadText method behavior for line endings and zero terminators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-write-read-methods-line-break-behavior) — the documented semantics this task is built around.
- [InStream.ReadText method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-readtext-method) — read its Remarks and you will see the trap.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the return type and its `Add`/`Count`/`Get` methods.
- [TextBuilder data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type) — the efficient way to accumulate a line character by character.
