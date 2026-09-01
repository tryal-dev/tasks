# Pass Filters Along

The customer list just got a new "Audit Current View" action: whatever the user has filtered down to — a city, a salesperson, a balance range — the action hands its filtered `Customer` record to a helper codeunit, which reports on exactly that view: how many customers it holds, how many of them are blocked, and which filters produced it.

The first prototype caused a memorable support ticket: "after I run the audit, my customer list shows only blocked customers." The audit code had scribbled its own filters straight onto the caller's record — the report was right, but the caller's view was ruined.

## Requirements

Create a **codeunit** named `"Customer View Reporter"` with three public procedures:

```al
procedure CountInView(var FilteredCustomer: Record Customer): Integer
procedure CountBlockedInView(var FilteredCustomer: Record Customer): Integer
procedure DescribeView(var FilteredCustomer: Record Customer): Text
```

Rules:

1. `CountInView` returns how many `Customer` records match the filters currently applied to `FilteredCustomer`. With no filters applied it returns the company's full customer count.
2. `CountBlockedInView` returns how many customers are blocked in any way — their `Blocked` field holds anything other than the blank option — among the customers admitted by the view's **other** filters: if the caller's view itself carries a `Blocked` filter, your count replaces that one filter with "any blocked state" instead of intersecting with it (the caller's own record must still come back with its filter intact, as rule 4 demands). A view containing no blocked customers yields 0.
3. `DescribeView` returns the standard textual rendering of every filter currently applied to `FilteredCustomer` — the exact text Business Central itself produces when asked to describe a record's applied filters. The grading test renders the caller's filters with the platform's own mechanism and compares your text **character for character**. An unfiltered record yields empty text.
4. Every procedure hands the caller's record back **untouched**: exactly the filters it arrived with — none added, none removed — and still positioned on the same record. The caller keeps working with that variable after you return.
5. None of the procedures may raise an error.

## What the tests check

The grading tests seed customers into city names generated at run time (so no count can be hardcoded), always next to decoys outside the filtered city, and assert **exact counts**. `CountBlockedInView` faces a view mixing blocked and unblocked customers with a blocked decoy outside the view, and a view containing no blocked customers at all. `CountInView` is also called on a record with no filters and must match the full customer count. Both counting procedures are called on a record whose filter text and current position were snapshotted first, and the snapshots are verified afterwards — an implementation that narrows, widens or repositions the caller's record fails. One `CountBlockedInView` call arrives with the caller's **own** `Blocked` filter already applied on top of the city filter; that test asserts both the rule-2 count (the view's `Blocked` filter is replaced by "any blocked state", not intersected) and preservation — the caller's filter text and record count must be exactly what they were before the call. The `DescribeView` rendering test also verifies the caller's filters are unchanged after the call. `DescribeView` is compared character for character against the platform's own rendering of a two-field filter set, and must return empty text for an unfiltered record. The tests run in a real company that already contains customers — the seeded cities carry unique markers, and your counts must be driven purely by the caller's filters.

## Learn More

- [Record.CopyFilters Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copyfilters-method)
- [Record.GetFilters Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getfilters-method)
- [Record.Count Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-count-method)
- [Record.SetFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method)
