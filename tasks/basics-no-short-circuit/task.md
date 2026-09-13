# AL Evaluates Both Sides

Two production errors landed in your queue this morning, and they are the same bug wearing two coats. The approval check on sales lines dies with a division-by-zero error on every comment line, and the customer check dies with `The Customer does not exist` whenever the customer field is still blank. Both procedures guard the dangerous operation with a condition on the left of an `and` — and both guards are useless.

The reason is a rule of the language. AL evaluates every operand of `and`, `or` and `xor` before it combines them; there is no short-circuit evaluation like `&&` in C# or `and` in Python. In `(Qty <> 0) and (Total / Qty > Limit)` the division runs first, and the question about zero is asked afterwards. A guard that must stop the second condition from running has to be a statement of its own: an `if` that tests the guard and only then evaluates the second condition, or an early `exit` for the unsafe case.

## Requirements

The starter contains a **codeunit** named `"Sales Guards"` with two public procedures and one local helper:

```al
procedure IsOverLimit(Total: Decimal; Qty: Decimal; Limit: Decimal): Boolean
procedure HasOpenOrder(CustomerNo: Code[20]): Boolean
```

Fix both procedures so that their guards actually guard, keeping the object name and both signatures exactly as they are.

Rules:

1. `IsOverLimit` returns `true` when `Qty` is not zero and the average `Total / Qty` is strictly greater than `Limit`; an average equal to `Limit` is not over it. `Qty` is never negative, and neither are `Total` and `Limit`.
2. When `Qty` is zero, `IsOverLimit` returns `false` and must not raise an error, whatever `Total` and `Limit` are — a line without quantity has no average to compare.
3. `HasOpenOrder` returns `true` when the customer numbered `CustomerNo` has at least one open sales order: a `Sales Header` record whose `"Document Type"` is `Order`, whose `"Sell-to Customer No."` is `CustomerNo` and whose `Status` is `Open`. Quotes, invoices and other document types do not count, orders in any other status do not count, and orders of other customers do not count.
4. When `CustomerNo` is blank, `HasOpenOrder` returns `false` and must not raise an error. The starter's `OpenOrderExists` helper is written for a customer that exists: it fetches the customer card with a bare `Get`, which raises an error when there is no such customer — and a blank number is no customer. The helper needs no change; it must simply never run for a blank number. A non-blank `CustomerNo` is always the number of an existing customer.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests call `IsOverLimit` with a quantity of zero and a random total above the limit and expect `false` with no error; when the call raises an error, the failure message shows the error text. They then call it with a random quantity and limit and a total chosen so that the average lands above the limit (expect `true`), below it (expect `false`) and exactly on it (expect `false`). For `HasOpenOrder` they pass a blank number and expect `false` with no error, again showing the raised error if there is one; they create customers and documents with the standard test libraries and expect `true` for a customer with a sales order in status Open, and `false` for a customer whose only order is Released, for a customer whose only document is a quote, and for a customer without documents while another customer has an open order. The tests run in a real company that holds other customers and documents, so your answer must follow the rules above rather than any assumption about the data.

## Learn More

- [Boolean (logical) operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-boolean-operators) — `and`, `or`, `xor` and `not` all work on fully evaluated Boolean operands.
- [AL control statements](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements) — `if-then-else`, nested `if` statements and the `exit` statement that leaves a procedure early.
- [Record.Get method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method) — why a `Get` whose return value is ignored raises a runtime error when the record does not exist.
- [Record.IsEmpty method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-isempty-method) — the cheapest way to ask whether a filtered set holds any record at all.
