# Filters That Understand TODAY, WEEK and ME

Your team ships a follow-up task list, and the feedback is unanimous: filtering feels broken. In every standard Business Central filter box a user can type `today`, `week` or `me` and the system quietly turns the word into a real date, a date range or their own user id — but your feature takes those words at face value. `today` crashes the date filter, and `me` politely finds nobody. Your job is to give raw user input that same translation step before it ever reaches a filter.

## Requirements

The starter ships a table named `"Follow-up Task"` — keep its name, field names and primary key exactly as they are, because the grading tests write rows into it directly:

| Field | Type |
|---|---|
| `"Entry No."` | `Integer` (primary key) |
| `"Description"` | `Text[100]` |
| `"Due Date"` | `Date` |
| `"Assigned To"` | `Text[50]` |
| `"Created At"` | `DateTime` |

Complete the **codeunit** named `"Follow-up Task Filters"` with three public procedures:

```al
procedure ApplyDueDateFilter(var FollowupTask: Record "Follow-up Task"; DateInput: Text)
procedure ApplyAssignedToFilter(var FollowupTask: Record "Follow-up Task"; AssignedToInput: Text)
procedure ApplyCreatedAtFilter(var FollowupTask: Record "Follow-up Task"; DateTimeInput: Text)
```

Each procedure resolves the raw input the way Business Central's own filter boxes would, then applies the result as the filter on the matching field of the passed record. The graded contract:

1. `ApplyDueDateFilter` with `today` must leave `"Due Date"` filtered to exactly today's date: reading the filter back with `GetFilter` must return exactly the text that `Format(Today())` produces.
2. `tomorrow` resolves the same way to tomorrow's date. Token words are case-insensitive — `Tomorrow` and `TOMORROW` work like `tomorrow`.
3. `week` becomes the current calendar week as a range: `GetFilter` must return the `Format` of the week's Monday, then `..`, then the `Format` of the week's Sunday (in `DateFormula` terms: `CalcDate('<-CW>')` through `CalcDate('<CW>')`).
4. In an input like `today|tomorrow`, each side of the `|` is resolved on its own, so `GetFilter` returns both resolved dates joined by `|` and the filter matches tasks due on either day.
5. Input that is already a plain date — for example the text `Format` produces for some date — keeps working: the filter matches exactly that date and `GetFilter` returns that same text.
6. `ApplyAssignedToFilter` with `me` or `user` (again any casing) filters `"Assigned To"` to the current user: `GetFilter` must return exactly what `UserId()` returns. Any other input, such as a colleague's code, is applied to the field unchanged.
7. `ApplyCreatedAtFilter` with `today` filters `"Created At"` to the whole of today — from midnight through the last instant of the day — so tasks created at any time today survive the filter and tasks from yesterday or tomorrow do not. This one is graded by which records the filter lets through, not by the exact filter text.
8. None of the procedures may raise an error for the inputs described above.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

The grading tests set the session's work date to today's date before each date-token test — so resolving a token relative to the work date and relative to today's date gives the same answer. They seed `"Follow-up Task"` rows with due dates on, before and after the resolved dates — including rows exactly on the Monday and Sunday edges of the current week — then call one procedure with one input and assert both the exact `GetFilter` text (computed at run time from `Today()`, `CalcDate` and `UserId()`) and the exact record count the filter leaves visible. One date is generated at run time, so a solution that only special-cases the sample tokens still has to keep ordinary input working, and the assigned-to tests seed rows for the real current user next to a decoy assignee.

## Learn More

- [Sort, search, and filter data in lists](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-enter-criteria-filters) — the user-side behavior you are replicating, including the filter tokens users type every day.
- [Work with calendar dates and times](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-enter-date-ranges) — what users are used to typing into date filters, and why they expect your feature to understand it.
- [Entering criteria in filters](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters) — the filter expression syntax your resolved text must end up in.
- [Record.GetFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getfilter-method) — reading back the filter the tests assert on.
