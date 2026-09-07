# Say It Like the Platform

Warehouse runs a release checklist before an order goes out the door, and when it refuses one the picker gets `Ship-to code missing` - no order number, no field name, nothing to click, and the German warehouse gets it in English. Business Central already knows how to say every one of those things properly: it names the field, the table and the exact document, translates itself, and even offers to open the record. Your job is to make the checklist speak like the platform.

## Requirements

The starter ships a **codeunit** named `"Release Checklist"` with one public procedure - keep the name and the signature exactly:

```al
procedure CheckReadyToShip(var SalesHeader: Record "Sales Header")
```

It already refuses a sales order that is not ready to ship, but every refusal is a hand-written text. Rewrite the three checks so that each refusal is the message Business Central itself raises when a record is asked to check one of its own fields.

Rules:

1. The checks run in this order, and the first one that fails raises the error: `"Ship-to Code"` must not be blank; `Status` must be `Released`; `"Shipment Date"` must not be in the past.
2. "In the past" means earlier than the work date, `WorkDate()`. The work date itself and any later date are fine. Compare against the work date, not `Today` - the tests first move the work date away from today's date, then set every shipment date relative to `WorkDate()`, and always give the document one.
3. A blank `"Ship-to Code"` is reported with the platform's standard message for a field that must have a value.
4. A `Status` other than `Released` is reported with the platform's standard message for a field that must be equal to a given value - the one that names the required value and ends by stating the current one.
5. A past `"Shipment Date"` is reported with the platform's standard field message built around your own rule text: the field caption, then your text, then the table caption and the document's primary key, then a period. Your text is exactly `must not be in the past`; the period at the end is added by the platform, so do not add your own.
6. A document that passes all three checks comes through unchanged: nothing on the record passed in, and nothing on the stored sales order, may differ from before the call.

All three messages carry the field caption, the table caption and the primary key of the document (`Document Type` and `No.`) automatically, which is why the checks have to run on the record itself.

## What the tests check

The tests first move the work date away from today's date (to 15 January 2024), then create real sales orders and run `CheckReadyToShip` on them. For every refusal they generate the expected wording by asking the platform for the same field message on a copy of the same document, then compare your error text to it character for character - a hand-written message, however close, fails, and so does a rule text with a period of its own. They cover a blank Ship-to Code, a status of Open, Pending Approval or Pending Prepayment (chosen at random), a shipment date some days before the work date, and the order of the checks when several fail at once. Two documents that are ready must pass without an error - one shipping on the work date, one some days later; a check against today's date refuses both - and the first of them is re-read from the database and compared field by field with a snapshot taken before the call.

Pick object IDs in the range **50100–50199** and reference other objects **by name, never by ID**.

## Learn More

- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling) — the error-handling strategies and methods AL offers, and what raising an error does to the running transaction.
- [User experience guidelines for errors](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-error-handling-guidelines) — what a good message says, and why one that names the record and the field beats "missing".
- [Record data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type) — every method a record offers, including the ones that know their own captions and primary key.
- [Handle errors by using application language in Dynamics 365 Business Central](https://learn.microsoft.com/en-us/training/modules/handle-errors/) — the Learn module on errors, messages and dialogs in AL.
