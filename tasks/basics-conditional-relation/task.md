# Point One Field at Three Tables

Every document line in Business Central works the same way: you pick a `Type`, and the `No.` next to it suddenly means something else — an item, a resource, a G/L account. One column, three tables. The wiring behind it is a **conditional table relation**, and it is what keeps a line from ever pointing at a record that does not exist.

You will build that wiring on an estimate line of your own.

## Requirements

Create a **table** named `"Estimate Line"` with these fields:

| Field | Type |
|---|---|
| `"Document No."` | `Code[20]` |
| `"Line No."` | `Integer` |
| `Type` | `Enum "Sales Line Type"` |
| `"No."` | `Code[20]` |
| `Description` | `Text[100]` |
| `"Catalog Ref."` | `Code[20]` |

The primary key is `"Document No."` + `"Line No."`. `Enum "Sales Line Type"` is the base enum that `Sales Line` itself uses — reuse it, don't define your own.

Rules:

1. `"No."` carries a **conditional** table relation: the value must exist in `Item` when `Type` is `Item`, in `Resource` when `Type` is `Resource`, and in `"G/L Account"` when `Type` is `"G/L Account"`. Validating `"No."` with a code the current `Type` cannot resolve must fail.
2. No other `Type` value gets a branch. While `Type` is blank, `"No."` therefore accepts **any** code — no condition holds, so there is nothing to check the value against.
3. When `"No."` resolves, the line copies its `Description` from the record it points at: the item's `Description`, the resource's `Name`, or the G/L account's `Name`.
4. Validating `"No."` with a **blank** value clears `Description` and must not raise an error. A blank value never reaches the relation check, so it lands in your own code untouched.
5. Validating `Type` with a value **different** from the one the line already carries blanks both `"No."` and `Description` — a line must never keep a code that belonged to the previous type. Validating `Type` with the value it already has leaves both fields alone.
6. `"Catalog Ref."` relates to `Item` as well, but that relation is **not validated**: the field accepts any code, including one no item carries. The relation itself stays on the field — only its validation is switched off.

Two things worth knowing before you start:

- The table relation is checked **before** your `OnValidate` trigger runs. Inside the trigger a non-blank `"No."` is therefore guaranteed to exist in the table `Type` points at — and a blank one was never checked at all.
- `xRec` inside a field's `OnValidate` trigger holds the record as it was before the new value was assigned. That is how rule 5 tells a real change from a re-validation.

Pick object and field IDs in the range **50100–50199**, and reference other objects **by name, never by ID**. Captions are good practice but not graded.

## What the tests check

The grading tests drive the table with `Validate` — no page is involved. They create an item, a resource and a G/L account whose description or name is **generated**, so a hardcoded text fails, and check that each type lands its own record's text in `Description`. They then hand a real item code to a line whose `Type` is `Resource` and expect the failure to come from the relation check itself: the error text must contain `cannot be found in the related table` — the platform's own wording when a table relation rejects a value — and name the `Resource` table. A plain relation to `Item` accepts that code and fails this test, and so does an existence check you write by hand in `OnValidate`, because its error reads differently. Codes that exist nowhere are checked the same way under `Type` `Item` and `"G/L Account"`. A line with a blank `Type` must accept a generated code, and blanking `"No."` on a filled line must clear `Description` without raising an error. Two tests fill a line, store and re-read it, then validate `Type`: with a different value (`"No."` and `Description` must be blank afterwards) and with the value it already has (both `"No."` and `Description` must survive). Finally `"Catalog Ref."` must accept a generated code that belongs to no item, while the `Field` virtual table must still report `Item` as the table it relates to.

## Worth knowing (not graded)

A `TableRelation` set from a **table extension** does not replace the base one: the two are combined and evaluated top-down, and the first *unconditional* relation prevails. You can add a branch for an enum value you extended in, but you can never narrow an existing unconditional relation — which is exactly why a base field meant to be extended gets a conditional relation from the start.

## Learn More

- [TableRelation property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property) — the full syntax, including the conditional form and the table-extension rule above.
- [ValidateTableRelation property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-validatetablerelation-property) — what switching validation off does, and what it leaves in place.
- [Setting relationships between tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-set-relationships-between-tables) — why a relation exists at all, with a two-branch conditional example.
- [OnValidate (Field) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/field/devenv-onvalidate-field-trigger) — where the defaulting and the clearing code belong.
