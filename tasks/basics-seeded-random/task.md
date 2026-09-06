# A Raffle You Can Replay

Marketing runs a monthly raffle among the customers who left a review, and last month's draw ended in an argument: nobody could prove that the names on the winners' mailing had really come out of the hat. This time the draw takes a **seed** — an integer written into the minutes — so that anyone with the same list of entrants and the same seed can replay the draw and get the same winners.

AL gives you both halves. `Randomize(Seed)` restarts the session's random number generator from a seed, and the same seed always restarts the same sequence. `Random(N)` hands out the next number of that sequence as a whole number from `1` to `N` — never `0` — which makes it directly usable as a 1-based list position.

## Requirements

Create a **codeunit** named `"Raffle Draw"` with one public procedure:

```al
procedure DrawWinners(Seed: Integer; Entrants: List of [Code[20]]; Count: Integer): List of [Code[20]]
```

`Entrants` never contains the same code twice, and `Count` is never negative.

The draw procedure — the tests replay it step by step, so follow it exactly:

1. Call `Randomize(Seed)` **once**, before the first pick — not before every pick.
2. Draw from a **working copy** of `Entrants` (the pool), in the same order as the caller's list. The caller's list must be exactly as it was after the draw: a `List` is a reference type, so removing from the parameter removes from the caller's list.
3. While winners are still needed and the pool is not empty: let `N` be the number of entrants still in the pool, call `Random(N)` once and use the number as a **position** (1-based) in the pool. The entrant at that position is the next winner — append it to the result and remove it from the pool, so the entrants behind it move down one position and nobody can win twice.
4. When `Count` is greater than or equal to the number of entrants, every entrant ends up a winner, in the order drawn. A `Count` of `0` or an empty `Entrants` list gives an empty result. None of these cases raises an error.

Two dead ends worth knowing. `Random(N) - 1` is not a way to get a 0-based index: `Random(1)` is always `1`, so the last pick of a full draw lands on position `0`, which is not a valid list index. `Random(N - 1)` does not fail either — `Random(0)` is documented to return `1` — but it can never pick the last entrant left in the pool, and the replay test catches that.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests build small entrant lists (one to ten generated codes) and generated seeds, then: draw twice with the same seed and expect the same winners in the same order; draw all ten entrants with two different seeds and expect the two orders to differ somewhere; draw fewer winners than entrants and check that every winner is a distinct entrant; ask for exactly as many and for more winners than there are entrants and expect every entrant exactly once, with no error; draw from a single entrant and expect that entrant; pass a `Count` of `0` and an empty entrant list and expect an empty result; check that the caller's list is untouched after a draw; and replay the draw procedure above step by step with the same seed and compare the exact winner sequence — reseeding before every pick, positions off by one, or picking from the full list instead of the shrinking pool all produce a different sequence and fail that test. Failure messages show the winners joined by commas.

## Learn More

- [System.Randomize([Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-randomize-method) — the same seed restarts the same sequence, per connection.
- [System.Random(Integer) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-random-method) — the range is 1 to MaxNumber, and Random(0) returns 1.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — lists are 1-based reference types; the remarks show how to copy one.
- [List.RemoveAt(Integer) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-removeat-method) — removing a winner by position from the pool.
