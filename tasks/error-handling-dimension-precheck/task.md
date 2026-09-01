# Dimensions Before You Post

`Select a Dimension Value Code for the Dimension Code DEPARTMENT...` — the single most common support ticket in Business Central finance. It always arrives the same way: someone clicks Post on a twelve-line order, the whole posting is refused because of one line, and nobody can tell which one until they walk the document by hand.

Your job is a pre-flight validator. Given a sales document, it reports **every** line whose dimensions break a default-dimension rule — all of them, in one pass, before anyone touches Post.

## Requirements

Create a **codeunit** named `"Dimension Precheck"` with one public procedure:

```al
procedure CheckSalesDocument(SalesHeader: Record "Sales Header"; var Violation: Record "Dimension Precheck Violation"): Integer
```

The starter already contains the buffer table the procedure fills, `"Dimension Precheck Violation"`, declared `TableType = Temporary` with these fields and the primary key `"Line No."`, `"Dimension Code"`:

- `"Line No."` (`Integer`) — `0` for the document header, otherwise the sales line's own `"Line No."`.
- `"Dimension Code"` (`Code[20]`) — the dimension whose rule was broken.
- `"Value Posting"` (`Enum "Default Dimension Value Posting Type"`) — the rule that was broken.

Do **not** add the `temporary` keyword to the `Violation` parameter: the table is already temporary by declaration, and the tests pass a plain record variable.

### What the procedure does

1. It empties `Violation`, writes one row per broken rule, and returns the number of rows it wrote.
2. Every source of rules is a **master record** carrying `Default Dimension` rows. The document header is checked against the `Customer` in `SalesHeader."Bill-to Customer No."`, using `SalesHeader."Dimension Set ID"`; findings are reported with `"Line No."` = `0`.
3. Every sales line of the document is checked twice: against that same customer, **and** against the line's own master record — the record its `Type` and `"No."` point at (an `Item` for an item line, a `G/L Account` for a G/L account line, a `Resource` for a resource line, a `Fixed Asset` for a fixed-asset line, an `Item Charge` for a charge line). Both checks run against `SalesLine."Dimension Set ID"` and are reported with that line's `"Line No."`.
4. Lines that point at no master record — `Type` is blank, or `"No."` is blank, as on description and comment lines — are skipped entirely and never reported.
5. A `Default Dimension` row is a **rule** only when its `"Value Posting"` is not blank. Plain default-dimension rows (`"Value Posting"` blank) only supply a default value and can never be violated.

### The three rules

For a rule on dimension `D` and the dimension set being checked:

- **Code Mandatory** — the set must hold a non-blank value for `D`. Broken when the set has no value for `D`.
- **Same Code** — the set's value for `D` must be exactly the rule's `"Dimension Value Code"`. When that field is **blank**, the set must hold **no** value for `D`. Broken in every other case.
- **No Code** — the set must hold no value for `D`. Broken when it holds one.

### What you can rely on

- Sell-to and bill-to customer are the same on every document the tests build.
- For any one dimension set that gets checked, at most one of its two sources carries a rule for a given dimension code — so a `"Line No."` + `"Dimension Code"` pair is never claimed twice, and you never have to decide which of two rules wins.
- The same broken rule on three lines is three rows, one per line.

Pick object IDs in the range **50100–50199** and reference other objects **by name, never by ID**. Captions on your own objects are good practice but not graded.

## What the tests check

The grading tests build sales orders in a real company, put `Default Dimension` rules of each of the three kinds on the customer, on an item, on a G/L account and on a resource, bend the document's dimension sets so a rule breaks, then call `CheckSalesDocument` and check both the returned count and the exact rows in the buffer — `"Line No."` (`0` for the header), `"Dimension Code"` and the `"Value Posting"` rule named. Covered: a missing mandatory value, a Same Code rule met, a Same Code rule missed by a different value and missed by no value at all, a **blank** Same Code rule against a line that carries a value, a No Code rule met and missed, the customer's rules reaching every line, two broken rules on one line, a description-only line that must never be reported, a plain default dimension without a rule that must never be reported, and a buffer left over from an earlier call that must be emptied. Two tests anchor the result to reality: a document whose line the precheck flags is refused by the standard posting routine, and a document the precheck accepts posts successfully.

## Learn More

- [Work with dimensions](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-dimensions) — default dimensions per master record, and what the `Value Posting` field is for.
- [Troubleshoot and correct dimensions](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-troubleshooting-correcting-dimensions) — every dimension error that posting can raise, and the rule behind each one.
- [Dimension Set Entries Overview](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-dimension-set-entries-overview) — how a document's dimensions are stored as a shared, immutable set.
- [Temporary tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables) — what `TableType = Temporary` means for the buffer you fill.
