# Filter Safely on Hostile Names

Support escalated a ticket this morning: the customer-search feature crashes the moment someone looks up **O'Brien & Sons**. Last week it was worse — a search containing a `|` quietly matched customers it should never have matched. The root cause is the same in both cases: user-typed text is being pasted straight into a record filter, and filter strings are a little query language of their own.

Your job is a search codeunit that treats user input as *data*, not as filter syntax.

## Requirements

Create a **codeunit** named `"Customer Name Search"` with two public procedures:

```al
procedure CountExactName(NameToFind: Text): Integer
procedure CountNamesContaining(Fragment: Text): Integer
```

Rules:

1. `CountExactName` returns how many `Customer` records have a `Name` equal to `NameToFind`, **every character taken literally** — apostrophes, `&`, `|`, `*`, `?`, `..`, parentheses and the rest included. Two customers sharing that exact name count as 2. Near misses (a name that merely starts the same way, or that a wildcard would catch) must not count.
2. `CountNamesContaining` returns how many `Customer` records contain `Fragment` anywhere in their `Name`, **ignoring case** — searching for `o'brien & sons` finds a customer named `O'Brien & Sons Ltd`.
3. `Fragment` is never empty and never contains `*` or `?`. Everything else is fair game: apostrophes, `&`, `|`, `(`, `)`, `=`.
4. Neither procedure may raise an error, whatever the input contains. A search that finds nothing returns 0.

## What the tests check

The grading tests seed customers with names like `O'Brien & Sons`, `Import|Export`, `Star* Retail`, `Hans?n Shipping` and `10..20 Storage`, next to near-miss decoys such as `Starfish Retail` and `Hansen Shipping`, and assert **exact counts** — an implementation that over-matches, under-matches, or dies with a filter syntax error fails the corresponding test. One test gives two customers the identical name and expects 2; others search for a name or fragment that no customer has and expect 0. The contains tests place the fragment at the start, in the middle and at the end of the name — and one fragment is the entire name. The tests run in a real company, so extra customers exist — the seeded names carry unique markers, and your counts must be driven purely by the name matching described above.

## Learn More

- [Entering criteria in filters](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters)
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method)
- [Record.SetFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method)
- [Record.Count Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-count-method)
