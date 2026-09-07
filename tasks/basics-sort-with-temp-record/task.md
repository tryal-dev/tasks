# Sort It Like AL Does

The sales dashboard shows customers ranked by a score the analytics team computes overnight. The scores land in your code as a `Dictionary of [Code[20], Decimal]` — and that is where the trouble starts: a dictionary has no order, and `List` has no `Sort` method. In AL you sort a collection the way the platform sorts everything else: pour the values into a temporary record, let a key put them in order, and read them back.

Here is the mechanism at work. A table declared with `TableType = Temporary` never touches the database — its rows live in memory for as long as the record variable does — yet it behaves like any other record: you `Insert` rows, `SetCurrentKey` picks the key to sort by, and `FindSet` with `Next` walks the rows in that key's order. The primary key is a key like any other, so a ranking needs a secondary key on the field you rank by. Two traps are worth knowing before you start. `Ascending(false)` reverses the **whole** current key, tiebreaker included, so two customers with the same score would come out with the higher customer number first; `SetAscending` flips a single field of the current key while the others keep sorting ascending. And a buffer declared as a codeunit global keeps its rows from one call to the next: the next call either trips over the old rows with "already exists" or silently ranks customers nobody asked about.

## Requirements

The starter contains two objects. Keep their names and the procedure signature exactly as they are.

A **table** named `"Customer Score Buffer"`, declared `TableType = Temporary`, with the fields `"Customer No."` (`Code[20]`, the primary key) and `Score` (`Decimal`). Add a **secondary key** on `Score, "Customer No."` — both fields, in that order.

A **codeunit** named `"Customer Ranker"` with one public procedure:

```al
procedure RankCustomers(Scores: Dictionary of [Code[20], Decimal]): List of [Code[20]]
```

Rules:

1. The result holds every key of `Scores` exactly once, ordered by score from highest to lowest.
2. Customers with the same score are ordered by customer number, ascending.
3. Zero and negative scores are ordinary scores: they rank below every positive score and among themselves by value, so `0` comes before `-0.01`, which comes before `-5`. No score is skipped.
4. An empty dictionary yields an empty list and must not raise an error.
5. Every call ranks exactly the customers passed to that call, however many times `RankCustomers` has already run on the same `"Customer Ranker"` instance — with the same customers or with different ones. Nothing from an earlier call may show up, and repeating a call must not fail.
6. The ranking is produced by reading the buffer table in the order of its `Score, "Customer No."` key — the tests check that the key is declared.

Pick your object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests call `RankCustomers` and compare the returned customer numbers, joined with commas, against the exact expected sequence, so a wrong order, a lost customer or an extra one is visible in the failure message. They rank three fixed scores added in non-sorted order, rank nine generated scores and compare with an independent sort of the same dictionary, rank three customers sharing one score between a higher and a lower one and expect them in ascending customer number, rank a mix of positive, zero and negative scores, rank an empty dictionary and expect a list with zero entries, call one `"Customer Ranker"` instance twice with the same scores expecting the second call to succeed with the same ranking, and call one instance with three customers and then with two others expecting only the two. A final test reads the key definitions of `"Customer Score Buffer"` at run time and fails with a message saying so when no key starts with `Score, "Customer No."`.

## Learn More

- [Temporary tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables) — what `TableType = Temporary` gives you and how temporary records behave like any other record.
- [Record.SetCurrentKey method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method) — how the key you name becomes the order the rows are read in.
- [Record.SetAscending method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setascending-method) — descending on one field of the current key while the rest stay ascending.
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — iterating the keys of the dictionary you are handed.
