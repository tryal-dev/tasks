# Copy a Record into a Table Whose Field Numbers Disagree

A carrier integration app owns the archive table your freight charges have to end up in. Its field numbers were chosen by that vendor, not by you, and they do not line up with the numbers in your own table. `TransferFields` pairs fields **by field number**, so the obvious one-liner files your quantity as a discount percentage.

In production the two tables live in different extensions, and Microsoft documents that a field-number collision between *different* apps never raises an error — deliberately, so that installing a new extension cannot break code that already works. Everything you submit here compiles into a single app, where the same collision does raise a runtime error, and `TransferFields`'s third argument `SkipFieldsNotMatchingType` makes that error go away again. Neither the silence nor the error makes the copy correct. Only an explicit map does.

## What you are given

Two finished tables. Submit both unchanged alongside your codeunit — the field numbers and types below are part of the exercise, not a bug to fix.

Table `"Freight Charge"` (yours, the source):

| Field no. | Field | Type |
|---|---|---|
| 1 | `"Entry No."` | `Integer` (primary key) |
| 2 | `"Shipment No."` | `Code[20]` |
| 3 | `Description` | `Text[100]` |
| 10 | `Quantity` | `Decimal` |
| 11 | `"Unit Freight Cost"` | `Decimal` |
| 12 | `"Discount %"` | `Decimal` |
| 20 | `"Posting Date"` | `Date` |
| 30 | `"Carrier Code"` | `Code[10]` |
| 90 | `Archived` | `Boolean` |

Table `"Carrier Charge Archive"` (the carrier vendor's, the destination):

| Field no. | Field | Type |
|---|---|---|
| 1 | `"Entry No."` | `Integer` (primary key) |
| 10 | `"Discount Pct"` | `Decimal`, with an `OnValidate` that rejects anything outside 0–100 |
| 20 | `"Carrier Code"` | `Code[20]` |
| 35 | `"Charge Amount"` | `Decimal` |
| 40 | `"Reference Text"` | `Text[30]`, with an `OnValidate` that upper-cases the value |
| 50 | `"Archived On"` | `Date` |
| 60 | `Quantity` | `Decimal` |
| 70 | `"Shipment No."` | `Code[20]` |

Three numbers exist on both sides — 1, 10 and 20 — and only number 1 means the same thing on both. The archive has no home at all for `"Posting Date"` or `"Unit Freight Cost"`.

## Requirements

Implement codeunit `"Freight Charge Archiver"` with exactly this procedure:

```al
procedure Archive(EntryNo: Integer; ArchivedOn: Date)
```

For the freight charge whose `"Entry No."` equals `EntryNo`, `Archive` writes one `"Carrier Charge Archive"` row filled like this:

| Archive field | Value |
|---|---|
| `"Entry No."` | the freight charge's `"Entry No."` |
| `"Shipment No."` | the freight charge's `"Shipment No."` |
| `"Carrier Code"` | the freight charge's `"Carrier Code"` |
| `Quantity` | the freight charge's `Quantity` |
| `"Discount Pct"` | the freight charge's `"Discount %"` |
| `"Charge Amount"` | the freight charge's `Quantity` multiplied by its `"Unit Freight Cost"`, rounded to two decimals |
| `"Reference Text"` | the first 30 characters of the freight charge's `Description`, stored in upper case |
| `"Archived On"` | the `ArchivedOn` parameter |

and then:

- flags the freight charge as `Archived` — the freight charge row itself stays: a separate cleanup job owns it;
- fails with an error, writing nothing, when no freight charge carries the given `"Entry No."`;
- fails with an error when the freight charge is already flagged `Archived`, leaving the archive row written by the first call untouched;
- fails with an error, writing nothing, when the freight charge's `"Discount %"` is outside 0–100 (legacy rows carry such values).

Two of those rules are the archive table's own business logic, living in `OnValidate` triggers on `"Discount Pct"` and on `"Reference Text"`. Neither `TransferFields` nor a plain `:=` ever runs an `OnValidate` — assigning is all they do. Make those triggers run, or reproduce what they do yourself. Note the widths as well: `"Reference Text"` holds 30 characters and `Description` holds 100, so shortening the value is your job too.

Keep any object you add in the house range 50100–50199, and reference other objects by name, never by ID. Captions and tooltips are not graded.

## What the tests check

The tests seed fully populated freight charges — generated quantities, unit costs, discounts, descriptions and dates — call `Archive` once, and then read the archive row **one destination field per test**, so a misfiled value tells you exactly which pairing went wrong. The discount test deliberately gives its freight charge a quantity far above 100, so a copy that pairs field 10 with field 10 is unmistakable in the value that lands. Further tests cover the `Archived` flag, the `"Archived On"` stamp, and each of the three error paths (missing entry, already archived, out-of-range discount), asserting in each case that nothing was written. Both ends of the discount rule are graded — a value below 0 has to be refused exactly like one above 100, while exactly 100 is inside the range and must still archive. The already-archived path is graded twice: once on a second call, and once on a freight charge that carries the flag with no archive row behind it yet, so only reading the flag itself passes.

Two tests call `TransferFields` directly against the two given tables: one asserts that the plain call still fails on the field-20 pair, the other that `TransferFields(FreightCharge, true, true)` runs through and files the quantity as a discount. Renumbering or retyping the given tables to make the mismatch disappear fails those tests.

## Learn More

- [Record.TransferFields(var Record, Boolean, Boolean) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-table-boolean-boolean-method) — the three-argument overload, and the note on what happens across extensions.
- [Record.Validate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method) — the way to make a destination field's own logic run.
- [OnValidate (Field) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/field/devenv-onvalidate-field-trigger) — what those triggers do, and when they run.
- [Text.CopyStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method) — shortening a value to fit a narrower field.
