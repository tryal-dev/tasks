# Load Only What You Read

The support team's nightly job walks every customer of a region twice: once to export a three-column phone directory, once to build the call sheet for the phone-number cleanup campaign — customers with a phone number get called, the rest get an e-mail. The output comes out right, but the DBA is unhappy: `Customer` is one of the widest tables in Business Central, and every full-record read also drags a companion-table join for each table extension installed — all of it across the wire so the job can look at three columns per row.

Your job: same output, a fraction of the traffic.

## Requirements

Your submission keeps the provided table extension `"Customer Phone Audit Ext"` exactly as shipped in the starter — it adds the Boolean field `"Phone Review Needed"` to `Customer`, and the tests probe that field by name to prove your reads skip the companion-table join.

Create a **codeunit** named `"Customer Phone Audit"` with two public procedures:

```al
procedure BuildDirectory(var Customer: Record Customer): List of [Text]

procedure BuildContactSheet(var Customer: Record Customer): List of [Text]
```

Both procedures receive a `Customer` record with the caller's filters already set and nothing read into it yet. Do the pass inside those filters, on that very record instance — the tests inspect the instance afterwards, so don't swap the work onto a copy or another object.

Rules for `BuildDirectory`:

1. Return one line per matching customer, in ascending `"No."` order: the customer's `"No."`, `Name` and `"Phone No."` joined by `|` (pipe), no extra spaces — for example `TRYAL-1|Alice Smith|555-0100`. The comparison is exact: a customer with a blank phone number still gets a line, ending in the pipe (`TRYAL-2|Bob Jones|`).
2. A filter that matches no customer returns an empty list. The procedure never raises an error.
3. **The load shape:** after the call returns, the record instance you were handed must report — the tests probe it with `AreFieldsLoaded` — that `Name` and `"Phone No."` are loaded, and that `Address`, `"E-Mail"` and `"Phone Review Needed"` are **not**. Hauling the full record shape across the wire fails this test even though the output text is identical.
4. **The statement budget:** one call must execute **at most 5 SQL statements**, no matter how many customers match. Grading measures `SessionInformation.SqlStatementsExecuted` around a single call over 30–40 customers — an implementation that goes back to the database once per customer spends 30+ statements and fails.
5. **The row budget:** the same call must read **at most 10 rows more than the number of matching customers**, measured with `SessionInformation.SqlRowsRead`. Fetching each customer a second time to pick up a missing field reads every row twice and fails.

Rules for `BuildContactSheet`:

6. Return one line per matching customer, in ascending `"No."` order, in the same pipe format — except the third column is how the campaign reaches the customer: the `"Phone No."` when it is filled in, otherwise the `"E-Mail"`. A customer with neither still gets their line, ending in the pipe.
7. A filter that matches no customer returns an empty list. The procedure never raises an error.
8. **The load shape:** after the call returns, the record instance must report `Address` and `"Phone Review Needed"` as **not loaded** — the sheet needs its three columns and the fallback, not the whole row and not the extension's companion table.
9. **The statement budget:** one call must execute **at most 2 SQL statements**, no matter how many customers match — or how many of them turn out to need the e-mail fallback. Grading measures a single call over 30–40 customers where roughly half the phones are blank. Careful: an implementation can produce exactly the right text and still quietly cost more statements than it appears to; the counters see what the output can't show.

## What the tests check

The grading tests seed customers marked `TRYAL-*` with names, phone numbers and e-mail addresses generated fresh every run, so hardcoded answers fail. Lines are compared character for character, order included; decoys are planted — a customer outside the filter, customers with blank phones, a customer with neither phone nor e-mail. The load-shape tests probe exactly the fields named in rules 3 and 8 with `AreFieldsLoaded` on the record instance they passed you. The budget tests warm the caches with one throwaway call, then invalidate the server's data cache — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle chatter past the budget — and snapshot the `SessionInformation` counters around a second call. The tests run in a real company with existing data, so your result must be driven purely by the caller's filters and the rules above.

## Learn More

- [Using partial records](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-partial-records)
- [Record.SetLoadFields([Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method)
- [Record.AreFieldsLoaded(Any,...) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-arefieldsloaded-method)
- [FAQ for Partial Records](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-partial-records-faq)
- [Performance articles for developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer)
