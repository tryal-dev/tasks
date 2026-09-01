# Archive a Record with TransferFields

Operations wants closed rental contracts out of the working table — but preserved forever, exactly as they looked on the day they were closed. That is the classic Business Central archive pattern (think `Sales Header Archive`): copy the row into an archive table with `TransferFields`, snapshot what the copy cannot carry, then delete the original.

`TransferFields` is the right tool, and this task is about its famous gotchas: it pairs fields **by field number** (same number + compatible type = copied; anything else = silently left alone), it never calculates a FlowField, and it never runs any `OnValidate` trigger.

## What you are given

The starter contains two finished tables — submit them unchanged alongside your new objects:

- Table `"Rental Contract"`: field 1 `"No."` (`Code[20]`, PK), field 2 `"Customer Name"` (`Text[100]`), field 3 `"Monthly Fee"` (`Decimal`, with an `OnValidate` that rejects negative values), field 4 `"Start Date"` (`Date`), and field 20 `"Total Charges"` — a **FlowField** summing `"Rental Charge".Amount` for the contract.
- Table `"Rental Charge"`: the charge lines behind that FlowField, keyed `"Contract No."` + `"Line No."`.

## Requirements

1. Finish table `"Rental Contract Archive"` so that `TransferFields` can carry the contract over: it needs `"No."` (`Code[20]`, PK — already there), `"Customer Name"` (`Text[100]`), `"Monthly Fee"` (`Decimal`), `"Start Date"` (`Date`), and `"Total Charges"` (`Decimal`) — plus a `Date` field named `"Archived On"` that exists **only** in the archive. Field numbers are yours to choose, but choose them knowing how `TransferFields` pairs fields.
2. In the archive, `"Total Charges"` must be a **normal** field: the archive stores a frozen snapshot of the total at archive time, because the charge lines may be cleaned up later and the archive must not depend on them.
3. Implement codeunit `"Contract Archiver"` with this exact procedure:

```al
procedure Archive(ContractNo: Code[20]; ArchivedOn: Date)
```

`Archive` must:

- copy the contract's stored fields (`"Customer Name"`, `"Monthly Fee"`, `"Start Date"`) onto an archive row with the same `"No."`;
- store the contract's **calculated** `"Total Charges"` in the archive — remember: `TransferFields` does not calculate a FlowField, and a freshly read record carries 0 in it;
- stamp the archive row's `"Archived On"` with the `ArchivedOn` parameter — `TransferFields` cannot fill a field the source table does not have;
- copy values **exactly as stored**, without running validation: a legacy contract whose `"Monthly Fee"` is negative (inserted before today's rule existed) must archive without an error and keep its negative fee;
- delete the original `"Rental Contract"` row — archiving moves the record;
- leave the `"Rental Charge"` lines untouched — a separate cleanup job owns them;
- fail with an error and write nothing when no contract with the given number exists.

## What the tests check

The tests seed contracts (with generated names, fees, dates and charge amounts), call `Archive` once, and then read your archive table directly, finding each field **by name** (so spell them exactly as listed): the copied fields, the snapshotted total (also after another charge line is added later — the archived total must not move), the `"Archived On"` stamp, the deleted original, the surviving charge lines, the raw copy of a negative legacy fee, and the error path for a missing contract number. The archived total is read straight from the field, so an archive `"Total Charges"` declared as a FlowField reads 0 and fails.

## Learn More

- [Record.TransferFields(var Record [, Boolean]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-table-boolean-method)
- [FlowFields overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields)
- [Record.CalcFields method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method)
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods)
- [Table object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object)
