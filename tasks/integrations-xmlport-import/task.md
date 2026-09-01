# Import an Order Document with an XMLport

Your wholesale customers stopped emailing orders and switched to EDI: a partner gateway drops one XML document per batch, each holding several orders with their lines. Before anything touches the sales tables, the batch is staged into two intake tables where a clerk reviews it.

Staging is the job of an **XMLport** — the AL object type built for exactly this. You describe the document once, bind its elements to tables, and the runtime walks the stream for you.

## What you are given

The starter contains two finished tables. Submit them **unchanged** alongside your XMLport:

- `"Order Intake Header"` — `"Order No."` (`Code[20]`, primary key), `"Customer No."` (`Code[20]`), `"Customer Name"` (`Text[100]`), `"Batch Id"` (`Code[20]`). Validating `"Customer No."` copies the customer's `Name` into `"Customer Name"`.
- `"Order Intake Line"` — `"Order No."` (`Code[20]`) + `"Line No."` (`Integer`) as the primary key, `"Item No."` (`Code[20]`), `Description` (`Text[100]`), `Quantity` (`Decimal`), `"Unit Price"` (`Decimal`), `Amount` (`Decimal`). Validating `"Item No."` copies the item's `Description` and `"Unit Price"` onto the line; validating `"Item No."` or `Quantity` recomputes `Amount` as `Quantity × "Unit Price"`.

Neither table derives anything on insert: those values appear only when the field is written **through validation**. A header written field by field arrives with an empty `"Customer Name"`, and a line written field by field with an empty `Description` and a zero `Amount` — and the tests check that this is still true of your submission.

## The document

One batch looks like this — element names, nesting and order are fixed, and no namespaces are involved:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<OrderIntake>
  <BatchId>BATCH-2026-0417</BatchId>
  <Order>
    <OrderNo>EDI-100244</OrderNo>
    <CustomerNo>C-01230</CustomerNo>
    <Line>
      <ItemNo>ITEM-4711</ItemNo>
      <Quantity>3</Quantity>
    </Line>
    <Line>
      <ItemNo>ITEM-4713</ItemNo>
      <Quantity>0</Quantity>
    </Line>
  </Order>
  <Order>
    <OrderNo>EDI-100245</OrderNo>
    <CustomerNo>C-04490</CustomerNo>
    <Line>
      <ItemNo>ITEM-4711</ItemNo>
      <Quantity>12</Quantity>
    </Line>
  </Order>
</OrderIntake>
```

What the gateway guarantees, and nothing more:

- `BatchId` appears exactly once, at the top of the document, and applies to every order in it.
- A document carries one or more `Order` elements; every `Order` carries one or more `Line` elements.
- Every `CustomerNo` exists as a `Customer` and every `ItemNo` exists as an `Item`.
- `Quantity` is a whole number and may be zero or negative.
- Lines are not numbered: their order inside the `Order` element is the only ordering there is.
- The same `OrderNo` can come back in a later document when the partner corrects an order.
- Documents are well-formed XML with plain-text element content.

## Requirements

Create an **XMLport** named `"Order Intake Import"` with `Direction = Import` that stages a batch document into the two tables:

1. Every `Order` element becomes one `"Order Intake Header"` row, keyed by its `OrderNo`, carrying its `CustomerNo` — and the `"Customer Name"` that the staging table derives from it.
2. Every staged header carries the document's `BatchId` in `"Batch Id"`, even though it is never repeated inside an `Order` element.
3. Every `Line` element becomes one `"Order Intake Line"` row whose `"Order No."` is the `OrderNo` of the `Order` element it sits in.
4. Staged lines are numbered **10000, 20000, 30000, …** in document order, and the numbering restarts at 10000 for every order.
5. A line whose `Quantity` is `0` or less is **not staged at all**, and it does not consume a line number: the line after it takes the number the skipped one would have had.
6. A staged line carries the `Description`, `"Unit Price"` and `Amount` that the staging table derives from the item — the document sends neither a description nor a price.
7. An `OrderNo` that is already staged is **updated**, not duplicated and not rejected: the staged header and its lines are overwritten with the values of the newer document. The tests re-send a corrected order with the same number of lines as before, so cleaning up lines that the corrected document no longer carries is out of scope.

Pick object IDs in the range 50100–50199, and reference every other object **by name**, never by ID. The two given tables must keep their names, fields and behaviour — the tests read them directly.

The grading tests call `Xmlport.Import(Xmlport::"Order Intake Import", InStr)`, which never shows a request page, so `UseRequestPage = false` is a good habit here but is not graded.

## What the tests check

The tests build batch documents in the shape above — with generated order numbers, batch ids, quantities and prices, so nothing can be hardcoded — hand them to `Xmlport.Import` by object, and then read the two staging tables directly: the header row and its derived `"Customer Name"`, the `BatchId` on every header of a two-order document, three lines numbered 10000/20000/30000 in document order, two orders each restarting at 10000 and keeping only their own lines, a zero-quantity and a negative-quantity line absent from the staging table, a skipped line not burning a number (the surviving lines are still 10000 and 20000), `Description`, `"Unit Price"` and `Amount` derived from the item, and a re-import of the same order number leaving exactly one header and one line with the second document's customer, batch id and quantity. Counts and values are exact: an extra line, a missing one, or a line numbered 30000 where 20000 was expected all fail. Two more tests write a header straight into `"Order Intake Header"` and a line straight into `"Order Intake Line"` without validating anything, and expect `"Customer Name"`, `Description` and `Amount` to stay empty — that is the given tables' behaviour, so leave both of them alone.

## Learn More

- [XMLport overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-overview) — what the object is made of, and the two properties you must decide first.
- [Defining an XMLport schema](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-schema) — the node keywords the schema is built from.
- [XMLport properties](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-xmlport-properties) — the full property list per node type; the header/line behaviour you need is configured here.
- [Xmlport.Import(Integer, var InStream) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-import-method) — how grading runs your XMLport.
