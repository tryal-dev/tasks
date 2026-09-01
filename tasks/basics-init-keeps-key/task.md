# Init Doesn't Touch the Key

Field technicians upload their meter readings in batches, and the importer that writes them into the `"Meter Reading"` table has two open support tickets. Ticket one: rows come out carrying the remark of the row *before* them. Ticket two: the second upload of the day dies with "already exists". Both come from the same habit — the importer fills one record variable in a loop and never resets it between rows.

The fix is a single method, as long as you know exactly what it does. `Record.Init` resets every **non-key** field to its default: the field's `InitValue` if it declares one, otherwise the type's empty value (`''`, `0`, `0D`, an enum's ordinal 0). It leaves the **primary-key** fields (and the row's `timestamp`) exactly as they are. So one `Init` per row hands you a clean `Remark`, a blank `"Read On"` and — once the field declares it — a `Status` of `Pending`, but the `"Entry No."` of the previous row is still sitting in the variable: assigning the next number is your job, on every row. (Defaults stamped in an `OnInsert` trigger work differently: they arrive only at insert time, while an `InitValue` is already in the record the moment `Init` returns.)

## Requirements

The starter ships the enum, the table and the buggy importer. Fix them so that:

1. Enum `"Meter Reading Status"` keeps its values: `" "` (blank) at ordinal 0, `Pending` at 1, `Verified` at 2. The ordinals are graded — the blank value at 0 is what a zeroed record falls back to, which is exactly why `Pending` needs `InitValue`.
2. Table `"Meter Reading"` has these fields: `"Entry No."` (`Integer`, the primary key), `"Reading Value"` (`Decimal`), `Status` (`Enum "Meter Reading Status"`), `Remark` (`Text[50]`), `"Read On"` (`Date`). Declare `InitValue = Pending` on `Status`, so that `Init` alone yields a `Pending` row.
3. Codeunit `"Meter Reading Import"` keeps the procedure:

```al
procedure Import(Values: List of [Decimal]; ReadOn: Date)
```

It inserts one `"Meter Reading"` row per element of `Values`, in list order:

- `"Entry No."` continues from the highest number already in the table: an empty table starts at 1; if the highest existing number is 9, the new rows get 10, 11, and so on. A second call continues where the first stopped — it never restarts at 1.
- `"Reading Value"` is the element; `"Read On"` is `ReadOn`.
- `Status` is `Pending` on every row — supplied by the field's `InitValue` through `Init`, not assigned in the loop.
- `Remark` is exactly `Suspect reading` when the value is zero or less, and blank otherwise. A remark set on one row must never carry over to the rows after it.
- An empty list inserts nothing and raises no error.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The grading tests work on an empty `"Meter Reading"` table with generated decimals and an explicit `ReadOn` date. They import three positive values and expect rows 1, 2, 3 carrying the values in list order and the date; import `0.01`, `0` and a negative value and expect the remark on the second and third row only; import a positive, a zero and a positive value and expect the third row's `Remark` to be blank; call `Init` on a bare record and expect `Status = Pending`, and check that every imported row is `Pending`; seed rows 4 and 9 by hand and expect two imported values to land on 10 and 11; import three values and then two more and expect the second call to produce rows 4 and 5; import an empty list and expect zero rows; and check the enum ordinals 0, 1, 2. The unchanged starter fails the remark-leak test, both `Pending` tests and both numbering tests.

## Learn More

- [Record.Init() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method) — the default-value table, the note that primary key and timestamp fields are not initialized, and the paragraph about refreshing a variable inside a loop.
- [InitValue property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property) — the field property that `Init` applies instead of the type's zero value.
- [Record.FindLast() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findlast-method) — reading the highest `"Entry No."` before the loop.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the `Values` parameter; `foreach` walks it in order.
