# Is That Filter a Range?

The Customer Ledger Entries export prints one header line saying which posting dates the file covers. Users filter the entries page however they like and click Export; the export receives their filtered record and has to describe its `"Posting Date"` filter in plain words. Two tickets came in this week. A user who filtered on two specific days with an either/or list (`01/05/26|01/19/26`) got a runtime error instead of a file. Another who filtered on a single day got a header reading `from 2026-01-15 to 2026-01-15`. Both bugs have the same cause: the export assumes every date filter is a simple range and reads its bounds without ever asking whether that is true.

## Requirements

Create a **codeunit** named `"Date Filter Describer"` with one public procedure:

```al
procedure DescribeDateFilter(var CustLedgerEntry: Record "Cust. Ledger Entry"): Text
```

It describes the filter currently applied to the `"Posting Date"` field of the record it receives. Rules:

1. No filter on `"Posting Date"` returns `all dates`. Filters on other fields (`"Customer No."`, `Open`, ...) are irrelevant — only the `"Posting Date"` filter counts.
2. A filter that is a range covering exactly one day returns `on ` followed by that day, e.g. `on 2026-01-15`. This includes a range written with two equal bounds (`01/15/26..01/15/26`), not only a filter set from a single date.
3. A filter that is a range covering more than one day returns `from ` + first day + ` to ` + last day, e.g. `from 2026-01-01 to 2026-01-31`.
4. Any other filter — an either/or list such as `01/05/26|01/19/26`, a comparison such as `>=01/01/26`, an exclusion such as `<>01/15/26` — is not a range and has no bounds to report: return the filter text exactly as `GetFilter` reports it for the `"Posting Date"` field.
5. Dates are rendered as `yyyy-mm-dd` (`2026-01-15`), whatever date format the session uses. The words `all dates`, `on`, `from` and `to` are lowercase, separated by single spaces, and nothing else is added.
6. The procedure never raises an error, and the caller's record comes back with exactly the filters it arrived with.

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests build a `"Cust. Ledger Entry"` record variable, apply one filter with `SetRange` or `SetFilter`, call `DescribeDateFilter` and compare the returned text **character for character** with the expected description. Every date is generated at run time, so no description can be hardcoded. The cases: no filter at all; filters on `"Customer No."` and `Open` only (still `all dates`); a single date set with `SetRange`; a two-date range set with `SetRange`; a range written as `date..date` with both bounds the same day (expected `on`, not `from ... to`); a `|` list; a `>=` comparison; a `<>` exclusion — each of the last three expected verbatim as `GetFilter` renders it, with the test reading that text before your code runs. Two more tests snapshot `GetFilters` on a record filtered on both `"Customer No."` and `"Posting Date"` — once with a `|` list, once with a `date..date` range whose bounds are the same day — call your procedure and assert the filters are unchanged, character for character. A submission that raises an error for any of these inputs fails that test with the error's own text.

## Learn More

- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — how the bound-reading methods behave, including the documented case in which they refuse.
- [Record.GetFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getfilter-method) — the text rule 4 must return, and empty exactly when rule 1 applies.
- [Record.HasFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-hasfilter-method) — read its one-line description carefully before relying on it for rule 1.
- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property) — the standard formats, one of which renders a date as `yyyy-mm-dd`.
