# Supermarket Checkout

Your retail customer's self-checkout needs a pricing brain: a plain price list, weekly multibuy offers ("3 for the price of 2"), and bulk breaks that reprice the whole line once a minimum quantity is reached — the same trio Business Central models with sales prices and line discounts, distilled into a kata.

Items are scanned one at a time, in whatever order the shopper unloads the basket, and the display shows a running total after every beep.

## Requirements

Create a **codeunit** named `"Checkout Pricing"` with five public procedures:

```al
procedure SetUnitPrice(ItemCode: Code[20]; UnitPrice: Decimal)
procedure SetMultibuyOffer(ItemCode: Code[20]; OfferQuantity: Integer; OfferPrice: Decimal)
procedure SetBulkPrice(ItemCode: Code[20]; MinimumQuantity: Integer; DiscountedUnitPrice: Decimal)
procedure Scan(ItemCode: Code[20])
procedure Total(): Decimal
```

Each grading test configures prices and deals, scans items, and reads `Total()` through **one** `"Checkout Pricing"` codeunit variable — whatever you keep inside the codeunit lives as long as that variable, and every test starts with a fresh one.

Pricing rules — all of them are graded:

1. An item with no deal costs its unit price times the scanned quantity.
2. A multibuy offer `SetMultibuyOffer(Item, N, P)` charges `P` for **every complete group** of `N` scanned units of that item; leftover units beyond the complete groups are charged at the unit price. A classic "3 for the price of 2" is simply `N = 3` with `P` set to twice the unit price.
3. A bulk break `SetBulkPrice(Item, M, D)` reprices **every unit — including the first** — at `D` once the scanned quantity reaches `M` or more; below `M`, all units cost the normal unit price.
4. Scans of the same item count together no matter how they are interleaved with other items — `MILK, BREAD, MILK, MILK` holds three milks.
5. `Total()` may be called at any time and any number of times: it prices the basket scanned so far and must not disturb later scans or later totals.
6. An empty basket totals `0`.
7. `Scan` of an item that has no configured unit price must raise an error with a message that contains the item's code and the text `no price` (lowercase).

What you may rely on — the tests never violate this:

- The unit price of an item is always configured before any deal for it and before it is scanned.
- Prices are positive with at most 2 decimal places; `OfferQuantity` and `MinimumQuantity` are at least `2`.
- An item carries **at most one** deal — never both a multibuy offer and a bulk break.
- No rounding is involved: every expected total is an exact sum of the configured prices.

Worked example: `BREAD` at `1.15`; `MILK` at `0.85` with a multibuy of 3 for `2.00`; `SUGAR` at `2.00` with a bulk break from 5 units at `1.70`. Scanning `MILK, BREAD, MILK, MILK, MILK` totals `4.00` — one complete milk group at `2.00`, the fourth milk at `0.85`, plus the bread. Scanning `SUGAR` five times totals `8.50` — not `9.70`: the bulk price reaches back and reprices the first four units too.

## What the tests check

The tests price a single scan and a plain multi-item basket; a complete multibuy group, a quantity below the offer, and a quantity spanning two groups plus a remainder; offer groups formed from interleaved scans; a bulk break one unit below its minimum and exactly at it; a running total read mid-basket and again after more scans; an empty basket; the `no price` error for an unknown item (checked via the expected error text); and one randomized basket combining all three deal shapes whose expected total the test computes independently — so neither hardcoding the examples nor pricing at scan time passes.

## Learn More

- [Codeunit data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-data-type)
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type)
- [Dictionary.Set method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-set-tkey-tvalue-method)
- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type)
- [Dialog.Error method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method)
