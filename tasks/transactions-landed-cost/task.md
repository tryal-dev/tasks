# Landed Cost: Spread the Freight Across the Receipts

The freight forwarder's invoice always arrives after the goods: two purchase receipts are already posted and invoiced when a bill for shipping, duty and customs lands on your desk. That bill is part of what the items really cost — a purchase price is not a landed cost — and your inventory value is only honest once each receipt carries its share.

Business Central has a dedicated mechanism for exactly this situation, and this task makes you drive it in pure AL: no pages, no suggest buttons, just code that takes a posted world and a charge amount and leaves behind receipts whose actual cost tells the truth.

## The objects you get

- Enum `"Landed Cost Method"` — values `"By Quantity"` and `"By Amount"`. Include it in your submission unchanged.

## Requirements

Implement the codeunit `"Landed Cost Mgt."` with exactly these two procedures — the grading tests bind to every name below character for character:

```al
procedure AssignAndPostCharge(VendorNo: Code[20]; ItemChargeNo: Code[20]; ChargeAmount: Decimal; ReceiptNos: List of [Code[20]]; Method: Enum "Landed Cost Method"): Code[20]
procedure GetReceiptCost(ReceiptNo: Code[20]): Decimal
```

Rules for `AssignAndPostCharge`:

1. Create a purchase invoice for `VendorNo` with exactly one line: type `Charge (Item)`, number `ItemChargeNo`, quantity 1, direct unit cost `ChargeAmount`.
2. Distribute the whole charge across every item line of the posted purchase receipts in `ReceiptNos` — receipts in list order, lines within a receipt in ascending line number.
3. A line's weight is its received `Quantity` when `Method` is `"By Quantity"`, and its line amount — `Quantity` × `"Direct Unit Cost"` — when `Method` is `"By Amount"` (the graded receipts carry no discounts or partial postings, so "line amount" is unambiguous).
4. Every line's share is `ChargeAmount` × weight ÷ total weight, rounded to 0.01 — except the last line in processing order, which takes `ChargeAmount` minus the sum of all earlier shares, so the shares always total `ChargeAmount` exactly.
5. Post the invoice and return the posted purchase invoice number.
6. Each share must land on the item ledger entry its receipt created back when the receipt itself was posted, as an item charge value entry. Posting the charge creates no new item ledger entry — a solution that posts another receipt, writes the item's cost fields, or reaches the right totals through any journal fails.

Rule for `GetReceiptCost`:

7. Return the receipt's actual landed cost: the sum of `"Cost Amount (Actual)"` over the item ledger entries that receipt created.

Environment notes:

- Every receipt in `ReceiptNos` is fully received and invoiced before your code runs.
- The grading company has `"Ext. Doc. No. Mandatory"` switched off, so the invoice you build needs no `"Vendor Invoice No."` (setting one anyway is fine).
- Pick object IDs in 50100–50199 and reference other objects by name, never by ID.

## What the tests check

Two purchase orders of the same item — 3 pieces and 7 pieces in most tests, generated quantities in one — are posted with receive and invoice, your codeunit assigns a charge, and the tests `CalcFields` `"Cost Amount (Actual)"` on each receipt's item ledger entry. A 100.00 charge `"By Quantity"` must land 30.00 and 70.00 on the fixed pair, and a second test generates the quantities and recomputes the shares from rule 4 itself; `"By Amount"` is likewise graded twice — fixed line amounts 180.00 and 140.00 must split 56.25 and 43.75, and generated line amounts must split by rule 4 — so hardcoded share fractions fail both methods. A 10.05 charge `"By Quantity"` exercises the rounding remainder — 3.02 on the first receipt and 7.03 on the last, exactly as rule 4 dictates (rounding both shares independently gives 3.02 and 7.04 and fails) — and one receipt posted with two item lines of 3 and 7 pieces checks the same rule inside a single receipt: 3.02 on the first item line and the 7.03 remainder on the last in ascending line number, each as a value entry on that line's own item ledger entry. Further tests verify that the returned number is a posted purchase invoice for the vendor holding the charge line, that the item still owns exactly its two original item ledger entries with quantities 3 and 7, that each original entry gained a value entry carrying the item charge number and the exact share, and that `GetReceiptCost` reports the pure direct cost before any charge and the landed cost after — direct unit costs are generated, so hardcoded answers fail.

## Learn More

- [Use Item Charges to Account for Additional Trade Costs](https://learn.microsoft.com/en-us/dynamics365/business-central/payables-how-assign-item-charges) — what an item charge is, how assignment links it to posted receipts, and why no new item ledger entry appears.
- [Design Details: Inventory Posting](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-inventory-posting) — the split between quantity (item ledger entries) and value (value entries) that this task rides on.
- [Design Details: Inventory Valuation](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-inventory-valuation) — how `"Cost Amount (Actual)"` aggregates value entries into what inventory is worth.
