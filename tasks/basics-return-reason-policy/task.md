# Make a Return Reason's Policies Stick

A return reason code is more than a label for statistics. Two fields on the **Return Reason** card carry real policy: `"Default Location Code"` names the location where goods returned for that reason are always placed — the repair bench, say — and `"Inventory Value Zero"` says those goods must not raise your inventory value, because an item that came in for repair is still owned by the customer.

Both policies are already written, in the base application, on the `"Sales Line"` table's `"Return Reason Code"` field. They only run if the code reaches that field the way the application itself puts it there. Writing the value straight into the field with `:=` stores the code and nothing else: the field's own logic never runs, the line keeps the location and the cost it already had, and the returned goods quietly land in the wrong place at the wrong value. No error is raised — the mistake surfaces only in the posted item ledger entry.

## Requirements

Create a **codeunit** named `"Return Line Registrar"` with one public procedure:

```al
procedure RegisterReturnLine(var SalesLine: Record "Sales Line"; ReturnReasonCode: Code[10])
```

`SalesLine` is an open sales **return order** line for an item; `ReturnReasonCode` is the code of a return reason that exists and has a `"Default Location Code"`. The procedure must:

1. Put the code on the line's `"Return Reason Code"` field **so that the reason's own policies take effect**. After the call the line sits at the reason's `"Default Location Code"`; a reason marked `"Inventory Value Zero"` leaves the line's `"Unit Cost (LCY)"` at 0, and a reason that is not marked leaves the item's cost on the line.
2. Save the line, so the new reason code and location are still there when the line is read back from the database and when the return order is posted.

Write no policy logic of your own. The location switch and the zero valuation belong to the base application; your job is to let them run.

Pick object IDs in the range **50100–50199**, and reference other objects **by name, never by ID**.

## What the tests check

Each test builds its own item with a generated unit cost, its own return order line at a freshly created "origin" location, and its own return reason whose `"Default Location Code"` is a second, freshly created "repair" location. After `RegisterReturnLine` they assert that the line's `"Location Code"` is the reason's default; that a zero-value reason leaves `"Unit Cost (LCY)"` at 0 while a normal reason leaves it at the item's unit cost; and that re-reading the line from the database shows the stored reason code and location. One test also listens to the base application's own `"Sales Line"` validation event for the `"Return Reason Code"` field and asserts it fired during your call — reproducing the two policies by hand on top of a plain assignment fails it. Three further tests receive and invoice the return order and assert on the resulting item ledger entry: its `"Location Code"` is the reason's default, its `"Cost Amount (Actual)"` is exactly 0 under the zero-value reason, and is not 0 under the normal one.

## Learn More

- [Record.Validate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method) — the method that puts a value into a field and calls the field's OnValidate trigger.
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods#validate-method) — a plain assignment and a validated one, side by side.
- [OnValidate (Field) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/field/devenv-onvalidate-field-trigger) — what that trigger is and when the platform runs it.
- [Process sales return orders](https://learn.microsoft.com/en-us/dynamics365/business-central/sales-how-process-sales-returns-orders) — where return reason codes sit in the return flow.
