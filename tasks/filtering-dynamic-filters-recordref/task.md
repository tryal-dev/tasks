# Dynamic Filters from Configuration Rows

Your customer's cleanup job must be configurable: an administrator decides which records the job touches by entering condition rows — a table, a field, an operator and a value — without anyone redeploying code. Those rows are plain data; your engine has to turn them into real filters at runtime, for any table, without knowing at compile time which table or which field a row points at.

## Requirements

The starter ships two finished objects — keep them in your submission exactly as they are, because the tests use them to feed your engine:

- Enum `"Dynamic Filter Operator"` with the values `Equals`, `"At Least"` and `"At Most"`.
- Table `"Dynamic Filter Line"` with the fields `"Entry No."` (Integer, primary key), `"Table ID"` (Integer), `"Field No."` (Integer), `Operator` (the enum above) and `"Filter Value"` (Text[250]).

Complete the **codeunit** named `"Dynamic Filter Engine"` with this public procedure:

```al
procedure CountWithConfiguredFilters(TableId: Integer; var AppliedFilters: Text): Integer
```

Rules:

1. The procedure opens the table whose ID is `TableId` and applies every `"Dynamic Filter Line"` row whose `"Table ID"` equals `TableId`, in `"Entry No."` order. Rows configured for other tables are ignored entirely.
2. All applied rows combine: a record is counted only if it satisfies every condition. The return value is the number of records left after all conditions are applied; with no matching configuration rows it is the table's unfiltered record count.
3. `Equals` keeps records whose field is exactly equal to `"Filter Value"`; `"At Least"` keeps records whose field is greater than or equal to it; `"At Most"` keeps records whose field is less than or equal to it.
4. The configured fields are only ever of type Text, Code, Integer, Decimal or Date, and `"At Least"` / `"At Most"` are only ever configured on Integer, Decimal or Date fields. For those three types, `"Filter Value"` holds the value the way `Format` renders it and must be turned back into the field's own type before it can filter anything.
5. Every character of `"Filter Value"` is data, never filter syntax: a value containing `|`, `*`, `?`, `..`, `&`, `(` or `)` must match records literally — a `|` must not become either/or, a `*` must not become a wildcard, `..` must not become a range.
6. If a row's `"Field No."` does not exist in the target table, raise an error with exactly this message: `Field %1 does not exist in table %2.` — `%1` is the configured field number, `%2` is the table's name (for the customer table: `Customer`).
7. If a row's `"Filter Value"` cannot be turned into the type of an Integer, Decimal or Date field, raise an error with exactly this message: `Value '%1' is not valid for field %2.` — `%1` is the raw `"Filter Value"` text, `%2` is the field's name (for example `Credit Limit (LCY)`).
8. `AppliedFilters` returns the filter description the record itself produces once all conditions are applied — the text `GetFilters` yields; it must name the filtered fields and carry the filter values.

Pick object IDs in the 50100–50199 range (the starter already does) and reference other objects by name, never by ID.

## What the tests check

The tests insert `"Dynamic Filter Line"` rows and run your engine against two structurally different tables — `Customer` and `Item Ledger Entry` — so an implementation hardwired to one table cannot pass. They seed records with hostile names like `Import|Export`, `Star* Retail`, `10..20 Storage` and `Smith & Jones` next to near-miss decoys, and assert **exact counts** for `Equals`; they check the `"At Least"` / `"At Most"` boundaries as inclusive on Decimal and Date fields (the record exactly at the boundary counts); they combine several rows and expect all of them to apply; they configure a row for a different table and expect it to be ignored; with no rows they expect the unfiltered count. One test asserts `AppliedFilters` names the filtered fields and values. Two tests trigger the named errors from rules 6 and 7 and match the messages — note the wording, the quotes and the final period.

## Learn More

- [RecordRef Data Type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type) — the object that opens any table by its number at runtime.
- [FieldRef Data Type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-data-type) — a handle to a field whose identity and type are only known at runtime.
- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — how AL filtering methods differ and combine.
- [Entering criteria in filters](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters) — the filter expression language, and why characters like `|` and `..` are dangerous inside values.
