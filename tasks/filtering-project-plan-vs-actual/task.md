# Project Plan vs. Actual per Task

The project manager wants a per-task progress readout: how much work was planned, how much has actually been posted, and how much is left. Sounds like three numbers per task — until you notice that on some projects the ready-made "posted so far" figures are frozen at zero while the ledger keeps filling up.

## Requirements

Create a **codeunit** named `"Project Plan vs Actual"` with three public procedures:

```al
procedure PlannedQty(ProjectNo: Code[20]; ProjectTaskNo: Code[20]): Decimal
procedure PostedQty(ProjectNo: Code[20]; ProjectTaskNo: Code[20]): Decimal
procedure RemainingQty(ProjectNo: Code[20]; ProjectTaskNo: Code[20]): Decimal
```

Rules:

1. `PlannedQty` returns the task's budgeted quantity: the sum of `Quantity` over its project planning lines whose `Line Type` is `Budget` or `Both Budget and Billable`. `Billable`-only lines are estimated invoicing, not budget — they must not count.
2. `PostedQty` returns the total quantity actually posted as **usage** on that task. Entries written by invoicing (entry type `Sale`) must not count.
3. `RemainingQty` returns planned minus posted. It goes negative when more was posted than planned — a task with usage but no plan at all reports minus its posted quantity, and its `PlannedQty` is 0.
4. Every figure is scoped to the (project, task) pair: another task on the same project, or a task with the same task number on a *different* project, must never leak into the result.
5. The figures must be correct whether or not the project uses the `"Apply Usage Link"` setting — the grading tests build both kinds of project.

Pick object IDs in the range 50100–50199, and reference base application objects by name, never by ID.

## What the tests check

The tests build real projects with the standard library: project tasks, planning lines of each line type, and usage posted through the project journal — sometimes several postings on one task, sometimes a fraction of the plan, sometimes usage on a task that has no plan, and sometimes a negative usage posting (a correction) that must reduce the posted figure. Decoys are everywhere: a second task on the same project, a second project whose task carries the identical task number, a `Billable` planning line, and `Sale` ledger entries of either sign — none of them may move your numbers. Some fixture projects apply the usage link and some do not; the expected planned/posted/remaining values are asserted exactly on both kinds.

## Learn More

- [Create projects](https://learn.microsoft.com/en-us/dynamics365/business-central/projects-how-create-jobs) — how projects, project tasks and the three planning line types fit together.
- [Walkthrough: managing projects](https://learn.microsoft.com/en-us/dynamics365/business-central/walkthrough-managing-projects-with-jobs) — plan, post usage through the project journal, and invoice a project end to end.
- [Filtering records with SetRange and SetFilter](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — the record-filtering toolbox your three procedures are built from.
- [Record.CalcSums method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcsums-method) — totalling a column of a filtered record set.
