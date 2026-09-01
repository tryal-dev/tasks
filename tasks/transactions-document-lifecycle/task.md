# Document Lifecycle: Open, Released, Posted

Every document in Business Central — sales order, purchase invoice, warehouse shipment — lives inside a status state machine: while it is `Open` you may edit it, once it is `Released` the warehouse can act on it, and after posting it is history that nothing may touch. The guards that keep each action legal only in the right status are what make an ERP trustworthy. This task is that state machine in miniature.

The starter ships two finished data objects. Do not rename them or their fields — the grading tests bind to every name below character for character.

## The objects you get

- Table `"Lifecycle Document"` — primary key `"No."` (Code[20]); fields `Description` (Text[50]), `Amount` (Decimal), `Status` (enum `"Lifecycle Document Status"`, defaults to `Open`), `"Posted On"` (Date).
- Enum `"Lifecycle Document Status"` — values `Open`, `Released`, `Posted`.

## Requirements

Implement the three actions in the codeunit `"Document Lifecycle"`, keeping exactly these signatures:

```al
procedure Release(var LifecycleDocument: Record "Lifecycle Document")
procedure Reopen(var LifecycleDocument: Record "Lifecycle Document")
procedure Post(var LifecycleDocument: Record "Lifecycle Document")
```

The transition rules — this is the whole matrix, there are no hidden cases:

1. `Release` is legal only when `Status` is `Open`: it moves the document to `Released`. A document whose `Amount` is zero must not release — fail with the standard field-guard error: the message names `Amount` and contains `must have a value` (exactly what `TestField` produces).
2. `Reopen` is legal only when `Status` is `Released`: it moves the document back to `Open`.
3. `Post` is legal only when `Status` is `Released`: it moves the document to `Posted` and stamps `"Posted On"` with the session's work date (`WorkDate`) — never with today's calendar date.
4. Every illegal transition fails with the standard field-guard error (exactly what `TestField` produces): the message names `Status` and the one status the action requires:
   - `Release` on a document that is not `Open` — error text contains `Status must be equal to 'Open'`.
   - `Reopen` or `Post` on a document that is not `Released` — error text contains `Status must be equal to 'Released'`.
   - Posted is final: no action ever leaves it — the same guards reject all three actions there.
5. A successful action updates both the `var` record you were handed and the database — a caller must see the new status on its own variable without re-reading, and the change must survive a fresh `Get`.
6. A failed action changes nothing: the document keeps its status in the database, and a failed `Post` leaves `"Posted On"` empty.
7. The open/released cycle is repeatable: a document can be released, reopened and released again any number of times, and still post.

## What the tests check

One test per cell of the 3×3 action-by-status matrix — the three legal transitions (asserted on the `var` parameter and on a fresh read from the database) and all six illegal ones (error fragment plus untouched status) — plus the zero-`Amount` release guard, the `WorkDate` stamp on `"Posted On"`, and a release–reopen–release–post round trip. Error matching is case-insensitive; the quoted fragments must appear in the message, quotes included. The illegal-transition tests all use documents with a non-zero `Amount`, so the order in which you check the status and the amount never decides a test.

## Learn More

- [Field Calculation Methods (CalcFields, TestField, Validate, and More)](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods)
- [System.WorkDate([Date]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-workdate-method)
- [Extensible Enums](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums)
- [Insert, Modify, ModifyAll, Delete, and DeleteAll Methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods)
