# A Report That Prints Nothing

Finance wants a nightly job that marks every customer with an overdue balance, so the collections team can work a short list the next morning. Nothing is printed — the job only changes data. In Business Central that is still a report object: a **processing-only report** gets the data-item loop, the caller's filters and the trigger sequence for free, and a job queue entry or a page action can run it without anyone answering a request page.

## Requirements

The starter already contains a table extension `"Customer Follow-Up"` that adds the Boolean field `"Follow-Up Required"` to the `Customer` table. Keep it as it is.

Create a **report** named `"Flag Overdue Customers"` with:

- `ProcessingOnly = true` and `UseRequestPage = false` — no layout and no request page, so the report starts the moment it is called.
- one data item on the `Customer` table, whose triggers do all the work.
- a public procedure `procedure GetFlaggedCount(): Integer`.

Rules:

1. The caller decides which customers are in scope. The report is run on a `Customer` record that already carries filters — a filter on `No.` and a `Date Filter` — and every one of those filters must stay in force, the `Date Filter` FlowFilter included. Your report narrows that selection to customers whose `Blocked` field is blank; it never resets or replaces what the caller set. `OnPreDataItem` runs once, before the first record and after the caller's view has been applied, so a filter added there narrows the selection.
2. For each customer that is left, calculate the FlowField `"Balance Due (LCY)"` (its caption reads *Overdue Balance (LCY)*: the sum of the customer's detailed ledger entry amounts whose due date lies on or before the end of the `Date Filter`). A FlowField is 0 until it is calculated. `OnAfterGetRecord` runs once per record and is where this belongs.
3. If the balance due is not greater than zero, skip the customer with `CurrReport.Skip()` and leave the record exactly as it is — a skipped customer that already carries the flag keeps it. Otherwise set `"Follow-Up Required"` to true and save the customer.
4. The report only ever sets the flag; clearing it is a human decision.
5. `GetFlaggedCount()` returns how many customers the most recent run flagged — every customer the run did not skip. A customer that already carried the flag and still has a balance due is flagged again and counted. A run that flags nobody returns 0.

Report data items also have an `OnPostDataItem` trigger that runs once after the last record; it is where a batch job typically finishes its bookkeeping, and this report hands its total back through `GetFlaggedCount()`.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID. A `Caption` on the report is good practice but not graded.

## What the tests check

The tests create customers and insert detailed customer ledger entries directly, then run your report on a `Customer` record filtered to specific customer numbers with `Date Filter` set to `0D..WorkDate()`. Most tests run it as a job queue would — `Report.Run(Report::"Flag Overdue Customers", false, false, Customer)` — and then read the customers back; the count tests use a report variable with `SetTableView`, `UseRequestPage(false)` and `RunModal()`, then call `GetFlaggedCount()`. They assert that an unblocked customer with a positive balance due is flagged; that a customer with no entries, a customer with a credit balance, and a customer whose only invoice falls due after the work date are not; that customers blocked as `Ship`, `Invoice` or `All` are never flagged; that a customer outside the caller's `No.` filter is untouched; that a skipped customer that already carried the flag keeps it; and that `GetFlaggedCount()` equals the number of customers flagged in that run (a random count, so it cannot be hardcoded) and is 0 when every customer is skipped. Two further tests read the report's metadata and require `ProcessingOnly = true` and `UseRequestPage = false`.

## Learn More

- [Report triggers and runtime operations](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers) — the order in which OnPreDataItem, OnAfterGetRecord and OnPostDataItem fire for a data item.
- [ProcessingOnly property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-processingonly-property) — what turns a report into a batch job with no output.
- [UseRequestPage property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-userequestpage-property) — running without a request page, and how callers can override it.
- [Report.Skip method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-skip-method) — dropping the current record from inside a data item trigger.
