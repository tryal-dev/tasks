# Resolve Scanned Codes Without a Prompt

An unattended intake job receives EDI lines and scanner reads all day: each one is a customer plus the code that customer used for the goods — their own article number, or a bar code off the label — never one of your item numbers. Business Central's `"Item Reference"` table maps those foreign codes to your items, and the same code can appear on several rows at once: one per customer, plus shared bar-code rows and untyped leftovers.

Your job is the resolver: given a sales line and a scanned code, pick the right reference deterministically and carry its item, variant, unit of measure and description onto the line — with nobody at a keyboard. The platform offers a tempting one-liner for this — validating the line's `"Item Reference No."` — but it judges a reference's date window by the order's own date, not by the day the scan arrived, and it breaks a tie between a bar-code row and a blank-type row by whichever sorts first rather than by policy. The lookup is yours to write.

## Requirements

Create a **codeunit** named `"Scanner Intake"` with one public procedure. Pick object IDs in the 50100–50199 range and reference every other object by name, never by ID.

```al
procedure ResolveScannedCode(var SalesLine: Record "Sales Line"; ScannedCode: Code[50]; IntakeDate: Date)
```

The sales line already exists on an open sales order, and its `"Sell-to Customer No."` names the customer the scan came from.

Rules:

1. A row of table `"Item Reference"` is a *candidate* when its `"Reference No."` equals `ScannedCode` and it is active on `IntakeDate`: its `"Starting Date"` is blank or on/before `IntakeDate`, and its `"Ending Date"` is blank or on/after `IntakeDate`. A reference that starts or ends exactly on `IntakeDate` is active.
2. Among the active candidates one wins by tier: first a row with `"Reference Type"` = `Customer` whose `"Reference Type No."` equals the line's `"Sell-to Customer No."`; otherwise a row with `"Reference Type"` = `Bar Code`; otherwise a row with a blank `"Reference Type"`. A customer row belonging to a different customer is never used — not even when the caller has no row of their own. The tests never seed `Vendor` rows and never put two active candidates in the same tier for the same caller.
3. Apply the winner to the line: `Type` becomes `Item` and `"No."` becomes the winner's `"Item No."` (validated, so the item's defaults flow in); `"Variant Code"` becomes the winner's variant; when the winner's `"Unit of Measure"` is non-blank it becomes the line's `"Unit of Measure Code"`, otherwise the item's own default unit stays; when the winner's `Description` is non-blank it becomes the line's `Description`, otherwise the item's description stays; the line's `"Item Reference No."`, `"Item Reference Type"` and `"Item Reference Type No."` record the winning row; and the change is saved — the tests re-read the line from the database.
4. When the code is unknown, or every row carrying it is inactive on `IntakeDate`, raise an error with a message that contains the scanned code.
5. The procedure must never open a page or dialog, whatever the data looks like. The grading tests declare no UI handlers, so any prompt — including one raised by platform code you call — fails the test immediately.

## What the tests check

The tests seed the same reference number for two customers plus a bar-code row and a blank-type row — every row pointing at a different item — and call the resolver once per customer, asserting each caller's line ends up with that customer's own item, variant, unit of measure and description, re-read from the database. Further tests assert that the bar-code row beats the blank-type row when the caller has no customer row, that the blank-type row is used as the last resort, that rows expired before `IntakeDate` or starting after it are skipped (falling through to the next tier), and that a row starting *and* ending exactly on `IntakeDate` still wins. A reference with a blank description and unit of measure must leave the item's own description and default unit on the line. An unknown code, and a code whose rows are all inactive, must each raise an error containing the code — checked with `asserterror`. The `IntakeDate` the tests pass lies months after the order's own dates, and every dated reference is dated relative to it — a resolver that lets the document's date decide the window instead of `IntakeDate` resolves the wrong rows. Item numbers, reference numbers and descriptions are generated at run time, so hardcoded answers can't pass, and no test declares a UI handler.

## Learn More

- [Use item references](https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-use-item-cross-refs) — the business feature you are automating: what a reference row carries and what filling one in does to a document line.
- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — narrowing a table to exactly the rows a policy allows.
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method) — a range filter's two bounds are just what a date window needs.
- [Record.FindFirst Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findfirst-method) — fetching a single winner out of a filtered set.
