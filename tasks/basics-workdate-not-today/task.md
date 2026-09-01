# The Date Nobody Set

On the third of February the bookkeeper sets her work date back to 31 January to finish the January close — exactly what the **Work Date** field on **My Settings** is for. Then everything goes wrong: every invoice she creates still defaults to 3 February, the "backdated document" warning fires on every January posting, and the overdue report counts three extra days on every open invoice.

The cause is one word. The code reads `Today` — the calendar clock — where it should read the session's **work date**: the date users set on My Settings, the one the `w` shortcut enters in any date field, and the one AL exposes through `WorkDate`. When nobody changes it, the work date *is* today, which is why the bug never showed up on the developer's machine.

Your job is a small codeunit that answers three everyday date questions from the work date.

## Requirements

Create a **codeunit** named `"Work Date Policy"` with three public procedures:

```al
procedure DefaultPostingDate(): Date
procedure IsBackdated(PostingDate: Date): Boolean
procedure DaysOverdue(DueDate: Date): Integer
```

Rules:

1. `DefaultPostingDate` returns the session's work date — never the calendar date.
2. `IsBackdated` returns `true` when `PostingDate` lies **strictly before** the work date. A posting date equal to the work date or after it is not backdated. A blank posting date (`0D`) is not backdated either — nothing has been entered yet, so there is nothing to flag.
3. `DaysOverdue` returns the number of whole days by which `DueDate` lies before the work date: a due date ten days before the work date is 10 days overdue. A due date on the work date, after the work date, or blank (`0D`) is 0 days overdue — the result is **never negative**.
4. The answers must follow the work date: when the work date moves, the same inputs give different answers. Reading the clock (`Today`, `CurrentDateTime`) cannot satisfy this — it agrees with the work date only on the one day nobody changed it.

Note the blank date: `0D` is smaller than every real date, so a plain comparison would call it backdated and a plain subtraction would report it centuries overdue. Decide the blank case before you compare or subtract.

## What the tests check

The grading tests set the work date themselves with `WorkDate(20240115D)` before each call and assert exact values against 15 January 2024: the default posting date is that date; 14 January 2024 and 31 December 2023 are backdated while 15 January, 16 January and a blank date are not; due dates of 5 January 2024 and 20 December 2023 are 10 and 26 days overdue, and the due date itself, a randomly chosen future due date and a blank due date are 0. Three further tests move the work date to a random day in 2019–2021 and expect the answers to move with it: the default posting date equals the new work date, a posting date after it is not backdated, and a due date a random number of days before it is overdue by exactly that many days. A solution based on `Today` fails those tests on every day of the year.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## Learn More

- [System.WorkDate([Date]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-workdate-method) — reads and sets the session work date; the method the tests use to move it.
- [System.Today() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-today-method) — what the clock actually returns, and why it depends on the user's time zone.
- [About dates in Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-about-dates) — Microsoft's own note on the trouble with defaulting a posting date from `Today`.
- [Change basic settings — Work date](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-change-basic-settings#work-date) — where users set the work date and how the client shows that it differs from today.
