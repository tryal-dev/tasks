# Inject a Project Dimension into Posting

Your ISV app tracks which project every sale belongs to, and finance wants to slice ledger entries by project in every dimension-based report. A text column on the posted tables won't do: Business Central analytics run on dimensions, and dimension values live in shared dimension sets — never as free text on an entry. Your job is to make a header field arrive on every posted line as a real dimension, from the outside, without touching base code.

## Requirements

1. Create a **table extension** for the `Sales Header` table with a field named `"Project Code"` of type `Code[20]`.
2. Create a **codeunit** — its name is up to you (not graded) — that injects the dimension pair `PROJECT` = the header's `"Project Code"` into the dimensions of every sales line of a document whose header carries a non-blank `"Project Code"`, so that every G/L entry produced for those lines at posting time carries that pair in its dimension set.
3. Injection must extend, never replace: every dimension the standard logic already gave the line — the customer's default dimensions included — must still be in the posted entry's dimension set.
4. The global-dimension shortcut fields (`"Global Dimension 1 Code"` / `"Global Dimension 2 Code"` on the posted entries) must stay consistent with what the entry's dimension set holds for the two global dimensions.
5. Dimension sets are shared and immutable: lines with identical dimension combinations must end up pointing at one and the same `"Dimension Set ID"`. Never insert `Dimension Set Entry` rows with hand-picked set IDs.
6. A blank `"Project Code"` means standard behavior, untouched: no `PROJECT` pair anywhere, and the line's dimensions exactly as base BC left them.

You can rely on two things: the `PROJECT` dimension and the dimension value placed in `"Project Code"` always exist before your code runs, and `"Project Code"` is always filled in before lines are added to the document. Validating the field against the `PROJECT` dimension values (for example, a table relation) is good practice but not graded.

Pick all object and field IDs in the 50100–50199 range, and reference other objects by name, never by ID. No page extensions are needed — grading reads and writes the fields in code. Captions are good practice but not graded.

## What the tests check

The tests get-or-create the `PROJECT` dimension, generate dimension values, create customers with default dimensions, build sales orders with G/L account lines (on freshly created accounts that carry no default dimensions of their own — the line's dimensions come from the header alone, so make sure your injection still runs for such lines), and post them through the standard posting routine. They assert that the revenue G/L entry points at a real (non-zero) dimension set containing the `PROJECT` pair with exactly the header's `"Project Code"`, that the customer's default dimensions are still in that set, and that the posted entry's global-dimension shortcut fields match what its own dimension set says (the tests configure the company's setup so `PROJECT` is global dimension 2 and a default dimension sits on global dimension 1). They also assert that two lines with identical dimensions share one `"Dimension Set ID"` on the posted invoice lines, that a blank `"Project Code"` leaves the posted dimension set free of any `PROJECT` pair, and that a blank-code order posted after a project order for the same customer still gets a `PROJECT`-free set of its own with a different `"Dimension Set ID"` than the project order's entry (existing sets must never be edited in place). Finally, they check that `"Project Code"` is declared as exactly `Code[20]` by checking its maximum length.

## Learn More

- [Work with dimensions](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-dimensions) — dimension sets, global and shortcut dimensions, and default dimensions: the model this task wires into.
- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al) — how publishers, subscribers, and raised events fit together.
- [Subscribing to events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events) — writing a subscriber method in your own codeunit.
- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — adding the `"Project Code"` field to `Sales Header`.
