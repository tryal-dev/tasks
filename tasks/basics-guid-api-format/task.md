# Braces Off, Lowercase On

A partner's ordering API identifies every record by its Business Central `SystemId`, and it is picky about the spelling: ids must travel as `ea48a3e0-48e0-4ab7-b1a1-e3ea85bf1b75` — lowercase, hyphens kept, no braces — and they come back in exactly that shape. The helper your predecessor wrote sends `Format(Id)`, which is `{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}`, so the partner rejects every call; and the first malformed id the partner ever sent back crashed the whole import with an `Evaluate` error. You will rewrite both directions.

## Requirements

Create a **codeunit** named `"Api Id Format"` with two public procedures:

```al
procedure ToApiId(Id: Guid): Text
procedure TryParseId(Input: Text; var Id: Guid): Boolean
```

Rules:

1. `ToApiId` returns the id as 32 lowercase hexadecimal digits in five hyphenated groups of 8-4-4-4-12 — 36 characters, no braces: the GUID `{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}` comes out as `ea48a3e0-48e0-4ab7-b1a1-e3ea85bf1b75`.
2. The all-zero GUID (the null GUID — the value an unassigned `Guid` variable holds) means "no id": `ToApiId` returns an empty text for it, never `00000000-0000-0000-0000-000000000000`.
3. `TryParseId` accepts both the API form (`ea48a3e0-48e0-4ab7-b1a1-e3ea85bf1b75`) and Business Central's braced display form (`{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}`), stores the value in `Id`, and returns `true`. Upper- and lowercase hex digits are accepted in either form.
4. `TryParseId` returns `false` for text that is not a GUID — empty text, words, a truncated id, or something GUID-shaped whose characters are not hex digits. `TryParseId` must never raise an error, whatever the text contains.
5. The all-zero GUID spelled out as text (`00000000-0000-0000-0000-000000000000`) is "no id" too: `TryParseId` returns `false` for it.
6. Round trip: for any non-null GUID, `TryParseId` accepts the text `ToApiId` produced and yields exactly the original value.
7. After a `false`, the returned Boolean is the only graded signal — whatever is left in `Id` is not checked.

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What to know

`Format(Id)` gives the display form — braces and uppercase. The three-argument `Format(Value, Length, FormatNumber)` selects one of the standard formats instead, and the GUID row of the standard-formats table on Learn shows what each number produces: formats 0 to 2 are the braced form, format 3 is the 32 digits with no hyphens at all, and format 4 is the hyphenated form without braces. Every one of them is uppercase — lowercasing is a separate step.

`Evaluate(Id, Input)` is the parser, and it understands both the braced and the bare spelling. Used as a statement, it raises an error when the text is not a GUID; captured as a Boolean expression, it reports the failure as `false` instead — that difference is what caused the crash. The all-zero GUID is perfectly acceptable text to `Evaluate`, so rejecting it afterwards is your job.

The starter checks for "no id" by comparing the `Guid` with an empty text. That compiles, because AL converts between the two types, but a GUID is never text: its empty value is the all-zero GUID, and `IsNullGuid` is the check that names that fact. Replace the comparison rather than reasoning about what the runtime makes of it.

## What the tests check

`ToApiId` is compared character for character against the expected text for a fixed GUID and for a freshly generated one (whose expected text the test computes on its own, so hardcoding the example fails), asserted to differ from `Format(Id)` for a generated GUID, and expected to return an empty text for the null GUID. `TryParseId` is fed the bare lowercase form, the bare uppercase form, the braced uppercase form and the braced lowercase form (each must return `true` and yield the GUID it spells), then garbage — `not-an-id-at-all`, a truncated id, `zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz`, and empty text — plus the all-zero GUID text (each must return `false`, not an error). One round-trip test runs `ToApiId` and then `TryParseId` on a generated GUID and expects the original value back.

## Learn More

- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property#standard-guid-formats) — the standard GUID formats table: what each format number produces.
- [Guid data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type) — the text spellings a GUID accepts, with `Format` and `Evaluate` as the conversions.
- [System.Evaluate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method) — the optional Boolean return that turns a parse failure into `false`.
- [System.IsNullGuid method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-isnullguid-method) — the check for the all-zero GUID.
