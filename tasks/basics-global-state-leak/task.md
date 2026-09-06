# The Total That Kept Growing

Support opened a ticket against the sales-order preview. The **Lines Total** it shows is right the first time; after the user edits a line and previews again, the total is roughly double, and a third preview triples it. The page keeps one `"Line Totaler"` codeunit variable and calls `Total` on it every time — and somebody stored the running sum in a codeunit global.

Here is the mechanism at work. A variable declared in a codeunit's own `var` section (a *global*) belongs to the codeunit **instance**, and an instance lives as long as the variable that holds it: a `Codeunit "Line Totaler"` variable on a page, in a test, or in another codeunit is one instance, and every call through it sees the same globals in whatever state the previous call left them. A variable declared inside a procedure (a *local*) is created at its default value on every call and disappears when the call returns. `Clear(Variable)` resets any variable to its default — `0` for a Decimal.

## Requirements

The starter contains a **codeunit** named `"Line Totaler"` with one public procedure:

```al
procedure Total(Amounts: List of [Decimal]): Decimal
```

It already sums correctly — once. Fix it so that every call is independent, keeping the object name and the signature exactly as they are.

Rules:

1. `Total` returns the sum of every amount in `Amounts`, each counted once, with no rounding. Amounts may be negative (credit lines) and reduce the total.
2. An empty list totals `0` and must not raise an error.
3. Every call returns the sum of exactly the amounts passed to that call. Calling `Total` any number of times on the same `"Line Totaler"` instance — with the same list, a different list, or an empty list — must never let an earlier call's total carry over into a later result.
4. `Total` must not change the list it is given: afterwards the caller's list holds the same amounts in the same order. A `List` is a reference type — the procedure and its caller share one list, so removing amounts while summing would empty the caller's list too.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests total a list of generated two-decimal amounts on a fresh `"Line Totaler"` instance and compare the result with an independently computed sum, total an empty list and expect `0`, and total the fixed list 120, -45.25, 10.10 expecting exactly 84.85. Three tests then reuse **one instance** across two calls: totaling the same list twice must return the list's sum the second time (not twice the sum), totaling a second, different list after a first one must return only the second list's sum, and totaling an empty list after a non-empty one must return `0`. A final test snapshots the amounts before a call and expects the list to hold the same amounts in the same order afterwards. Every comparison is exact, and a failure shows both the expected and the actual total — a leaked total is visible as the surplus.

## Learn More

- [AL variables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-variables) — global variables apply to every method of an object, local variables to a single method.
- [System.ClearAll method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method) — the remark that values of variables are retained in memory between repeated calls on the same object.
- [System.Clear method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-joker-method) — what each data type is reset to when you clear a single variable.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — why a list passed without `var` is still the caller's list.
