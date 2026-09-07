# Where in the Tree Is This Item?

The web-shop team wants a breadcrumb on every product page — `FURNITURE > CHAIRS > OFFICE` — plus the item's depth in the catalog and its top-level department for the navigation menu. In Business Central that tree already exists: every `Item Category` can name a `"Parent Category"`, and each item carries an `"Item Category Code"`. All you have to do is walk up the tree. The catch is that the tree is not always clean: an import can leave a parent code pointing at a category that was deleted afterwards, and a configuration package can wire two categories into a loop. A walker that crashes with a generic "record does not exist" or, worse, never returns is not acceptable — both situations must be reported with a clear error.

## Requirements

Create a **codeunit** named `"Category Breadcrumb"` with three public procedures:

```al
procedure CategoryPath(ItemNo: Code[20]): Text
procedure CategoryDepth(ItemNo: Code[20]): Integer
procedure RootCategory(ItemNo: Code[20]): Code[20]
```

Rules:

1. The **chain** of an item starts at its `"Item Category Code"` and follows `"Item Category"."Parent Category"` upward until that field is blank. `CategoryPath` returns the codes of the chain from the root down to the item's own category, separated by ` > ` (space, greater-than sign, space): for an item in `OFFICE` whose parent is `CHAIRS` whose parent is `FURNITURE`, the path is `FURNITURE > CHAIRS > OFFICE`. No separator before the first code or after the last one, and codes exactly as stored.
2. `CategoryDepth` returns how many categories are on that path — 3 in the example, 1 for an item whose category has no parent. `RootCategory` returns the first code of the path — `FURNITURE` in the example; for an item whose category has no parent, that category's own code.
3. An item without an `"Item Category Code"` has no chain: `CategoryPath` returns an empty text, `CategoryDepth` returns 0 and `RootCategory` returns an empty code. None of them raises an error.
4. **Missing parent.** When a category on the chain has a `"Parent Category"` that names no existing `Item Category` record (deleted after the fact, or imported wrongly), raise the error `Item category %1 refers to parent category %2, which does not exist.` — `%1` is the category whose parent field is broken, `%2` the code it points at. If `CHAIRS` was deleted, an item in `OFFICE` gives `Item category OFFICE refers to parent category CHAIRS, which does not exist.`
5. **Cycle.** When the walk reaches a category it has already visited, raise the error `Item category %1 is its own ancestor.` — `%1` is the code of the category that was reached for the **second** time. Item in `A`, `A`'s parent is `B`, `B`'s parent is `A`: the walk goes A, B, A — the error names `A`. Item in `D`, `D`'s parent is `B`, `B`'s parent is `A`, `A`'s parent is `B`: the walk goes D, B, A, B — the error names `B`. A category that is its own parent names itself. The walk must stop; it may never loop forever.
6. Rules 4 and 5 apply to all three procedures — `CategoryDepth` and `RootCategory` walk the same chain and raise the same errors.

You can rely on these guarantees about the input: the tests always pass the number of an existing item, and the item's own category (when it has one) always exists — only parents go missing.

The tools are all basic AL. A `while` loop that reads the next `Item Category` record until `"Parent Category"` is blank does the walking; `Record.Get` has an optional Boolean return value, so `if not ItemCategory.Get(...)` turns "record not found" from a crash into the branch that raises rule 4's error. A `List of [Code[20]]` collects the codes you have seen — its `Contains` method is the cycle detector for rule 5, and its `Count` is the depth. Raise the errors with `Error` and a `Label` that carries the `%1`/`%2` placeholders. Two things a first attempt often misses: the base application's `"Parent Category"` field validation does refuse cycles, but only in `OnValidate` — a direct table write, an import or a configuration package can still leave a loop in the data, and the tests create their broken trees exactly that way. And an implementation without a visited list does not fail on a cycle — it never returns, which the grader can only report as a timeout, not as a failing test.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

| Categories | Item in | `CategoryPath` | `CategoryDepth` | `RootCategory` |
|---|---|---|---|---|
| `FURNITURE` ← `CHAIRS` ← `OFFICE` | `OFFICE` | `FURNITURE > CHAIRS > OFFICE` | 3 | `FURNITURE` |
| `FURNITURE` (no parent) | `FURNITURE` | `FURNITURE` | 1 | `FURNITURE` |
| — | (no category) | (empty) | 0 | (empty) |
| `OFFICE` → parent `CHAIRS`, which was deleted | `OFFICE` | error: `Item category OFFICE refers to parent category CHAIRS, which does not exist.` | same error | same error |
| `A` ⇄ `B` (each other's parent) | `A` | error: `Item category A is its own ancestor.` | same error | same error |

## What the tests check

The grading tests create their own item categories with the standard test library, so the codes are generated at run time and the expected path is assembled from the actual codes — returning a constant or matching the examples passes nothing. They link the categories into trees of one, three and four levels, assign a freshly created item, and compare each returned value **exactly** (mind the spaces around `>`); the three "no category" cases must return empty text, 0 and empty code without raising. For the error paths, the tests first build a valid tree and assign the item, then damage the tree with direct table writes that bypass validation: a middle category deleted, the root deleted, a parent code that never existed, a two-category loop, a loop above the item's category, and a category that is its own parent. Each of the three procedures is run against at least one missing-parent tree and one cycle, and the tests look for the exact sentence from rules 4 and 5 — same wording, same codes, same full stop — inside the error text. An implementation that never returns on a cycle makes the whole grading run time out; read that as the cycle tests failing.

## Learn More

- [Categorize items](https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-categorize-items) — what item categories and the Parent Category field mean to the people who maintain them.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — Add, Contains, Count and Get, and the line that says lists are 1-based.
- [Record.Get method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method) — the optional Boolean return value that turns "record not found" from a crash into a branch.
- [Dialog.Error(Text [, Any,...]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method) — placeholders `%1` and `%2` fill the codes into the message.
