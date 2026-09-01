# Call Off the Blanket Order

A blanket sales order is an agreement, not a delivery. The customer commits to 1,000 units for the year and takes them in tranches, and every tranche becomes its own sales order — "called off" against the agreement. The agreement itself has to survive: it stays open, it keeps score of what has already gone out the door, and every order created from it stays attached to the line it came from, so posting a shipment feeds the numbers back onto the blanket line. Get that link wrong and the blanket order quietly stops tracking anything, which nobody notices until the customer has taken 1,400 units of a 1,000-unit agreement.

Your job is the call-off routine: one tranche in, one sales order out, the agreement intact.

## Requirements

Create a **codeunit** named `"Blanket Call Off"` with two public procedures, exactly these signatures:

```al
procedure CallOff(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer; QuantityToCallOff: Decimal): Code[20]
procedure RemainingOnBlanket(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer): Decimal
```

Both are addressed the same way: `BlanketOrderNo` is the `"No."` of a `Sales Header` whose `"Document Type"` is `Blanket Order`, and `BlanketOrderLineNo` is the `"Line No."` of one of its `Sales Line` records. You may assume both exist.

### `RemainingOnBlanket`

Returns how much of that blanket line is still uncommitted — what you could still call off today. Three terms:

1. the blanket line's `Quantity`,
2. minus its `"Quantity Shipped"` — the part already delivered and posted,
3. minus the `"Outstanding Quantity"` of every sales **order** line that was called off against this blanket line and has not been posted yet.

An untouched blanket line therefore reports its full `Quantity`, and a tranche that moves from "open call-off order" to "posted shipment" does not change the answer — it only moves from term 3 to term 2.

### `CallOff`

Creates the sales order for one tranche and returns that order's `"No."`.

1. `QuantityToCallOff` must be greater than zero. Reject `0` and negative quantities with an error message that contains `must be positive`, and change nothing.
2. `QuantityToCallOff` must not be greater than `RemainingOnBlanket` for the same line. Reject a larger call-off with an error message that contains `exceeds the remaining quantity`, and change nothing — in particular, no sales order may be created.
3. Otherwise exactly one sales order is created, for the blanket order's `"Sell-to Customer No."`, carrying exactly one line: the same item as the blanket line, with `Quantity` equal to `QuantityToCallOff`.
4. That created order line must be attached to the blanket line it came from: its `"Blanket Order No."` holds the blanket order's `"No."` and its `"Blanket Order Line No."` holds the blanket line's `"Line No."`. This is the link that makes posting the order update `"Quantity Shipped"` and `"Quantity Invoiced"` on the blanket line — the tests post a called-off order and check exactly that.
5. Only the requested line is called off. A blanket order with several lines must yield an order that contains the target line's tranche and nothing else, no matter what state its other lines are in.
6. The blanket order survives as an open agreement: after a call-off it still exists as a `Blanket Order` document, and its line quantities are unchanged.
7. `CallOff` may be called again on the same line for as long as something remains, and the whole remainder may be taken in one final call-off.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The tests build real blanket sales orders with the standard libraries — generated quantities and unit prices, a fresh customer and item per test, so hardcoded numbers fail — call off a tranche and grade the result: that the returned number identifies a real sales order for the blanket order's customer, that the order carries exactly one line with the blanket line's item and the called-off quantity, and that the line's `"Blanket Order No."` and `"Blanket Order Line No."` point back at the blanket line. One test puts two lines on the blanket order, calls off the *second* one, and checks that the created order carries only that line's item and tranche, that its `"Blanket Order Line No."` names that line, and that nothing at all was called off against the first line; another applies `RemainingOnBlanket` to both lines of such a document and expects only the called-off line to have moved. Others check that the blanket order is still there afterwards with its line quantity untouched, then post a called-off order in full and assert `"Quantity Shipped"` and `"Quantity Invoiced"` on the blanket line. `RemainingOnBlanket` is graded on an untouched line, on a line with an open unposted call-off, after that call-off has been posted in full, after one has been posted as shipped but not invoiced — the call-off order line is still there with nothing outstanding, and the tranche must still be subtracted exactly once — and after the whole quantity has been taken. The rejections are graded with `asserterror`: zero, a negative quantity, one unit more than the line quantity, and one unit more than what is left after an earlier call-off — each must carry the message fragment named above, and must leave the blanket line with no extra call-off order behind it. Error matching is case-insensitive; the quoted fragments must appear somewhere in the message.

## Learn More

- [Sales](https://learn.microsoft.com/en-us/dynamics365/business-central/sales-manage-sales) — where a blanket agreement sits among the other sales documents, and which of them records a commitment delivered over several shipments.
- [Posting sales](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-post-sales) — what posting a sales order actually writes, and why a called-off order must be attached before it is posted.
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods) — `Validate` versus a plain assignment, and why it matters on document lines that keep derived quantities in step.
- [SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — walking the lines that belong to one document, or to one blanket line.
