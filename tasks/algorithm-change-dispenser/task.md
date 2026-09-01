# Fewest Coins

The self-checkout at your retail customer dispenses change from a coin hopper, and every coin it hands out is a coin someone has to refill — the hardware team wants change made with as few coins as possible, whatever denominations happen to be loaded that day.

You are writing the dispenser's brain: given an amount and the loaded denominations, find the smallest number of coins that adds up exactly, or report that the amount cannot be made at all.

## Requirements

Create a **codeunit** named `"Change Dispenser"` with one public procedure:

```al
procedure FewestCoins(Amount: Integer; Denominations: List of [Integer]): List of [Integer]
```

What you may rely on — the tests never violate this:

- `Amount` is in the smallest currency unit (cents), between `0` and `999`.
- `Denominations` contains at least one entry; every denomination is `>= 1`, they are all distinct, and they arrive in **no particular order**.

What the returned list must guarantee — all of it is graded:

1. Every value in the list is one of the given denominations, and the values sum to exactly `Amount`.
2. The list holds the **fewest coins possible** — no combination of the given denominations reaches `Amount` with fewer coins.
3. The coins are sorted in **ascending** order.
4. An `Amount` of `0` returns an empty list.
5. If no combination of the denominations sums to `Amount`, the procedure must raise an error with a message that contains the text `impossible` (lowercase).

Examples: `FewestCoins(41, [1, 5, 10, 25])` = `[1, 5, 10, 25]`; `FewestCoins(63, [1, 5, 10, 21, 25])` = `[21, 21, 21]` — three coins, even though `25` fits first; `FewestCoins(3, [5, 10])` errors.

## What the tests check

The tests call `FewestCoins` and verify the coin count, the exact sum, the ascending order, and that every coin is a loaded denomination. They include an amount that equals a single denomination, an amount of zero, denominations passed in shuffled order, the `63` case above where grabbing the largest coin that fits hands out too many coins, `27` from `[4, 5]` where the largest coin leads to a dead end that a correct answer must avoid, two impossible amounts checked via the expected error, one randomized amount against standard coins whose minimal coin count the test computes independently, and one randomized non-standard denomination set built so that grabbing the largest coin that fits is never the fewest — so neither hardcoding nor pattern-matching the examples passes.

## Learn More

- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type)
- [Dictionary.ContainsKey method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-containskey-method)
- [Dialog.Error method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method)
