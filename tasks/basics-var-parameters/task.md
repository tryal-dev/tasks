# Why Did My Change Vanish?

A teammate wrote a small helper codeunit for a sales-line discount feature, and the bug report reads like a riddle. `ApplyDiscount` calculates the discounted `"Line Amount"` correctly — you can watch it happen in the debugger — yet the calling code never sees the new amount. `NormalizeTag` upper-cases a tag and the caller still holds the lower-case original. Meanwhile the sibling `AppendTag`, declared exactly the same way, *does* change the caller's list. Nothing is random here: every one of these behaviors follows from whether a parameter travels **by value** or **by reference**.

In AL a parameter is passed by value unless you write `var` in front of it. By value means the callee receives a *copy* — assignments inside the procedure land on that copy and vanish when it returns. `var` makes the parameter a reference to the caller's own variable, so the callee's changes stick. This applies to a `Record` (the whole in-memory record is copied) and to a `Text` (the string is copied). A `List` is different: `List` is a reference type, so even a by-value `List` parameter is a second handle on the caller's list — `Add` inside the callee changes what the caller sees, `var` or not. That also means a procedure that only *reads* a list must not "normalize it in place", because there is no private copy to normalize.

Your job is to fix the codeunit's signatures so that every caller observes exactly what the statement promises — and nothing more. The starter gets `var` wrong in more than one place, and in both directions.

## Requirements

Create a **codeunit** named `"Line Discount Helper"` with five public procedures:

```al
procedure ApplyDiscount(var SalesLine: Record "Sales Line"; Pct: Decimal)
procedure PreviewDiscount(SalesLine: Record "Sales Line"; Pct: Decimal): Decimal
procedure NormalizeTag(var Tag: Text)
procedure AppendTag(Tags: List of [Text]; Tag: Text)
procedure CountTags(Tags: List of [Text]): Integer
```

Rules:

1. `ApplyDiscount` writes two fields on the caller's line: `"Line Discount %"` becomes `Pct`, and `"Line Amount"` becomes `Quantity × "Unit Price" × (100 − Pct) ÷ 100`, rounded to the nearest 0.01. Only assign the fields — do not call `Validate`, `Modify`, or `Insert`; the tests pass an in-memory line that is not in the database.
2. `PreviewDiscount` returns the `"Line Amount"` that `ApplyDiscount` *would* produce for the same line and `Pct`, but the caller's record must be untouched afterwards — its `"Line Amount"` and `"Line Discount %"` keep the values they had before the call.
3. `NormalizeTag` changes the caller's text in place: leading and trailing spaces are removed (inner spaces stay) and the result is upper-cased.
4. `AppendTag` adds the **normalized** form of `Tag` (as `NormalizeTag` defines it) to the end of `Tags`. The caller's list gains the entry — no `var` is needed for a `List`. `Tag` stays by value: after the call the caller's own text variable still holds exactly what it typed, spaces and case included.
5. `CountTags` returns how many **distinct** tags the list holds once every entry is normalized — `'promo'`, `' PROMO'` and `'Promo '` count as one. The caller's list must be exactly as it was afterwards: same number of entries, same order, same raw text. Normalize into a loop variable or a scratch list of your own, never into the shared list.
6. Tags are never blank; `Pct` is between 0 and 100.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The grading tests build a `"Sales Line"` variable in memory (never inserted) and assert **caller-side** values only. After `ApplyDiscount` the caller's `"Line Amount"` and `"Line Discount %"` must carry the new values — a fixed case (3 × 19.90 at 10 % gives 53.73), a generated one, and a rounding case (1 × 19.99 at 12.5 % is 17.49125 before rounding and must land as 17.49). After `PreviewDiscount` the return value must equal the discounted amount — including a rounding case (1 × 12.99 at 37.5 % must return 8.12, not 8.11875) — while the caller's two fields are unchanged. After `NormalizeTag` the caller's text must be trimmed and upper-cased (`'  Black  Friday '` becomes `'BLACK  FRIDAY'`). `AppendTag` must make the caller's list one entry longer, that entry must be the normalized form, and the caller's `Tag` variable must still read exactly as typed. `CountTags` must return the distinct normalized count (fixed and generated lists, and 0 for an empty list) and leave the list's entries untouched. A helper that lacks `var` where the caller must see the change fails the corresponding test, and so does one that carries a `var` where the statement says the caller's variable stays as it was.

## Learn More

- [Working with AL methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods) — the Parameters section explains passing by value (a copy) versus by reference (`var`).
- [Identify differences between a parameter by value and by reference](https://learn.microsoft.com/en-us/training/modules/create-custom-functions/6-parameter) — the training unit with a side-by-side example of the same procedure with and without `var`.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the Remarks state that a `List` is a reference type, so passing it by value does not create a new list.
- [CodeCop Warning AA0150](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/analyzers/codecop-aa0150) — why `var` on a parameter the procedure never changes is a bug in its own right.
