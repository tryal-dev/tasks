# Add a Priority Enum to Items

Purchasing wants to rank items by how urgently they should be restocked. In AL that calls for an **enum** — a first-class object that other extensions can even extend later.

## Requirements

1. Create an **enum** named `"Item Priority"` with these values (the ordinals are graded; extra values of your own don't hurt):

   | Ordinal | Name |
   |---|---|
   | 0 | `Low` |
   | 1 | `Normal` |
   | 2 | `High` |

2. Create a **table extension** that extends the `Item` table and adds a field named `"Restock Priority"` of type `Enum "Item Priority"`.
3. A freshly created item must default to `Normal` — use the field's `InitValue` property.

## What the tests check

The grading tests look each value up by name in the enum's `Names()`/`Ordinals()` lists and check its ordinal (a missing value fails with a message naming it), look `"Restock Priority"` up on the `Item` table by name and require it to be an enum field whose values are those of `"Item Priority"` — declaring it as an `Option` field fails. They then write `High` to an item and read its ordinal back, and create a new item to verify it defaults to `Normal`.

## Learn More

- [Extensible enums](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums)
- [Enum data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-data-type)
- [Enum.Names method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-names-method)
- [InitValue property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property)
- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object)
