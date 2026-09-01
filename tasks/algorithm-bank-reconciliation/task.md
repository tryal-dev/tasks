# Match the Bank Statement

The bank statement for March just arrived, and the accountant is staring at two columns: what the bank says happened, and what the bank account ledger says happened. Amounts agree, but the dates rarely do — the bank booked the wire two days after you posted it. Business Central's payment reconciliation journal solves this with automatic matching; your job is that auto-match in miniature: pair statement lines with ledger entries by amount and date tolerance, deterministically, and report what matched and what didn't.

## Requirements

Create a **codeunit** named `"Bank Statement Matcher"` with one public procedure:

```al
procedure MatchStatement(LineAmounts: List of [Decimal]; LineDates: List of [Date]; EntryAmounts: List of [Decimal]; EntryDates: List of [Date]; ToleranceDays: Integer; var UnmatchedEntries: List of [Integer]): List of [Integer]
```

Position `i` of `LineAmounts` and `LineDates` together describe statement line `i`; position `j` of `EntryAmounts` and `EntryDates` together describe bank account ledger entry `j`. Positions are 1-based, like AL list indexes, and "entry number" below always means that position.

What you may rely on — the tests never violate this:

- `LineAmounts` and `LineDates` have the same count, and so do `EntryAmounts` and `EntryDates`. Either side may be empty.
- `ToleranceDays` is `>= 0`.
- Amounts can be negative — outgoing payments appear on the statement too.

The matching contract — every rule is graded:

1. Entry `j` is a **candidate** for line `i` when the amounts are exactly equal (sign included: a deposit never matches a payment) and the dates differ by at most `ToleranceDays` days in either direction — the boundary is inclusive.
2. Matching is **one-to-one**: once an entry is matched to a line, it is consumed and no later line may take it.
3. Lines are processed **in statement order**, line 1 first. Each line takes its best available candidate immediately, even if that leaves a later line with nothing — no global optimization. (That is exactly how BC's auto-match behaves: one line at a time.)
4. The **best** available candidate is the one with the smallest date distance; on a tie, the one with the earliest entry date; if still tied, the one with the lowest entry number.

What the procedure reports:

- The **return value** contains exactly one integer per statement line, in statement order: the matched entry number, or `0` if the line has no available candidate.
- `UnmatchedEntries` must first be cleared of whatever the caller passed in, then filled with the entry numbers that no line matched, in ascending order.

## What the tests check

The tests call `MatchStatement` on fixed scenarios that check every rule: an exact match at zero tolerance, matches exactly at the tolerance boundary on both sides, a date one day beyond tolerance, an amount off by one cent, opposite signs, an entry wanted by two lines, a nearer-dated entry beating a farther one, a distance tie resolved by earlier entry date, a full tie resolved by lowest entry number, a greedy scenario where line order beats global optimization, an empty entry list, an empty statement against entries that must all come back unmatched, and a report scenario that pre-fills `UnmatchedEntries` with garbage to verify clearing and ascending order. One test shuffles a randomized statement against randomized entries, so hardcoding the fixed examples fails. Amount comparisons are exact, and the return list's length is checked on every call.

## Learn More

- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
- [List.Get method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-get-integer-t-method)
- [List.Add method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-add-method)
- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type)
- [Working with AL methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods)
