# Copy Text Safely into Code Fields

An import routine receives item identifiers from an external system as free text. Your teammate wired it straight into a `Code[20]` — and the import now dies with *"The length of the string is 27, but it must be less than or equal to 20 characters."* This is one of AL's classic runtime errors: assigning oversized `Text` to a `Code` field doesn't truncate; it crashes.

The starter code reproduces that bug. Fix it.

## Requirements

Create a **codeunit** named `"Code Normalizer"` with a public procedure:

```al
procedure ToCode20(Input: Text): Code[20]
```

Rules:

1. Remove leading and trailing whitespace **first**.
2. Then truncate to at most **20 characters** — the procedure must never raise a string-overflow error, no matter how long the input is.
3. The result is uppercase, as every `Code` value is. (The `Text` → `Code` conversion does this for you on return/assignment — you don't need `UpperCase` unless you want it explicit.)
4. Empty or whitespace-only input returns an empty code.

## What the tests check

The grading tests call `ToCode20` with a short lowercase value (expected back uppercased and otherwise unchanged), a 40-character value (the first 20 characters are expected, not an error), a padded value (whitespace must be trimmed **before** truncating), an empty string, a whitespace-only value, and a value wrapped in **tabs**. Whitespace means more than spaces: `Text.Trim()` handles tabs, while the old `DelChr(..., '<>', ' ')` idiom strips only spaces and fails the tab cases.

## Learn More

- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type)
- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)
- [Text.Trim method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-trim-method)
- [Text.CopyStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method)
- [Text.MaxStrLen method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-maxstrlen-string-method)
