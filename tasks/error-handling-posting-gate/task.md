# The Invoice Hold

Finance sometimes needs to freeze a customer — a payment dispute, a fraud check — and while the account is frozen, nothing may be posted for them. Today that rule lives in people's heads, and every few weeks an invoice slips through. Your job is to move the rule into code: a hold flag on the customer that makes posting itself refuse to run.

## Requirements

1. Create a **table extension** that extends the `Customer` table and adds a field named `"Invoice Hold"` of type `Boolean`.
2. Create a **codeunit** named `"Invoice Hold Gate"` that enforces the hold. Base application objects must not be modified — the gate has to attach itself to the standard posting flow from the outside.
3. When any sales document (invoice, order, credit memo, …) is posted and the document's sell-to customer has `"Invoice Hold"` set, posting must fail with an error before anything is written.
4. The error message must contain the exact phrase `is on invoice hold` (note the casing) and the `"No."` of the held customer. A message like `Customer C00040 is on invoice hold and cannot post sales documents.` satisfies both.
5. A blocked posting must leave no trace: no posted sales invoice and no customer ledger entries may exist for the held customer afterwards.
6. When `"Invoice Hold"` is `false` — never set, or set and cleared again — posting must run exactly as standard Business Central would: it succeeds, and the posted documents and ledger entries appear as usual.

The grading tests always post documents where the sell-to and bill-to customer are the same, so checking the sell-to customer is sufficient. The codeunit name `"Invoice Hold Gate"` is where your gate code is expected to live, but the tests grade posting behavior, not the codeunit's name.

## What the tests check

The tests write and read back the `"Invoice Hold"` field, then post real sales documents through the standard posting routine: for a held customer they expect posting an invoice, an order, and a credit memo to fail with the message from rule 4, and they verify no posted sales invoice and no customer ledger entry exists for that customer; for a customer whose flag is `false` (including one whose hold was set and then cleared) they expect posting to succeed and the posted invoice and ledger entries to exist.

Pick object IDs in the range **50100–50199** and reference other objects **by name, never by ID**.

## Learn More

- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — how to add the hold flag to a base table.
- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — how extensions hook into standard application flows without modifying them.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — the syntax for attaching your own method to a published event.
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling) — what raising an error does to the running transaction.
