# `\n` Is Not a Newline

Your extension builds the body of a notification e-mail from a list of lines, and later has to parse the same kind of text back — an address block pasted from the clipboard, a multi-line note submitted through a web form. The first version shipped with a bug report attached: "the e-mail is one long line with `\n` sprinkled through it". Whoever wrote it had `'\n'` from other languages in muscle memory. In AL that literal is two ordinary characters — a backslash and the letter n — and contains no line break at all.

## Requirements

Create a **codeunit** named `"Line Breaks"` with two public procedures:

```al
procedure JoinLines(Lines: List of [Text]): Text
procedure SplitLines(Body: Text): List of [Text]
```

Rules for `JoinLines`:

1. Consecutive lines are separated by CRLF: the character with code 13 (carriage return) immediately followed by the character with code 10 (line feed). That pair is the only thing between two lines — no space, no backslash, no other characters.
2. Nothing precedes the first line and nothing follows the last one: no trailing line ending.
3. An empty list joins to `''` (the empty text); a list with a single line joins to that line, unchanged.
4. An empty entry in the list is a blank line and still gets its separators: the list `head`, *empty*, `tail` joins to `head`, CRLF, CRLF, `tail`.
5. Line texts are copied unchanged — no trimming, no case changes.

Rules for `SplitLines`:

1. A line ends at LF (code 10) or at CRLF (code 13 immediately followed by code 10). Both styles may appear inside the same body.
2. The text between two line endings — even when it is empty — is a line, so a blank line comes back as an empty entry.
3. Text after the last line ending is the final line; a body containing no line ending at all is exactly one line.
4. An empty body (`''`) yields an empty list: zero entries, not one empty entry.
5. Returned lines never contain a CR or an LF character.
6. Only the real control characters end a line. The two-character sequence backslash followed by n is ordinary text: the body `C:\new\notes.txt` is one line.
7. Out of scope, so not graded: bodies that end with a line ending, a CR that is not immediately followed by an LF, and non-ASCII content.

Together these rules make the two procedures inverses of each other: splitting the text that `JoinLines` produced gives back the original list, blank lines included.

## How to produce the characters

A `Char` variable assigned the integer 13 holds a carriage return and one assigned 10 holds a line feed; `Format` turns a `Char` into a one-character `Text`, and a `Text` can be indexed to read a character back as a `Char`. The Base Application's `Type Helper` codeunit already wraps both control characters as `CRLFSeparator()` and `LFSeparator()`. `Text.Replace` and `Text.Split` are the natural tools for the split.

The dead end to avoid: the backslash in an AL text literal is not a general-purpose escape. `Message`, `Error`, `Confirm` and `Dialog.Open` do turn a `\` into a line break when they *display* a text, which is where the muscle memory comes from — but in an assignment `'\n'` has a `StrLen` of 2 and no line break, and `'\r\n'` is four ordinary characters. Text built that way looks right in a `Message` and wrong everywhere else.

## What the tests check

The join tests call `JoinLines` with lists of generated line texts and compare the whole result character for character against the expected text; one of them inspects the joined text of `a` and `b` position by position and expects exactly four characters with codes 13 and 10 in the middle. Further join tests cover lines with leading and trailing spaces, punctuation and mixed case (copied unchanged), a single line, an empty list, and a blank middle line. The split tests feed a CRLF-only body, an LF-only body, a body mixing both, a body with a blank middle line, a body with no line ending, an empty body, and the body `C:\new\notes.txt`, comparing the entire returned list — the count and every entry, in order. One test joins a list with a blank middle line and splits the result back, expecting the original list. Every comparison is exact, and failure messages render CR and LF as `<CR>` and `<LF>` so you can see what your code actually produced.

Pick object IDs in the house range 50100–50199 and reference other objects by name, never by ID.

## Learn More

- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type) — its "Escape sequences in text literals" section is the whole lesson: the backslash is interpreted by `Message` and friends, not by assignments.
- [Char data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type) — assigning a number to a `Char` gives you the character with that code.
- [Text.Split([Text,...]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-split-text-method) — splits a text on one or more separator texts.
- [Text.Replace(Text, Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-replace-method) — normalizes CRLF to LF before splitting.
