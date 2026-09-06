# The Key Has Two Parts

A colleague wired up a helper that looks up the description of an item variant, and it never finds anything: every call dies with *"The Item Variant does not exist. Identification fields and values: Item No.='BLUE',Code=''"*. Read that message slowly — it is the whole bug. The variant code landed in `"Item No."`, and `Code` was searched as blank.

`Record.Get` retrieves one row by its primary key, and it takes **one value per key field, in the order the key declares them**. The `Item Variant` table's primary key has two parts — `"Item No."` first, then `Code` — because a variant code such as `BLUE` is only unique together with its item: many items have a `BLUE`. `Get` does not insist on receiving every value: hand it fewer and each key field you left out is searched as its blank value, which is why the starter compiles cleanly and still finds nothing. Two more things to know: called as a plain statement, `Get` raises an error when the row is missing, while its Boolean return value lets you branch instead; and the order of the values matters — swap them and you are looking for a different row.

## Requirements

Create a **codeunit** named `"Variant Lookup"` with a public procedure:

```al
procedure VariantDescription(ItemNo: Code[20]; VariantCode: Code[10]): Text[100]
```

Rules:

1. Return the `Description` of the `Item Variant` whose `"Item No."` is `ItemNo` and whose `Code` is `VariantCode` — exactly as stored, in full.
2. The first argument is the item number and the second is the variant code. Passing them the other way round must look up a different row, not the same one.
3. If no such variant exists — the item has no variant with that code, or the item itself is unknown — return an empty string. The procedure must never raise an error.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

The starter reproduces the bug from the ticket. Fix it.

## What the tests check

The grading tests seed their own items and variants (item numbers start with `TRYAL-CK`; descriptions are generated) and call `VariantDescription` once per test. They ask an item with two variants, `BLUE` and `RED`, for one and then the other, and expect the matching description each time — one of those descriptions is exactly 100 characters long and must come back untruncated. They give the same variant code `BLUE` to two different items and expect the description stored on the item you asked for. They seed two items whose numbers double as each other's variant codes and expect the description filed under the first argument's item — a solution that swaps the arguments returns the other item's variant and fails. Finally, they ask an existing item for a variant code it does not have, and ask for a variant of an item that does not exist at all, and expect an empty string from both with no error raised. The unchanged starter fails every test.

## Learn More

- [Record.Get method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method) — the signature, the Boolean return value, and the note on what happens to key fields you leave out of the call.
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods) — why `Get` is the tool for a primary-key lookup and how it behaves when the row is missing.
- [Table keys](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys) — primary keys made of several fields, and why the combination, not each field, has to be unique.
