# abc-1 Is ABC-1

A stock count comes back from the warehouse as two parallel lists: the item numbers exactly as the counters typed them, and the quantities they counted. The same item shows up on several lines — as `abc-1` on one, `ABC-1` on the next, `ABC-1 ` with a stray space on a third. In Business Central they are all one item: `Item."No."` is a `Code[20]`, and a `Code` value is always uppercased with leading and trailing spaces removed.

A colleague started the per-item summary but keyed the totals with a `Dictionary of [Text, Decimal]`. `Text` keys compare character by character, so those three spellings land in three buckets — and because `Dictionary.Add` refuses a key it already holds, the routine dies with a runtime error on the first line whose item number repeats exactly. The starter is that code. Fix it.

## Requirements

Create a **codeunit** named `"Item Totals"` with one public procedure:

```al
procedure TotalsByItem(ItemNos: List of [Text]; Quantities: List of [Decimal]): Dictionary of [Code[20], Decimal]
```

Rules:

1. The lists are paired by position: the first item number goes with the first quantity, the second with the second, and so on. The lists always have the same length, and no item number is blank.
2. An item number identifies an item by its **uppercased, trimmed** form: `abc-1`, `ABC-1`, `Abc-1`, `ABC-1 ` and ` ABC-1` are all the item `ABC-1`. That is exactly what happens when a `Text` value is assigned to a `Code[20]` variable or passed where a `Code[20]` is expected — the conversion uppercases, strips leading and trailing spaces, and refuses anything longer than 20 characters.
3. The returned dictionary holds exactly one key per distinct item, and that key's value is the sum of the quantities of every line belonging to it. Zero and negative quantities count like any other: a negative quantity lowers the total, and a line with quantity 0 still creates its key with a total of 0.
4. Looking a total up with any spelling works: calling `Get` on the returned dictionary with `abc-1` finds the total stored under `ABC-1`. A `Code[20]` key gives you this for free — the lookup text goes through the same conversion.
5. An item number longer than 20 characters is a bug in the input, not something to truncate silently: the procedure must raise an error with a message that mentions `20`. The runtime's own string-overflow error from the `Text` → `Code[20]` conversion (*"The length of the string is 21, but it must be less than or equal to 20 characters."*) satisfies this without any code of your own. An item number of exactly 20 characters is valid and must be totalled normally.
6. Empty lists return an empty dictionary.

Three `Dictionary` methods matter here. `Add` returns a `Boolean`; if you ignore that return value and the key already exists, `Add` raises a runtime error instead of returning `false`. `Get` comes in two shapes: `Get(Key)` returns the value and raises when the key is missing, while `Get(Key, var Value)` fills `Value` and returns `false` for a missing key without raising. `Set` writes a value under a key whether or not the key exists yet. For each line, you need to know whether the item already has a running total, then either extend it or start it.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests call `TotalsByItem` with quantities generated fresh on every run and assert the dictionary's **key count** and the **exact total** under each key, so hardcoded answers fail. One test repeats an item number across non-adjacent lines and expects the two quantities summed under a single key next to a second, untouched item. Others feed `tryal-case`, `TRYAL-CASE` and `Tryal-Case`, then `TRYAL-PAD` with leading and trailing spaces (never padded past 20 characters in total), and expect exactly one key each time. A test reads the single key back and compares it to the uppercased, trimmed spelling; another calls `Get` with the lowercase spelling and expects it to succeed with the right total. A zero-quantity line must produce its key with a total of 0, and a negative quantity must be subtracted. A generated 20-character item number must be accepted; a generated 21-character one must raise an error with a message that contains `20` (substring match). Empty lists must return an empty dictionary.

## Learn More

- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — the method list, and a worked example of the get-then-set-or-add pattern this task needs.
- [Dictionary.Add method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-add-method) — the optional Boolean return, and why omitting it turns a duplicate key into a runtime error.
- [Dictionary.Get(TKey, var TValue) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-get-tkey-tvalue-method) — the non-throwing lookup that reports a missing key through its return value.
- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type) — why a Code value is uppercased and trimmed, with the `' 2 '` → `'2'` example.
