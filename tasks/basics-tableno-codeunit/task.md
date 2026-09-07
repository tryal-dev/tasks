# Rec, Meet OnRun

Sales wants every newly onboarded customer to leave the onboarding step with a welcome note on the card and, when nobody has chosen payment terms yet, the introductory `WELCOME` terms. The same logic is needed from two very different callers: an action on the Customer Card that simply runs a codeunit against the current record, and an import job that holds a codeunit variable and calls a procedure on it. Business Central has a documented shape for exactly that: a codeunit bound to a table through its `TableNo` property, whose `OnRun` trigger does nothing but hand its record to a public procedure.

Setting `TableNo` changes the signature of `OnRun` without you writing it: the trigger receives a `var` record of that table under the name `Rec`. When a caller runs the codeunit with a record — `Codeunit.Run(Codeunit::"Customer Welcome", Customer)` — that `Rec` is the caller's own variable, passed by reference, so every field the codeunit changes on `Rec` is visible to the caller the moment the call returns, with no database write involved. Run the codeunit with a record from any other table and the platform refuses at run time. The tests deliberately do not capture the return value of `Codeunit.Run`: `if Codeunit.Run(...) then` would commit the transaction, and grading runs inside one that is rolled back.

## Requirements

1. Create a **table extension** that extends the `Customer` table with a field named `"Welcome Note"` of type `Text[250]`. The starter already declares it; keep the name exactly.
2. Create a **codeunit** named `"Customer Welcome"` bound to the `Customer` table through its `TableNo` property, with one public procedure:

```al
procedure Apply(var Customer: Record Customer)
```

3. The codeunit's `OnRun` trigger hands its `Rec` to `Apply` and does nothing else, so the two entry points — `Codeunit.Run(Codeunit::"Customer Welcome", Customer)` and `Welcome.Apply(Customer)` — behave identically.

Rules for `Apply`:

1. `"Welcome Note"` becomes the text `Welcome aboard, ` followed by the customer's `Name` and an exclamation mark — for a customer named `Northwind Traders` that is exactly `Welcome aboard, Northwind Traders!`. It is written every time, whatever the field held before.
2. When `"Payment Terms Code"` is blank, it becomes `WELCOME`. A customer who already has a payment terms code keeps it. The tests make sure a payment terms record with code `WELCOME` exists, so validating the field is as safe as assigning it.
3. `Apply` changes only the record it was handed, in memory. It must not call `Modify` or `Insert` — whether and when the changes are saved is the caller's decision.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The grading tests create customers through the standard test library, set a known `Name`, blank out `"Payment Terms Code"` and `"Welcome Note"` on the stored row, sometimes pre-fill one of those fields on the record in memory, and then drive your codeunit through both entry points. Through `Apply` they check that the caller's record carries the exact note for a fixed name and for a generated one (mind the comma, the space and the exclamation mark), that a `"Welcome Note"` that already held other text is overwritten with the new note, that a blank `"Payment Terms Code"` becomes `WELCOME` while an existing code is kept, and that the customer's row in the database is still untouched afterwards — a `Modify` inside `Apply` fails that test. Through `Codeunit.Run(Codeunit::"Customer Welcome", Customer)`, return value not captured, they check that the caller's own `Customer` variable shows the note and the payment terms afterwards, that an existing code is kept on this path too, and that the stored row is still untouched on this path as well — a `Modify` in `OnRun` fails that test just as one in `Apply` does; a codeunit whose `OnRun` works on a copy of `Rec`, or whose `Apply` takes the record by value, passes nothing back and fails here. One test reads the codeunit's `TableNo` from the `"CodeUnit Metadata"` table and expects the `Customer` table, one runs the codeunit with an `Item` record and expects the platform's own refusal, whose message contains `is not compatible with Codeunit.Run`, and one checks that `"Welcome Note"` is declared with a maximum length of exactly 250.

## Learn More

- [TableNo property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tableno-property) — how the property gives `OnRun` its implicit `var Rec` parameter.
- [Codeunit object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object) — the official example of a codeunit usable both through `Codeunit.Run` and through a procedure call.
- [Codeunit.Run(Integer [, var Record]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-integer-table-method) — running a codeunit with a record, the run-time error for a record from another table, and why capturing the return value commits.
- [OnRun (Codeunit) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/devenv-onrun-codeunit-trigger) — the trigger that runs when a codeunit is run.
