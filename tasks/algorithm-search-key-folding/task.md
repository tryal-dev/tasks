# Müller Equals Muller

A support agent types `muller` into the customer search and finds nothing — the customer is stored as `Müller GmbH`. Business Central compares what was typed against what is stored, and `ü` is simply not `u`; AL ships no diacritics-folding API, so a search that shrugs off accents, case and punctuation needs its own normalizer. You are building it.

## Requirements

Create a **codeunit** named `"Search Key Folding"` with two public procedures:

```al
procedure ToSearchKey(Input: Text): Text
procedure CountCustomersMatching(Query: Text): Integer
```

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

### `ToSearchKey`

Turns arbitrary text into a canonical *search key*. Every character of `Input` falls into exactly one of three classes:

- Plain letters `a`–`z` / `A`–`Z` and digits `0`–`9` are **kept**.
- A character in the fold map below is **replaced** by its mapped letters.
- Every other character — spaces, punctuation, dashes, symbols, and any character not covered above — is a **separator**.

The fold map (lowercase and uppercase fold the same):

| Characters | Fold to |
|---|---|
| `à á â ã ä å` | `A` |
| `è é ê ë` | `E` |
| `ì í î ï` | `I` |
| `ò ó ô õ ö ø` | `O` |
| `ù ú û ü` | `U` |
| `ý ÿ` | `Y` |
| `ñ` | `N` |
| `ç` | `C` |
| `ß` | `SS` |
| `æ` | `AE` |
| `œ` | `OE` |

Rules for the returned key:

1. Kept and mapped letters appear uppercased; digits appear unchanged.
2. A run of one or more separators between kept characters becomes exactly one space; separators at the start or end of the input are dropped entirely.
3. If nothing survives — the input is empty or consists only of separators — the key is the empty string.
4. A key is a fixed point: `ToSearchKey(ToSearchKey(X))` equals `ToSearchKey(X)` for any input.

Examples: `ToSearchKey('Müller GmbH')` = `MULLER GMBH`; `ToSearchKey('O''Brien   &  Sons, Ltd.')` = `O BRIEN SONS LTD`; `ToSearchKey('Straße 4711')` = `STRASSE 4711`; `ToSearchKey(' --Nordwind-- ')` = `NORDWIND`.

### `CountCustomersMatching`

1. Returns how many `Customer` records have a `Name` whose search key equals the search key of `Query`.
2. A `Query` whose search key is empty matches nothing and returns `0` — an empty key must never sweep up records.
3. The procedure never raises an error, whatever `Query` contains; a search that finds nothing returns `0`.

## What the tests check

The grading tests call `ToSearchKey` and compare the returned key **character for character**: the fold map applied to German, Nordic, French and Spanish names, **every character of the fold map in both its lowercase and uppercase form**, `ß` doubling to `SS`, the `æ`/`œ` ligatures, digits kept, punctuation runs collapsing to single spaces, trimmed ends, the empty and all-punctuation inputs yielding the empty string, and re-folding a key returning it unchanged. Several expected keys are built around **randomly generated text**, so hardcoding the examples will not pass — and plain `UpperCase` fails every accented case, because `Ü` is still not `U`. The lookup tests seed customers such as `TRYAL-SKF1 Müller GmbH` and `TRYAL-SKF1 MULLER GMBH` next to decoys like `TRYAL-SKF1 Mueller GmbH`, then assert **exact counts** for hits, misses, a separator-only query, and the empty query. The tests run in a real company where other customers exist — the seeded names carry unique markers, and your counts must be driven purely by the key equality described above.

## Learn More

- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type) — the toolbox for taking strings apart and putting them back together.
- [Text.UpperCase(Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-uppercase-method) — uppercasing is the easy third of the job; notice what it does *not* do to accents.
- [TextBuilder data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type) — assembling a result string piece by piece without churning memory.
