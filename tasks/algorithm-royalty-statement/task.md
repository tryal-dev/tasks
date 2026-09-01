# Performance Royalties

Your client licenses theatrical plays to touring companies, and at month-end every licensing agreement gets a royalty statement: one line per performance played, a fee computed from the play's category and audience size, and loyalty credits the licensee redeems against future bookings. The fee formulas come straight from the negotiated contracts — your job is to turn them into a statement engine.

## What you are given

The starter contains two finished tables — submit them unchanged alongside your codeunit:

- Table `"Royalty Performance"` — the register of played shows: field 1 `"Entry No."` (`Integer`, PK), field 2 `"Agreement No."` (`Code[20]`), field 3 `"Play Name"` (`Text[50]`), field 4 `Category` (`Code[20]`), field 5 `Audience` (`Integer`).
- Table `"Royalty Statement Line"` — the statement buffer: field 1 `"Line No."` (`Integer`, PK), plus `"Play Name"` (`Text[50]`), `Category` (`Code[20]`), `Audience` (`Integer`), `Amount` (`Decimal`), and `Credits` (`Integer`).

## Requirements

Implement a **codeunit** named `"Royalty Statement"` with three public procedures, exactly as written:

```al
procedure LineAmount(Category: Code[20]; Audience: Integer): Decimal
procedure LineCredits(Category: Code[20]; Audience: Integer): Integer
procedure BuildStatement(AgreementNo: Code[20]; var RoyaltyStatementLine: Record "Royalty Statement Line" temporary; var TotalAmount: Decimal; var TotalCredits: Integer)
```

Two categories are negotiated so far — the category codes are exactly `TRAGEDY` and `COMEDY`:

- A tragedy costs a flat base fee of 400.00. When more than 30 people attend, add 10.00 for every attendee above 30.
- A comedy costs a base fee of 300.00 plus 3.00 per attendee — every attendee, at any audience size. When more than 20 people attend, add a bonus of 100.00 plus 5.00 for every attendee above 20.
- Loyalty credits: every performance earns one credit per attendee above 30 (zero when the audience is 30 or smaller — never negative). A comedy additionally earns one credit for every full group of 5 attendees, fractions dropped — an audience of 9 adds one extra credit, an audience of 34 adds six.
- Any other category is unknown: both `LineAmount` and `LineCredits` must raise an error with a message that contains the category code.

`BuildStatement` writes the statement of one agreement into the caller's buffer:

- start clean: remove any lines already in the buffer and reset both totals — nothing from a previous build may survive;
- include exactly the performances whose `"Agreement No."` matches, and nothing else;
- one line per performance, in ascending `"Entry No."` order, numbered `"Line No."` = 1, 2, 3, ... without gaps;
- copy `"Play Name"`, `Category` and `Audience` from the performance, and set `Amount` and `Credits` to that performance's fee and credits by the rules above;
- return the sums: `TotalAmount` is the sum of all line amounts, `TotalCredits` the sum of all line credits;
- an agreement with no performances yields an empty buffer and zero totals;
- if any included performance carries an unknown category, the build fails with the same error.

Worked example: an agreement's month has *Hamlet* (`TRAGEDY`, audience 55), *As You Like It* (`COMEDY`, audience 35) and *Othello* (`TRAGEDY`, audience 15). The statement lines are 650.00 with 25 credits, 580.00 with 12 credits (5 for the attendees above 30 plus 7 for the full groups of five), and 400.00 with 0 credits — `TotalAmount` 1630.00, `TotalCredits` 37.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

What you may rely on — the tests never violate this: `Audience` is at least 1 in every graded case, and every expected amount is an exact sum of the fees above. No rounding is involved; all decimal comparisons are exact.

## What the tests check

The per-line procedures are graded directly: the tragedy fee below, exactly at, and just above 30 attendees plus a generated larger audience; the comedy fee exactly at and just above 20 attendees plus generated audiences on both sides of the bonus threshold; credits at exactly 30 and at 31 attendees, a generated tragedy audience, and comedy audiences of 9 and 34; and the unknown-category error from both procedures — for `HISTORY` and for a generated category code, verified via the expected error text. `BuildStatement` is graded on the worked example seeded next to a foreign agreement (line order, every copied field, both amounts and credits per line, both totals), on clearing a pre-filled buffer and pre-set totals, on an agreement with no performances, on failing when one performance's category is unknown, and on a randomized agreement whose totals the test computes independently — so hardcoding the worked example fails.

## Learn More

- [Temporary tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables) — the statement buffer is a temporary record: what that means and how to work with one.
- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — narrowing a table to one agreement's records.
- [Dialog.Error(Text [, Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method) — raising the unknown-category error with the code substituted into the message.
- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type) — how `Code` values behave (uppercase, no surrounding spaces) when you compare category codes.
