# Deep Copy Nested Collections

A colleague "fixed" a data-mixup bug by duplicating a nested schedule structure with `:=` — and a week later, edits made to the copy were mysteriously appearing in the original. Nothing mysterious about it: in AL, `List` and `Dictionary` are reference types. Assigning one variable to another copies the reference, not the collection — both variables read and write the same data. Even `GetRange`, which does build a new list, performs only a *shallow* copy: when the elements are themselves lists, the new outer list still points at the very same inner lists.

Your job is a small utility codeunit that produces genuinely independent copies of two nested collection shapes.

## Requirements

Create a **codeunit** named `"Collection Deep Copy"` with two public procedures:

```al
procedure CopyMatrix(Source: List of [List of [Integer]]): List of [List of [Integer]]
procedure CopyGroups(Source: Dictionary of [Code[20], List of [Text]]): Dictionary of [Code[20], List of [Text]]
```

Rules:

1. `CopyMatrix` returns a new outer list containing a **new** inner list for every inner list of `Source`, with the same integers in the same order.
2. `CopyGroups` returns a new dictionary with the same keys, each mapped to a **new** list holding the same texts in the same order.
3. The copies must be fully independent of the source: after copying, adding values to an inner list (or to a group's list) on either side must never show up on the other side.
4. Empty inner lists count too: an empty inner list in the source comes out as an empty — and equally independent — inner list in the copy.
5. Copying must not modify `Source`.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests copy matrices and dictionaries filled with generated values, then compare counts, keys, and every element in order — including a source that contains an empty inner list, which must come out empty. After each copy they mutate an inner list on one side (the copy in some tests, the source in others, previously-empty lists included) and assert the other side is unchanged — a solution that shares any inner list between source and copy fails those tests.

## Learn More

- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — why a List is a reference type, and what shallow versus deep copy means for nested lists.
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — reference semantics plus the key/value methods you will need.
- [List.GetRange method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-getrange-integer-integer-method) — the documented shallow-copy method and its limits.
- [Dictionary.Keys method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-keys-method) — iterate a dictionary's keys to rebuild it.
