# Build a Sales Order From Code

An integration drops orders into Business Central every night, and every morning support gets the same ticket: the order has a blank Unit Price, no Payment Terms, and the invoice went to the wrong company. Nobody typed those orders on the Sales Order page — a codeunit created them, and it *assigned* fields instead of validating them. Your job is the opposite: a small builder whose orders are indistinguishable from ones typed on the page.

## Requirements

Create a **codeunit** named `"Sales Order Builder"` with three public procedures:

```al
procedure CreateOrder(CustomerNo: Code[20]): Code[20]
procedure AddLine(OrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal): Integer
procedure AddNegotiatedLine(OrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal; LineDiscountPct: Decimal): Integer
```

`CreateOrder` stores a **sales order** (document type Order) for `CustomerNo` and returns its `"No."`. Let the document assign its own number: the stored order's `"No. Series"` must be the `"Order Nos."` series from Sales & Receivables Setup, which is what running the header's insert trigger gives you. The order must also carry everything the customer card would have given it on the page:

- `"Sell-to Customer No."` is `CustomerNo`;
- `"Payment Terms Code"`, `"Salesperson Code"` and `"Currency Code"` come from the customer;
- `"Bill-to Customer No."` is the customer's own `"Bill-to Customer No."` when the customer is invoiced through somebody else, and the customer itself otherwise.

`AddLine` appends a line of type Item for `ItemNo` to order `OrderNo`, stores it, and returns its `"Line No."`. Line numbers start at **10000** and step in **10000s** — the second line of an order is 20000, the third 30000. The stored line must carry:

- `Description`, `"Unit of Measure Code"` (the item's `"Sales Unit of Measure"`) and `"Unit Price"` from the item;
- `Quantity` and `"Outstanding Quantity"` equal to the quantity passed in;
- `"Line Amount"` equal to quantity × unit price, rounded to the nearest 0.01.

`AddNegotiatedLine` does the same, but the finished line must end up priced at `UnitPrice` with a line discount of `LineDiscountPct` percent: `"Unit Price"` is `UnitPrice`, `"Line Discount %"` is `LineDiscountPct`, `"Line Discount Amount"` is that percentage of quantity × `UnitPrice` (each step rounded to the nearest 0.01), and `"Line Amount"` is quantity × `UnitPrice` minus the discount amount. A `LineDiscountPct` of 0 simply means no discount.

This task is really about two things. First, assigning a field stores a value and nothing else, while validating it runs the field's own logic — the logic that copies the customer's terms onto the header, the item's data onto the line, and recalculates the amounts. Second, **order matters**: a sales line looks its price and its discount up again every single time `Quantity` is validated, and overwrites what it finds there.

`OrderNo` always names an existing sales order, and `ItemNo` an existing item. Pick object IDs in the range **50100–50199**, and reference other objects **by name, never by ID**. Nothing has to be released, shipped or posted.

## What the tests check

The grading tests build customers and items with the standard test libraries, everything generated: a customer carrying a payment terms code, a salesperson, a currency and a `"Bill-to Customer No."` pointing at a second customer, and an item with a generated description, a sales unit of measure that differs from its base unit, and a generated unit price. They call `CreateOrder`, read the stored order back by the returned number, and then assert separately: the number series it was numbered from, each inherited header field, and the bill-to customer both for a customer that names another payer and for one that doesn't. For lines they create the order with the standard library (so `AddLine` must not assume how the order was made), read each line back by the returned line no., and assert the inherited description, unit of measure and unit price, the quantity and outstanding quantity, and the line amount. One test adds three lines and expects 10000, 20000, 30000. Two more call `AddNegotiatedLine` with a price well above the item's own price and assert the negotiated unit price, line amount, discount percentage and discount amount — those numbers only add up if the negotiated terms are the last thing the line hears about.

## Learn More

- [Record.Validate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method) — what validating a field does that assigning it doesn't.
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods) — `Validate`, `TestField` and `Init` in one page, with the assignment-versus-validation example.
- [OnValidate (Field) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/field/devenv-onvalidate-field-trigger) — the trigger behind every field you validate on the header and the line.
- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — the `RunTrigger` parameter that decides whether `OnInsert` runs, and with it the number series.
