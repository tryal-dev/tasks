# No Cent Left Behind

Finance rejected a posting this morning because it did not balance: an invoice-level charge of 0.99 was spread over six lines, each line got its proportional share rounded to the cent — and the six line amounts added up to 1.02. Three phantom cents, invented by rounding. Business Central faces this exact problem every time it distributes VAT or an invoice discount across lines, and it always closes the books to the cent.

Your job is that allocation algorithm in miniature: split a total across lines in proportion to their weights so that the rounded line amounts add up to exactly the total, with no line drifting more than a cent from its fair share.

## Requirements

Create a **codeunit** named `"Penny Allocator"` with one public procedure:

```al
procedure Allocate(TotalAmount: Decimal; Weights: List of [Decimal]): List of [Decimal]
```

What you may rely on — the tests never violate this:

- `TotalAmount` is always an exact multiple of 0.01. It can be positive or negative — credit memos allocate too.
- `Weights` contains at least one entry, every weight is `>= 0`, and at least one weight is `> 0`. Weights are not necessarily whole numbers and do not sum to anything special.

What the returned list must guarantee — all four are graded:

1. Exactly one amount per weight, in the same order: the amount at position `i` belongs to the weight at position `i`.
2. Every amount is an exact multiple of 0.01.
3. The amounts sum to exactly `TotalAmount` — not a cent more, not a cent less.
4. Every amount differs from its line's exact share — `TotalAmount` × `Weight` ÷ (sum of all `Weights`) — by strictly less than 0.01.

Guarantee 4 has teeth: a line with weight 0 must get exactly 0.00, a line whose exact share is already a whole number of cents must get exactly that share, and dumping the whole rounding difference on a single line fails the moment the drift exceeds one cent. More than one classic strategy satisfies all four guarantees — any of them passes.

## What the tests check

The tests call `Allocate` and verify all four guarantees on fixed cases — a single line, weights that divide evenly, the classic three-way split of 100.00, 0.03 across two equal lines, 0.99 across six equal lines where every exact share ends in half a cent, a zero-weight line, and a negative credit-memo total — plus one invoice with a randomized total and weights, so hardcoding the examples fails. Sum comparisons are exact, and the per-line drift check is strict (`< 0.01`).

## Learn More

- [System.Round(Decimal [, Decimal] [, Text]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method)
- [Decimal data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type)
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
- [System.Abs(Decimal) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-abs-method)
