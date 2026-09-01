# A File Name the OS Accepts

Your extension attaches PDF exports to customer records, and the file is named after whatever the user typed: the document number, the customer name, sometimes a whole subject line. Every few days one of those names carries a `/` or a `:` — and the export dies, because Windows refuses nine characters in a file name: `\ / : * ? " < > |`. On top of that, a name with a trailing dot or space is silently changed by the file system, and a 300-character subject line does not fit at all.

Write the one procedure that turns any proposed name into a file name the operating system accepts — every time, deterministically.

## Requirements

Create a **codeunit** named `"Safe File Name"` with a public procedure:

```al
procedure ToSafeFileName(Proposed: Text; Extension: Text; MaxLength: Integer): Text
```

The result is the cleaned **stem** (the name without extension), a single dot, and `Extension`. Clean the stem in this order:

1. **Illegal characters.** Replace each of the nine characters `\ / : * ? " < > |` with one underscore `_` — one underscore per character, so `a/b` becomes `a_b` and a name made of nothing but the nine illegal characters becomes nine underscores (not `document`).
2. **Whitespace.** A tab (character 9) counts as a space. Every run of two or more consecutive spaces or tabs collapses to a single space.
3. **Edges.** Remove every leading and every trailing space and dot from the stem — any number of them, in any mix: `' ..v1.2 notes . '` becomes `v1.2 notes`. Dots and spaces inside the stem stay where they are.
4. **Empty stem.** If nothing is left after steps 1-3 (the input was empty, or only spaces, tabs and dots), the stem is `document`.
5. **Length.** Append `.` + `Extension`. If the whole result is longer than `MaxLength` characters, cut the stem from the end so that the complete file name — stem, dot and extension — is exactly `MaxLength` characters long. The extension always survives intact; the length is measured **after** cleaning, so leading spaces you removed never count against it.

Everything else passes through untouched: letters of any alphabet (`Müller`, `Straße`, `日本語`), digits, upper- and lowercase, and characters such as `&`, `-`, `(`, `)`, `'` and `,` that the operating system allows.

You can rely on these guarantees about the input: `Extension` is never empty, never contains a dot and contains only letters and digits; `MaxLength` is always at least the length of the extension plus two; `Proposed` contains no control characters other than tabs; and the tests never cut a stem at a position where a space or a dot would end up trailing, so whether you trim again after cutting is your call (not graded).

The built-in `Text` methods do nearly all of this. `ConvertStr` maps characters one-to-one — its two character lists must be the same length or it raises a runtime error. `DelChr` removes characters at the start (`<`), at the end (`>`) or everywhere (`=`): the *Where* argument names positions, and the *Which* argument is a **set** of characters (not a literal string), so one call strips spaces and dots from both ends. Watch out for a plausible dead end: `Text.Trim()` removes whitespace only, never dots.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

| `Proposed` | `Extension` | `MaxLength` | Result |
|---|---|---|---|
| `Invoice 1001/2026: Müller & Co` | `pdf` | 100 | `Invoice 1001_2026_ Müller & Co.pdf` |
| ` ..v1.2 notes . ` | `md` | 100 | `v1.2 notes.md` |
| `` (empty) | `pdf` | 100 | `document.pdf` |
| 300 letters | `pdf` | 100 | the first 96 letters + `.pdf` |

## What the tests check

The grading tests call `ToSafeFileName` and compare the returned text **character for character**: the `Invoice 1001/2026: Müller & Co` example, a name containing all nine illegal characters (each must become one underscore), a name made of nothing but illegal characters (nine underscores), non-ASCII letters that must survive unchanged, tabs and runs of spaces inside the name, leading and trailing spaces and dots in a mix, an empty name and a name of only spaces, tabs and dots (both `document`), a 300-character stem cut so that the whole name is exactly `MaxLength` long with the extension intact, a name already exactly at `MaxLength` (untouched), a name one character over it (one character cut), and a padded name whose *cleaned* stem fits exactly (so cutting before cleaning fails). Several tests build their stems from generated letters, so returning a constant or matching the examples passes nothing.

## Learn More

- [Text.ConvertStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-convertstr-method) — one-to-one character mapping, and why the two character lists must be the same length.
- [Text.DelChr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-delchr-method) — the `Where` positions (`<`, `>`, `=`) and the `Which` character set.
- [Text.CopyStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method) — cutting the stem down to a length without an overflow error.
- [Text.Replace method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-replace-method) — replacing a substring such as two spaces with one.
