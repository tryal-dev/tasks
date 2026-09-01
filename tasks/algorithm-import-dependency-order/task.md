# Import in the Right Order

Your team applies a RapidStart configuration package to every new company, and it keeps blowing up halfway through: Customer lines fail because their Payment Terms are not in yet, Items fail on missing Item Categories, and someone reorders the package tables by hand until it sticks. You are building the planner that computes a correct apply order once and for all.

## Requirements

Create a **codeunit** named `"Import Order Planner"` with exactly these three public procedures:

```al
procedure AddTable(TableID: Integer)
procedure AddDependency(TableID: Integer; DependsOnTableID: Integer)
procedure GetImportOrder(var ImportOrder: List of [Integer])
```

`AddTable` stages a table for import. Staging the same table ID again has no further effect.

`AddDependency` records that the records of `TableID` reference records of `DependsOnTableID` (a foreign key), so `DependsOnTableID` must be imported before `TableID`. Registering the same pair again has no further effect. By the time `GetImportOrder` is called, every table ID mentioned in a dependency pair has also been staged with `AddTable` — you do not need to handle unknown tables.

A pair where `TableID = DependsOnTableID` is legal — think of Item Category's Parent Category field — and imposes no ordering constraint: a table never waits for itself.

`GetImportOrder` first empties whatever is in `ImportOrder`, then fills it with every staged table exactly once, so that:

1. For every dependency pair, `DependsOnTableID` appears before `TableID`.
2. Whenever more than one staged table could legally come next, the one with the **lowest table ID** comes first. This makes the order fully deterministic.
3. With no tables staged, the result is an empty list.

If at some point no remaining table can legally come next — a circular dependency — `GetImportOrder` must fail with exactly this error message:

```
No valid import order exists. Tables that cannot be imported: 50111, 50113, 50115.
```

The list after the colon names every staged table that can never be imported — the tables in a cycle **plus** every table whose dependency chain leads into one — in ascending table ID order, separated by a comma and one space, with a period at the end. Tables unaffected by the cycle must not appear in the list.

State lives in your codeunit's instance variables; each grading test uses a fresh planner variable, so no reset procedure is needed. The planner works on plain integers — do not create or read any database tables.

## What the tests check

The tests stage small dependency graphs and compare the full order returned by `GetImportOrder`, element for element: a single table, independent tables (must come out in ascending table ID order), a parent staged after its child, a case where the lowest-ID table must wait while higher-ID tables go first, a self-referencing table, and duplicate `AddTable`/`AddDependency` calls (each table exactly once). One test builds a dependency chain over randomly generated table IDs, so hardcoding the fixed examples fails. Two tests build cycles and compare the error message exactly — including that a table stuck behind a cycle is named and an importable table is not. One test passes a non-empty list to `GetImportOrder` with nothing staged and expects it to come back empty.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## Learn More

- [Set up company configuration packages](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/set-up-standard-company-configuration-packages) — the RapidStart machinery this planner exists for.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the collection type in the promised signature, and a reference type: assigning a list copies the reference, not the list.
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — handy for keeping the dependency pairs queryable by table.
