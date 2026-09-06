# Last Segment, One-Based

A document-import job hands your extension full file paths straight from the customers' servers: `C:\Exports\2026\invoice-1001.pdf` from a Windows share one minute, `/exports/2026/invoice-1001.pdf` from a Linux one the next, and every now and then a path that ends in a separator because someone pointed the job at a folder instead of a file. To fill the attachment's file name and file extension you need the last segment of the path and the extension of that segment — nothing else.

## Requirements

Create a **codeunit** named `"Path Helper"` with two public procedures:

```al
procedure FileNameOf(Path: Text): Text
procedure ExtensionOf(Path: Text): Text
```

Rules:

1. `FileNameOf` returns everything after the **last** separator in `Path`. Both `/` and `\` are separators, and one path may mix them. A path with no separator at all is a bare file name — return it unchanged.
2. When `Path` ends with a separator there is no file name: return an empty text.
3. `ExtensionOf` returns the part of the **file name** (what rule 1 returns) after its last dot, without the dot: `backup.2026-03-01.tar.gz` has the extension `gz`. Return it exactly as written in the path — no case change, no trimming.
4. A file name without a dot has no extension: return an empty text. A dot in a folder name does not count — `/archive.2025/notes` has no extension — and neither does a path that ends with a separator.

You can rely on these guarantees about the input: `Path` is never empty and never consists of separators only; the file name never starts or ends with a dot; there is no whitespace around the segments.

The `Text` and `List` types do the work. `Text.Split` takes any number of separators and returns a `List of [Text]` with one element per segment — and when the text ends with a separator, its last element is an empty text, which is exactly what rule 2 needs. AL lists are **1-based**: the first element sits at index 1 and the last at `Count()`. `List.Get` raises a runtime error for any index outside that range, so index 0 is never "the first element" — it is a crash. `Text.LastIndexOf` follows the same convention: it returns the **1-based** position of the last match and **0 when there is no match** — never -1 as in most other languages — so a check for a negative result never fires, and treating 0 as a position slices from the start of the text. `Text.Substring` is 1-based too. The starter is wrong in exactly these two places; each is marked with a `// TODO:` comment.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

| `Path` | `FileNameOf` | `ExtensionOf` |
|---|---|---|
| `/exports/2026/invoice-1001.pdf` | `invoice-1001.pdf` | `pdf` |
| `C:\Users\Anna\Documents\report.xlsx` | `report.xlsx` | `xlsx` |
| `/exports/2026/` | (empty) | (empty) |
| `/archive.2025/notes` | `notes` | (empty) |
| `backup.2026-03-01.tar.gz` | `backup.2026-03-01.tar.gz` | `gz` |

## What the tests check

The grading tests call both procedures and compare the returned text **character for character**: a forward-slash path and a backslash path, a path mixing both separators, a trailing `/` and a trailing `\` (both give an empty file name), a bare file name with no separator, an extension after the last of several dots, a file name without a dot, a path whose only dot sits in a folder name, a trailing separator asked for its extension, and an uppercase extension that must come back uppercase. Several file names and extensions are generated at run time, so returning a constant or matching the examples passes nothing. No test passes an empty path.

## Learn More

- [Text.Split([Text,...]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-split-text-method) — one call, several separators, a `List of [Text]` back.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the instance methods, and the one line that says lists are 1-based.
- [Text.LastIndexOf method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-lastindexof-method) — the 1-based position of the last match, and what 0 means.
- [Text.Substring method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-substring-method) — slicing from a 1-based position to the end.
