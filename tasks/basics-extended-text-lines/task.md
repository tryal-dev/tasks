# The Words That Follow the Item

Sales maintains extended text on the item cards — safety notes, "assembly required", a legal blurb in the customer's language — and expects those lines under every order line, whether a person types the order or the integration drops it in overnight. Today the integration's lines arrive bare. Your job is a small order-line builder whose lines look exactly like the ones a user gets with the **Insert Ext. Text** action: the item line, and right behind it the words that belong to it. Business Central already knows which text belongs where; the trick is to ask it.

## Requirements

Create a **codeunit** named `"Order Line Builder"` with two public procedures:

```al
procedure AddItemLineWithText(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal): Integer
procedure RemoveItemLine(var SalesHeader: Record "Sales Header"; LineNo: Integer)
```

Rules:

1. `AddItemLineWithText` appends a line of type Item for `ItemNo` with `Quantity` to the sales order `SalesHeader`, stores it, and returns its `"Line No."`. Validate `Type`, `"No."` and `Quantity` the way the order page would, so the line picks up the item's description and price (not graded — the tests look at the line's type, item and quantity). Number the item line above every line already in the order — 10000 for an empty order and 10000 above the last line afterwards is the convention; only the ordering is graded.
2. Right behind the item line come the item's extended text lines, exactly as the **Insert Ext. Text** action places them: one sales line per `Extended Text Line`, of blank type, with no `"No."` and zero quantity, its `Description` carrying the text, its `"Attached to Line No."` set to the item line's `"Line No."`, and numbered so that the text lines sit after their item line, in the order of the text lines, and before whatever item line is added next.
3. Which text applies follows the standard rules, and codeunit `"Transfer Extended Text"` (378) already implements every one of them. An `Extended Text Header` of the item counts only if its `"Sales Order"` toggle is on; only if the order's `"Document Date"` lies inside its `"Starting Date"`–`"Ending Date"` window (a blank date is open-ended, and the boundary dates themselves count); and only if it fits the order's `"Language Code"`, which the order header copies from the customer: a header in exactly that language wins, a header without a language and with `"All Language Codes"` on serves a customer whose language has no text of its own, and a customer without a language gets the headers without a language and nothing else.
4. The item card's `"Automatic Ext. Texts"` toggle plays no part: the integration inserts the text for every item that has any, whatever the card says. The codeunit works in two steps — `SalesCheckIfAnyExtText` checks the stored line and collects the applicable text (its second parameter, `true`, is what makes it look regardless of the item toggle), and `InsertSalesExtText` writes what was collected. The second step has nothing to write unless the first one ran and returned true.
5. An item that has no applicable text gets a bare item line: no blank lines under it.
6. `RemoveItemLine` deletes item line `LineNo` from the order together with every line attached to it, and leaves the other lines and their text alone. The sales line's own `OnDelete` trigger already takes the attached lines along — but only when the delete runs it.

`SalesHeader` is always a stored, open sales order (document type Order), `ItemNo` an existing item, and `LineNo` the `"Line No."` of an item line the builder created. Nothing has to be released, shipped or posted. Pick object IDs in the range **50100–50199**, and reference other objects **by name, never by ID**.

## What the tests check

The grading tests create customers, items and sales orders with the standard libraries and seed the `Extended Text Header` and `Extended Text Line` records by hand, with generated texts, so a hardcoded description fails. They call `AddItemLineWithText`, read the item line back by the returned `"Line No."` and assert its type, item and quantity; that an item without extended text leaves the order with exactly one line; that a three-line text gives exactly three lines attached to the item line through `"Attached to Line No."`, numbered after it, with the texts in `Description` in the order of the text lines; and that those lines are of blank type, with no `"No."` and zero quantity. The items in those tests have `"Automatic Ext. Texts"` switched on; one further test switches it off and still expects the text. Negative tests seed a header with `"Sales Order"` unticked, one whose `"Ending Date"` is the day before the order's `"Document Date"`, one whose `"Starting Date"` is the day after, and one without a language and with `"All Language Codes"` unticked for a customer who has a language — each expecting no attached lines — while two boundary tests put `"Ending Date"` and `"Starting Date"` exactly on the `"Document Date"` and expect the text. The language tests give an item a language-neutral text and a text in a generated language, and expect exactly the language text for a customer with that language, exactly the neutral text for a customer without a language, and the neutral text again for a customer whose own language has no text. One test adds two items with text and checks that the second item line is numbered after all of the first line's text and gets its own text behind it. The last test removes the first of two item lines and expects it and its text lines gone while the second line and its text stay.

## Learn More

- [Add extended text](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-how-define-ext-text) — how the headers are set up: language, dates and the per-document toggles your builder has to honour.
- [Codeunit "Transfer Extended Text"](https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/codeunit/microsoft.foundation.extendedtext.transfer-extended-text) — the signatures of the check and insert procedures for sales lines.
- [Record.Delete method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-delete-method) — the `RunTrigger` parameter, and what its default is.
- [OnDelete (Table) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/table/devenv-ondelete-table-trigger) — why the cascade to attached lines depends on that parameter.
