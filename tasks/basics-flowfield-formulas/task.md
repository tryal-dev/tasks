# A Lab Batch Header That Calculates Itself

The lab logs every measurement as a row in a reading table, and the batch card above it shows the summary: how many readings came in, their total, the lowest and the highest one, the average, whether the batch has any readings at all, and the name of the customer who ordered it. The readings are written and corrected by an import job that touches the reading table directly — nothing goes through the batch card — so any figure the header *stores* is wrong minutes after it was written. Design the header so its summary columns are descriptions of a calculation instead, and give the user a date window to narrow them with.

## Requirements

The starter already contains the `"Lab Batch Reading"` table — `"Batch No."`, `"Line No."`, `"Reading Date"`, `"Reading Value"`. The grading tests insert and delete those rows themselves, so leave the table's field names as they are.

Complete the table named `"Lab Batch Header"`. It starts out with two ordinary fields, `"Batch No."` (`Code[20]`, the primary key) and `"Customer No."` (`Code[20]`), and you add:

- `"Date Filter"` — a `Date` **flow filter**: never stored, set by the caller, and consumed by the calculated fields below.
- `"Has Readings"` — `Boolean`, true when the batch has at least one reading.
- `"No Readings"` — `Boolean`, the exact opposite of `"Has Readings"`.
- `"Reading Count"` — `Integer`, how many readings the batch has.
- `"Reading Total"` — `Decimal`, the signed sum of their `"Reading Value"`.
- `"Lowest Reading"` — `Decimal`, the smallest `"Reading Value"`.
- `"Highest Reading"` — `Decimal`, the largest `"Reading Value"`.
- `"Average Reading"` — `Decimal`, the mean `"Reading Value"`.
- `"Customer Name"` — `Text[100]`, the `Name` of the `Customer` identified by `"Customer No."`.

Rules:

1. All eight fields above are **FlowFields** — calculated on demand from the reading table (and from `Customer`), never maintained by code. The tests insert and delete readings with plain `Insert()` and `Delete()`, so no trigger of yours ever runs: a stored figure is stale the moment the next reading lands, and a recalculation after a direct delete must report the smaller figures.
2. Each of the seven reading-based fields sees only readings whose `"Batch No."` equals the header's own `"Batch No."`. A neighbouring batch's readings never leak in.
3. Each of those seven also honours `"Date Filter"`: only readings whose `"Reading Date"` lies inside that filter count. An empty `"Date Filter"` restricts nothing, so an unfiltered calculation covers the whole batch. `"Customer Name"` ignores the date filter.
4. A flow filter is a filter, not a value. `SetRange("Date Filter", FromDate, ToDate)` narrows the calculation; assigning a date to the field (`Header."Date Filter" := SomeDate`) compiles, filters nothing and leaves you with the unfiltered figure. The tests assert both halves of that, so an ordinary `Date` field pretending to be a flow filter fails.
5. Aggregating over no readings at all gives a normal answer, not an error: count, total, lowest, highest and average all come back as 0, `"Has Readings"` is false and `"No Readings"` is true.
6. Until they are calculated, FlowFields read as 0, false and blank — the tests read a header straight back from the database and expect exactly that before any `CalcFields` call.
7. `"Customer Name"` returns the customer's *current* name, so a name changed after the batch was created shows through. A blank `"Customer No."` yields a blank name rather than an error.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID. Captions and tooltips are good practice but are not graded.

## What the tests check

The grading tests build batches whose readings carry values generated at run time — hardcoded answers fail — and drive every field: exist and its negation in both directions, the count, the signed sum (a negative reading lowers it), the smallest and the largest value, the mean, and the looked-up customer name (calculated with a `"Date Filter"` window set, which it must ignore; the tests also cover a customer renamed after the batch was created and a header with no customer at all). Decoy readings sit in a neighbouring batch in most tests, so a formula that forgets to match on `"Batch No."` over-counts. One test deletes a reading straight from the table and recalculates, one reads a header back from the database and expects 0/false/blank before `CalcFields`, and two cover a batch with no readings at all. Three more drive the date window: a `SetRange` on `"Date Filter"` that must narrow the count, total, lowest, highest and average to the readings inside it; a window containing no readings, which must flip `"Has Readings"` to false and `"No Readings"` to true; and an *assignment* to `"Date Filter"`, which must change nothing at all. Averages are compared with a tolerance of 0.01; every other figure is compared exactly. The tests reach every field by its exact name at run time (a missing or misspelled field fails with a message saying so), and one structural test checks each field's declaration: `"Date Filter"` must have `FieldClass = FlowFilter` and type `Date`, the eight calculated fields must have `FieldClass = FlowField` with the types listed above, and `"Customer Name"` must be `Text[100]`.

## Learn More

- [FlowFields overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields) — the seven calculation types, and why a calculated value starts at 0.
- [FlowFilters overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfilter-overview) — how a filter set by the caller reaches a calculation.
- [CalcFormula property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property) — the full formula syntax, including the where clause and the forms its filters can take.
- [Record.CalcFields method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method) — how the tests ask for the values, and what a FlowField reads before they do.
