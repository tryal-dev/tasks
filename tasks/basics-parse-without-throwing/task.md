# The Parse That Throws

The warehouse imports a spreadsheet of purchase references and lead times every morning. Rows 1 to 4,999 are fine; row 5,000 has `12.5` in a whole-number column — and the whole batch dies with a runtime error. The culprit is one line of AL: `Evaluate(Qty, Cell)`. `Evaluate` returns a `Boolean`, and its documentation is explicit: if you omit that return value and the conversion fails, a runtime error occurs. The starter code makes exactly that mistake, and a few related ones. Your job is a parser that reports bad input as `false` and never raises.

## Requirements

Create a **codeunit** named `"Safe Parser"` with two public procedures:

```al
procedure TryParseReference(Ref: Text; var Prefix: Text; var Year: Integer; var Seq: Integer): Boolean
procedure TryParseLead(Input: Text; var Lead: Duration): Boolean
```

Rules for `TryParseReference`:

1. A reference looks like `INV-2026-000123`: exactly three segments separated by hyphens — a prefix, a year and a sequence number. Two segments or four segments make the reference invalid.
2. The prefix is the first segment, returned exactly as written. It must be at least one character long.
3. The year and the sequence number are whole numbers that fit in an `Integer`. Leading zeros are padding: `000123` is 123. A decimal such as `12.5`, a word, or a number too large for an `Integer` (`3000000000`) makes the reference invalid.
4. A valid reference returns `true` with all three output parameters filled in. Anything else returns `false` — never a runtime error, whatever the input is. When the result is `false`, callers do not rely on the output parameters (not graded).

Rules for `TryParseLead`:

5. `Input` is a lead time written in words, such as `2 days 4 hours` or `90 minutes`. `Evaluate` into a `Duration` variable understands this format natively — `day(s)`, `hour(s)`, `minute(s)`, `second(s)` and their abbreviations — so no arithmetic is required. `2 days 4 hours` is a duration of 52 hours; `90 minutes` is one and a half hours.
6. Text that is not a duration (`soon`) and an empty `Input` return `false`. Never a runtime error.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## The traps

Each of these is a method whose failure mode is an error rather than a return value, and each shows up in the starter or in a tempting rewrite of it:

- `Evaluate` returns `false` when the text cannot be converted — including a number too large for the target type — but only if you *use* the return value. Discard it and the failure becomes a runtime error.
- `Text.Split` returns a `List of [Text]`. `Get(3)` on a list that holds two elements raises an error; check `Count` first, or use the `Get` overload with a `var` parameter, which returns `false` instead.
- `Text.IndexOf` returns 0 when the value is absent — check for that before using the position, because both `Substring` and `CopyStr` raise an error for a position below 1. They differ only in the length: `CopyStr` clamps a length that runs past the end of the text, while `Substring` only tolerates that from Business Central 27.1 onward and raises an error on earlier versions.

## What the tests check

The grading tests call `TryParseReference` with `INV-2026-000123` (expecting `true`, `INV`, 2026 and 123) and with a generated reference — a random uppercase prefix, a random year and a random zero-padded sequence number — so a solution that pattern-matches the example fails. They then expect `false`, and no error, for `INV-2026` (missing segment), `INV-2026-000123-COPY` (extra segment), `INV-2026-12.5` (decimal sequence), `INV-2026-3000000000` (sequence too large for an `Integer`), `INV-YEAR-000123` (non-numeric year), random letters without any hyphen, an empty text, and `-2026-000123` (empty prefix). `TryParseLead` is called with `2 days 4 hours` (expecting exactly 52 hours), a generated `N days M hours` text, and `90 minutes` (expecting exactly one and a half hours), then with `soon` and with an empty text, both expecting `false`. Any runtime error raised by your code fails the test that triggered it.

## Learn More

- [Evaluate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method) — the optional Boolean return value, and the words a Duration string may contain.
- [List.Get(Integer, var T) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-get-integer-t-method) — the overload that returns false instead of raising an error when the index is out of range.
- [Text.Split method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-split-text-method) — splitting a text on a separator into a `List of [Text]`.
- [Duration data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type) — a 64-bit number of milliseconds you can compare and do arithmetic with.
