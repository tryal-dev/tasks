# Undo the Receipt, Prove the Reversal

The receiving clerk scans a pallet against the wrong purchase order. It happens every week, and it has to be fixed before the vendor's invoice arrives. Juniors "fix" it by hand: they type a negative line, or they post an item journal adjustment, and the numbers on the item card look right again. They are not right. The posted receipt still claims the goods arrived, the purchase order still thinks it has been received in full, and nobody can ever reopen it and receive the pallet properly.

Business Central has one correct answer for this, and it is not a negative line. Your job is to wrap it in a small service so the warehouse app can reverse one receipt line safely — silently, scoped to exactly that line, and refusing the cases where a reversal is no longer allowed.

## Requirements

Create a **codeunit** named `"Receipt Correction"` with two public procedures — the grading tests bind to these names character for character:

```al
procedure UndoReceiptLine(ReceiptNo: Code[20]; LineNo: Integer): Decimal
procedure IsReversible(ReceiptNo: Code[20]; LineNo: Integer): Boolean
```

`ReceiptNo` and `LineNo` identify one posted purchase receipt line — the `"Document No."` and `"Line No."` of a `"Purch. Rcpt. Line"` record.

Rules for `UndoReceiptLine`:

1. It reverses that receipt line the way Business Central itself reverses a posted receipt — the same bookkeeping the **Undo Receipt** action on the Posted Purchase Receipt page produces. Reaching the same totals any other way (a hand-written negative receipt line, an item journal adjustment, deleting entries) fails the tests.
2. It runs **silently**. No confirmation dialog, message or progress window may reach the caller: the grading tests declare no handler functions, so any dialog fails the test outright.
3. It reverses **only** the line it was given. Every other posted receipt line in the database — including the other lines of the same receipt — must come out untouched.
4. It returns the quantity it reversed: the line's own `Quantity`, positive, as it stood before the reversal.
5. Before touching anything, it refuses three cases with its own error, checked in this order:
   - the line does not exist — `Receipt line <LineNo> of <ReceiptNo> does not exist.`
   - the line is a correction line (`Correction` is `true`) — `Receipt line <LineNo> of <ReceiptNo> is already reversed.`
   - the line is invoiced, meaning its `"Qty. Rcd. Not Invoiced"` differs from its `Quantity` — `Receipt line <LineNo> of <ReceiptNo> is already invoiced and cannot be undone.`

   `<LineNo>` and `<ReceiptNo>` are the two arguments, in that order, printed as they were passed. These are the messages the tests match, so note the wording and the full stop; the base application's own refusals ("This receipt has already been invoiced…") do not count. A refusal must change nothing.

Rule for `IsReversible`:

6. It returns `true` exactly when `UndoReceiptLine` would proceed — the line exists, is not a correction line, and is not invoiced — and `false` in every other case, including a receipt number or line number that matches nothing. It never raises an error and never changes data.

Environment notes:

- The graded receipts are plain item lines on ordinary purchase orders — no warehouse receipts, item tracking, drop shipments, jobs or production orders.
- The grading company has `"Ext. Doc. No. Mandatory"` switched off, so posting needs no `"Vendor Invoice No."`.
- Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

Each test posts its own purchase order for a freshly created vendor and item at a quantity generated at run time, so nothing can be hardcoded. After one `UndoReceiptLine` the tests assert: a second `"Purch. Rcpt. Line"` exists on that receipt with `Correction = true` and `Quantity` equal to minus the received quantity; the original line survives with its positive `Quantity` and now carries `Correction = true` itself; the item owns exactly **two** item ledger entries — the original positive one plus a reversing negative one, so deleting history instead of reversing it fails — their `Quantity` sums to exactly `0`, and the negative one is the entry Undo Receipt itself posts: a `Purchase` entry of `"Document Type"` `Purchase Receipt` carrying the receipt's `"Document No."` with `Correction = true`, so an item journal adjustment that reaches the same on-hand quantity fails; the purchase order line's `"Quantity Received"` and `"Qty. Rcd. Not Invoiced"` are back to `0` with `"Outstanding Quantity"` equal to the full ordered quantity; and the order really is receivable again — one test posts the receipt a second time and expects a new posted receipt carrying the full quantity, with the item ledger back to the received quantity. The return value is compared against the generated quantity. A two-line receipt is undone on its first line only, and the second line must still read `Correction = false` with its own order line's `"Quantity Received"` intact. On the error side: `asserterror` covers a receipt line that was received **and invoiced in full**, one received in full but invoiced only **in part** (so its `"Qty. Rcd. Not Invoiced"` differs from its `Quantity` without being `0`), a line already undone by a previous call, and a receipt number that does not exist, each expecting the exact message from rule 5 — and both invoiced cases additionally check that the receipt line was left alone. `IsReversible` is checked `true` for a received-but-not-invoiced line and `false` for a fully invoiced line, a partly invoiced one, an already-reversed line, and a line that does not exist.

## Learn More

- [Reverse journal postings and undo receipts/shipments](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-how-reverse-journal-posting) — what Undo Receipt does to the posted document and to the originating purchase order, and when it is no longer allowed.
- [Design details: Inventory posting](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-inventory-posting) — why a reversal adds an item ledger entry instead of removing one.
- [Codeunit.Run(var Record) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunitinstance-run-method) — running a codeunit instance against a record, and what the record parameter carries with it.
- [Record purchases with purchase invoices and orders](https://learn.microsoft.com/en-us/dynamics365/business-central/purchasing-how-record-purchases) — the receive-then-invoice lifecycle the graded quantities move through.
