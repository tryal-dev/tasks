# Top 5 Entries by Amount

The sales team runs a quarterly contest: every closed deal is logged in a small custom table, and a Role Center tile is supposed to show the five biggest deals of the quarter. Right now the tile shows the five *oldest* deals instead — the records simply come back in entry-number order, and nothing ever lines them up by amount.

## Requirements

The starter contains two files — submit both:

- the table `"Sales Contest Entry"` with the fields `"Entry No."` (the primary key), `Description` and `Amount` — leave its name, fields and keys unchanged; the grading tests seed it and read it by name;
- the codeunit `"Sales Contest Leaderboard"`, whose single procedure you implement:

```al
procedure GetTopFiveEntryNos(): List of [Integer]
```

Rules:

1. Return the `"Entry No."` values of the five entries with the largest `Amount`, largest amount first.
2. When two entries have the same `Amount`, the newer entry — the one with the higher `"Entry No."` — ranks first.
3. The tie rule also decides who makes the list at all: when the fifth-largest amount is shared by two entries, the newer one takes the last spot and the older one is off the board.
4. When the table holds fewer than five entries, return all of them, under the same ordering rules.
5. When the table is empty, return an empty list — the procedure never raises an error.
6. `Amount` can be zero or negative; such entries rank like any other value.

## What the tests check

Each grading test empties the table, seeds its own entries with known entry numbers (the amounts are generated at run time in some tests, so the answers can't be hardcoded), calls `GetTopFiveEntryNos` and compares your list against the expected one as a whole — the values *and* their order. One test seeds eight entries and expects exactly five back; one seeds three; one seeds none; one puts three equal amounts inside the top five; one makes fifth place itself a tie. A failing test prints both lists in full, so you can see exactly what your code returned.

## Learn More

- [Record.SetCurrentKey Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method)
- [Record.Ascending Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-ascending-method)
- [Table keys](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys)
- [Record.FindSet Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method)
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
