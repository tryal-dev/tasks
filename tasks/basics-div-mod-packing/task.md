# Pallets, Boxes, and Loose Units

The warehouse ships every item in boxes, and the boxes are stacked on pallets. A pick list should read "2 pallets, 2 boxes, 7 loose units" — but the current calculator tells the forklift driver to bring 4 boxes for 7 units that come in boxes of 2. Its author reached for `/`, and in AL `/` always yields a Decimal, which is silently rounded to the nearest whole number the moment it is assigned to an Integer. The right tools for splitting a quantity are the integer operators `div` (the whole-number quotient) and `mod` (the remainder).

## Requirements

The starter already contains a table extension `"Item Packing Ext"` on the `Item` table with two Integer fields, `"Units per Box"` and `"Boxes per Pallet"`. Leave it as it is — the tests write both fields directly.

Complete the **codeunit** `"Packing Calculator"` with these two public procedures:

```al
procedure SplitQuantity(ItemNo: Code[20]; Quantity: Decimal; var Pallets: Integer; var Boxes: Integer; var Loose: Integer)
procedure PalletsNeeded(ItemNo: Code[20]; Quantity: Decimal): Integer
```

Rules:

1. A pallet holds `"Boxes per Pallet"` × `"Units per Box"` units. `SplitQuantity` fills as many full pallets as possible, then as many full boxes as possible from what is left, and reports the rest as loose units. So `Boxes` is always less than `"Boxes per Pallet"`, `Loose` is always less than `"Units per Box"`, and `Pallets × (units per pallet) + Boxes × "Units per Box" + Loose` adds back up to `Quantity`. A quantity of 0 splits into 0, 0, 0.
2. `PalletsNeeded` returns how many pallets it takes to carry the whole quantity: the full pallets, plus one more if any box or loose unit is left over. It rounds *up* — a single unit still needs one pallet — and a quantity of 0 needs 0 pallets.
3. `Quantity` is a Decimal because that is how Business Central stores quantities, but only whole units can be packed. A quantity with a fractional part (12.5) must raise an error with a message that contains the words `whole number` (lowercase, exactly as written) — never round or truncate it into something packable. Do this check before any arithmetic: `div` and `mod` happily accept a Decimal operand and would hide the problem.
4. If the item's `"Units per Box"` or `"Boxes per Pallet"` is 0, raise an error with a message that names that field (`Units per Box` or `Boxes per Pallet`). A raw "Attempted to divide by zero" is not acceptable. `Item.TestField` on the empty field produces exactly such a message.
5. Both procedures apply rules 3 and 4. The tests never pass a negative quantity and always pass the number of an existing item.

Keep object and field IDs in the range **50100–50199**, and reference other objects **by name, never by ID**. Captions are good practice but not graded.

## What the tests check

The grading tests create items with the standard inventory library, set the two packing fields, and call your procedures. `SplitQuantity` is checked on an exact pallet multiple (no boxes, no loose), a mixed quantity (pallets, boxes and loose all non-zero), a quantity below one box, the 7-units-in-boxes-of-2 case (3 boxes and 1 loose, not 4 boxes), zero, and a **generated** quantity with generated box and pallet sizes, where the three parts must add back up to the quantity and respect the "less than" bounds from rule 1. `PalletsNeeded` is checked on an exact multiple, a partial pallet, a single unit, zero, and a generated quantity that must fit on the returned number of pallets but not on one fewer. Six tests use `asserterror`: a non-whole quantity through each procedure must fail with `whole number` in the message, and a zero `"Units per Box"` or a zero `"Boxes per Pallet"` (both procedures) must fail with the field name in the message. All comparisons are exact.

## Learn More

- [Arithmetic operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-arithmetic-operators) — the operand and result types of `/`, `div` and `mod`.
- [AL variables: assignment and type conversion](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-variables#assignment-and-type-conversion) — why a Decimal can be assigned to an Integer at all, and what that silently does to the value.
- [Round method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method) — rounding a Decimal to a chosen precision and direction; handy for the whole-number check.
- [Record.TestField method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-joker-method) — the one-liner that refuses a zero field with a message naming it.
