# A 32-Column Receipt

The shop's thermal receipt printer prints exactly 32 characters per line: the first 20 columns hold the item description, the last 12 hold the amount, right-aligned so the decimal points stack up. Your codeunit produces those lines, plus the zero-padded document number printed at the top of every receipt.

## Requirements

Create a **codeunit** named `"Receipt Formatter"` with two public procedures:

```al
procedure ReceiptLine(Description: Text; Amount: Decimal): Text
procedure DocumentNo(Prefix: Code[10]; Seq: Integer): Code[20]
```

Rules for `ReceiptLine`:

1. The result is **always exactly 32 characters** long.
2. Columns 1–20 hold `Description`, left-aligned and padded with spaces on the right. A description longer than 20 characters is cut to its first 20 characters. An empty description leaves 20 spaces.
3. Columns 21–32 hold `Amount`, right-aligned (spaces on the left) with **exactly two decimals** — `3.5` prints as `3.50`, `2` as `2.00`. The decimal separator is always a period, whatever region the server runs under, and there is **no thousands separator**: `1234567.8` prints as `1234567.80`. A negative amount keeps its minus sign directly in front of the first digit: `-3.5` prints as `-3.50`.
4. `Amount` always lies between `-99999999.99` and `99999999.99` and never carries more than two decimals, so the amount column never overflows.

Rules for `DocumentNo`:

5. The result is `Prefix`, a hyphen, and `Seq` zero-padded on the **left** to at least five digits: `DocumentNo('INV', 42)` returns `INV-00042`.
6. Longer sequences keep every digit — `DocumentNo('INV', 100000)` returns `INV-100000`, and `DocumentNo('RCP', 99999)` returns `RCP-99999`. `Seq` is always at least 1 and at most 999999; `Prefix` is always 1–10 uppercase letters.

The starter already compiles, but its `DocumentNo` pads on the wrong side: `PadStr` adds its filler characters at the **end** of the string, so sequence 42 comes out as `42000`. `PadStr` is still the right tool for the description column — it pads on the right and truncates longer text — but the zeros need a method that pads on the left.

For the amount, `Format(Value, Length, FormatString)` does both jobs in one call: with a positive `Length` the result is exactly that many characters — a number gets its padding spaces on the left, and a value longer than `Length` is **silently cut**, so never rely on it to complain. The format string decides the digits: `<Precision,2:2>` forces exactly two decimals, and the standard format picks the separators — standard format 0 inserts thousands separators, standard format 1 follows the server's region settings for both separators, and standard format 2 (like 9) always uses a period and never a thousands separator. Pick the one that prints the same on every server.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

```text
|Coffee                      3.50|
|Extra Large Cappucci       12.00|
|Refund                     -3.50|
|Catering              1234567.80|
```

The `|` marks are not part of the line — they show where the 32 columns start and end.

## What the tests check

The grading tests compare every `ReceiptLine` result **character for character** against the expected 32-character line: a short description (`Coffee`, `3.5`), a generated description of 1–19 letters, a generated 35-character description that must be cut to 20, an empty description, a whole-number amount (`2`), a negative amount (`-3.5`), and `1234567.8`, whose line must show `1234567.80` with no thousands separator. One test feeds a generated description of 1–40 letters and a generated amount and only checks that the line is 32 characters long. For `DocumentNo`, the tests expect `INV-00042`, `INV-100000`, `RCP-99999` and a generated prefix with a generated sequence between 1 and 99999 — so zeros pasted at the wrong end, a six-digit sequence cut to five digits, or a hardcoded prefix all fail.

## Learn More

- [Format method (Any, Integer, Text)](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method) — the three rules for the `Length` argument, including the silent truncation.
- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property) — `<Precision>`, `<Filler Character>`, `<Integer,n>` and the standard decimal formats side by side for US and European regions.
- [Text.PadStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-padstr-method) — pads at the end or truncates, with a worked example.
- [Text.PadLeft method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-padleft-method) — right-aligns by padding on the left with any character.
