# What Does the Total Line Total?

The Chart of Accounts is more than a list of posting accounts: Total and End-Total lines carry a `Totaling` expression such as `1000..1999|2500`, and the figure shown on such a line is the sum of the accounts that expression names. Finance wants that figure available to code — for any total line, for any period — so a custom statement can print exactly what the chart would show.

## Requirements

Create a **codeunit** named `"G/L Totaling Balance"` with one public procedure:

```al
procedure TotalingBalance(AccountNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
```

Rules:

1. `AccountNo` always identifies an existing G/L account. Its `Totaling` field holds a standard G/L account filter expression — single account numbers, `..` ranges and `|` unions, exactly as the Chart of Accounts accepts them (for example `1000..1999|2500`).
2. The result is the net change of every **Posting**-type account whose number satisfies that expression: the signed sum of their G/L entry amounts (credits are negative and reduce the figure), counting only entries with a posting date from `FromDate` through `ToDate`, **both boundary days included**.
3. Accounts of any other type that fall inside the expression — Heading, Begin-Total, Total, End-Total — contribute nothing of their own. In particular, when an End-Total's Totaling embraces another Total account, every posting entry is counted exactly once: a subtotal inside the range must not be added on top of the entries it already summarises.
4. An account whose `Totaling` is blank totals no accounts and returns 0 — even when that account is itself a Posting account with entries inside the window. The procedure evaluates the Totaling expression, never the account's own entries.
5. A window that no matching entry falls into returns 0; that is a normal answer, not an error. `FromDate` and `ToDate` are always real dates with `FromDate` on or before `ToDate`.
6. Pick object IDs in the range 50100–50199 and reference other objects **by name, never by ID**.

## What the tests check

The grading tests seed their own G/L accounts with numbers like `TRYAL-T1-1000` (so the expressions under test read `TRYAL-T1-1000..TRYAL-T1-1998` and `TRYAL-T2-1000..TRYAL-T2-1999|TRYAL-T2-2500`), post general-journal lines to them with amounts generated at run time — the answers cannot be hardcoded — and assert **exact figures** for: a `..` range with three posting accounts inside (one carrying a negative amount) and one just outside it; a `range|single` union with a posting account between the two parts that must not count; a Heading and a Begin-Total inside the range next to two posting accounts; an End-Total whose Totaling embraces both a Total account and its own number (expect each entry once); a Posting account with a blank Totaling and entries of its own (expect 0); a window whose `FromDate` and `ToDate` land exactly on posting dates, with further entries one day outside each boundary (the boundary days count, the days outside do not); and a window containing no entries (expect 0). The tests run in a real company, so other accounts and entries exist — the seeded numbers carry unique markers, and every figure must come purely from the rules above.

## Learn More

- [Understanding the Chart of Accounts](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-chart-of-accounts) — the five account types and what a Total or End-Total line stands for.
- [Set up or change the chart of accounts](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-setup-chart-accounts) — the Totaling field, and how Indent fills it for End-Total accounts.
- [Entering criteria in filters](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters) — the `..` and `|` syntax a Totaling expression is written in.
- [FlowFilters overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfilter-overview) — how a date window is fed into a calculated field.
