# Only This Item's Variants

An item can have variants — colours, sizes, pack sizes — and a stock count line that names an item must only ever carry one of *that* item's variants, never a variant that happens to exist under another item. Elsewhere, a customer's sales region must be one that is still open for business. Both rules are a single property each in Business Central: a **table relation with a filter**. The catch, and the point of this task, is *when* that property is enforced.

## Requirements

The starter contains three objects. Keep every object name, field name, type and key exactly as they are — you add relations and one trigger.

- `table "Sales Region"` with `Code` (`Code[10]`), `Description` (`Text[50]`) and `Blocked` (`Boolean`). It is complete; leave it alone.
- `table "Stock Count Line"` with `"Document No."` (`Code[20]`), `"Line No."` (`Integer`), `"Item No."` (`Code[20]`, already related to `Item`), `"Variant Code"` (`Code[10]`) and `"Counted Quantity"` (`Decimal`). The primary key is `"Document No."` + `"Line No."`.
- `tableextension "Customer Region" extends Customer` with `"Region Code"` (`Code[10]`).

Rules:

1. `"Variant Code"` relates to the `Code` field of the `"Item Variant"` table, restricted to the variants whose `"Item No."` equals the line's **own** `"Item No."`. Validating it with a variant of the line's item succeeds; validating it with a variant that exists under a *different* item must fail with the platform's own relation error.
2. A **blank** `"Variant Code"` is always accepted — a blank value never reaches the relation check.
3. Validating `"Item No."` with an item **different** from the one the line already carries blanks `"Variant Code"` — the old variant belongs to the old item. Validating `"Item No."` with the item it already has leaves `"Variant Code"` alone.
4. `"Region Code"` relates to `"Sales Region"`, restricted to the regions whose `Blocked` is `false`. A region that is not blocked is accepted; a blocked region and a code that no region carries must both fail with the platform's own relation error.
5. Neither relation is enforced outside `Validate`. Assigning a value directly to the field and calling `Modify` stores it whatever it is — another item's variant on the line, a blocked region on the customer. Do **not** add triggers that try to close this hole: the tests assert it stays open, with `Modify(true)` so table triggers run.

Worth knowing before you start:

- A filter in a table relation comes in two flavours: the related field compared with a **constant**, or compared with a **field of the record being validated**. The second flavour is evaluated against the value the record holds at the moment of validation — so it is the line's current `"Item No."` that decides which variants are in range.
- The relation check runs **before** the field's `OnValidate` trigger, and only as part of `Validate`. Inside the trigger the value has already passed.
- `xRec` inside a field's `OnValidate` trigger holds the record as it was before the new value was assigned. That is how rule 3 tells a real change from a re-validation.
- Dead ends: an existence check you write by hand in `OnValidate` raises a different message than the relation does, and the tests look for the platform's wording. A relation to `"Item Variant"` that does not name the `Code` field is matched against the wrong field, so the line's own variants are refused.

Pick object and field IDs in the range **50100–50199**, and reference other objects **by name, never by ID**. Captions are good practice but not graded.

## What the tests check

The grading tests drive the tables with `Validate` — no page is involved. They create items and variants through the standard test library, so every code is generated. One test validates `"Variant Code"` with a variant of the line's own item and expects it kept; another hands the line a variant that exists under a different item and expects the failure to come from the relation itself: the error text must contain `cannot be found in the related table` — the platform's own wording — and name `Item Variant`. A hand-written existence check fails that test because its message reads differently, and so does a relation without the item filter, because the foreign variant does exist. A blank `"Variant Code"` must be accepted. Two tests store a line with an item and a variant, re-read it, then validate `"Item No."`: with a different item (`"Variant Code"` must be blank afterwards) and with the same item (it must survive). On the customer, a `"Sales Region"` that is not blocked must be accepted by `"Region Code"`, while a blocked region and a generated code no region carries must both fail with the same relation wording, naming `Sales Region`. Two tests assign a value the relation would refuse — another item's variant on a line, a blocked region on a customer — with a plain assignment and `Modify(true)`, read the record back, and expect the value stored with no error. Finally the `Field` virtual table must report `"Variant Code"` as related to the `Code` field of `Item Variant`, and `"Region Code"` as related to `Sales Region`.

## Learn More

- [TableRelation property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property) — the full syntax, including the `where` filter and both filter flavours.
- [Setting relationships between tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-set-relationships-between-tables) — what a relation is for, and why it may only point at a primary-key field.
- [OnValidate (Field) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/field/devenv-onvalidate-field-trigger) — where the clearing rule belongs, and what has already been checked by the time it runs.
- [Record.Validate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method) — the call that triggers the relation check, as opposed to a plain assignment.
