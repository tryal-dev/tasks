# Column AA Comes After Z

Your export writes an Excel sheet cell by cell, and every cell needs a reference like `B7` or `AC12`. The row is just a number; the column is where it gets interesting. Excel counts columns `A` … `Z`, then `AA` … `AZ`, `BA` … `ZZ`, then `AAA`, all the way to `XFD` (column 16,384). It looks like base 26 — but there is no letter that stands for zero, and that one missing digit is exactly where the obvious approach goes wrong. You are writing the conversion in both directions.

## Requirements

Create a **codeunit** named `"Excel Column"` with two public procedures:

```al
procedure ColumnLetters(Index: Integer): Text
procedure ColumnIndex(Letters: Text): Integer
```

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

### `ColumnLetters`

1. Returns the column letters for a 1-based column index: `1` → `A`, `2` → `B`, … `26` → `Z`, `27` → `AA`, `28` → `AB`, … `52` → `AZ`, `53` → `BA`, … `702` → `ZZ`, `703` → `AAA`, … `16384` → `XFD`.
2. The result is always uppercase and consists of the letters `A`–`Z` only — no spaces, no padding, nothing else.
3. An `Index` of `0` or below raises an error whose message contains the text `positive`.

### `ColumnIndex`

1. The inverse: returns the 1-based index of the column named by `Letters`: `A` → `1`, `Z` → `26`, `AA` → `27`, `ZZ` → `702`, `AAA` → `703`, `XFD` → `16384`.
2. Letters are accepted in any case: `aa`, `Aa` and `AA` all mean column 27.
3. A `Letters` that is empty, or that contains any character other than a letter `A`–`Z` / `a`–`z` (a digit, a space, punctuation), raises an error whose message contains the text `not a valid column`.
4. For every index `N ≥ 1`, `ColumnIndex(ColumnLetters(N))` returns `N`.

## What the tests check

The tests call `ColumnLetters` with the fixed indexes `1`, `26`, `27`, `52`, `702`, `703` and `16384` and compare the returned text **exactly** (uppercase, nothing else), and call `ColumnIndex` with every single letter `A`–`Z`, with `AA`, `ZZ`, `AAA` and `XFD`, and with the lowercase `aa` and the mixed-case `xFd`. `26` and `52` are the tests that catch treating the letters as an ordinary base-26 number — both end in `Z`, not in a character before `A`. Two tests build a random three-letter column, compute its index independently and check each direction; two more round-trip a random index of up to one million through `ColumnLetters` and `ColumnIndex`, once as returned and once lowercased — so hardcoding the examples cannot pass. The remaining tests expect an error containing `positive` for an index of `0` and for a random negative index, and an error containing `not a valid column` for the empty string, for `A1`, for ` A ` (a letter with a space on each side — the input is not trimmed) and for `A_B`.

## Learn More

- [Char data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type) — a character is a number underneath, and the page shows the three ways to put one into a `Char` variable.
- [Arithmetic operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-arithmetic-operators) — which types `+`, `-`, `div` and `mod` accept, and what type comes out when a `Char` meets an `Integer`.
- [AL operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-operators) — the operator precedence table; `mod` binds tighter than `+`, which matters the moment you combine them.
- [Text.UpperCase(Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-uppercase-method) — the cheapest way to make `aa`, `Aa` and `AA` the same input.
