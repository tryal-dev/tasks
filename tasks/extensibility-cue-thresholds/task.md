# Cue Styles from Thresholds

Finance's role center shows a Receivables cue with the company's total overdue amount, and management wants its colored indicator to work for everyone: green while the amount is comfortable, yellow once it passes a warning level, red past a critical level. Administrators can set this up per company in the UI, but your app must ship it as code — a one-time registration plus a helper that any code can ask "which style applies to this amount right now?". No page or role center is needed in this task; it is pure table + enum logic.

## Requirements

1. Create a **table** named `"Receivables Cue"` with a field named `"Overdue Amount"` of type `Decimal`. The rest of the table design is up to you, but the grading inserts a record without setting any key fields, so the primary key must accept its default values.
2. Create a **codeunit** named `"Receivables Cue Style"` with two public procedures:

```al
procedure RegisterThresholds(LowerThreshold: Decimal; UpperThreshold: Decimal): Boolean
procedure StyleFor(Amount: Decimal): Enum "Cues And KPIs Style"
```

Rules the tests enforce:

- `RegisterThresholds` records a **company-wide** (all users) indicator setup for the `"Overdue Amount"` cue field with exactly three bands: `Favorable` for low amounts, `Ambiguous` for the middle band, `Unfavorable` for high amounts, split by the two thresholds. It returns `true` when the setup was recorded.
- If a setup for this cue field already exists, `RegisterThresholds` must leave the existing setup untouched and return `false`.
- `StyleFor` resolves the style for an amount from the recorded setup: strictly below `LowerThreshold` → `Favorable`; from `LowerThreshold` up to and including `UpperThreshold` → `Ambiguous`; strictly above `UpperThreshold` → `Unfavorable`. Note the boundaries: an amount exactly equal to either threshold is `Ambiguous`.
- When nothing has been registered for the cue field, `StyleFor` returns `None`.
- The registration must outlive the codeunit instance that made it: the tests call `RegisterThresholds` and `StyleFor` on two separate instances of your codeunit, so thresholds kept in codeunit variables will not pass.

Two things worth knowing before you start: the storage behind the admin's cue indicator setup is internal to the System Application, so your code cannot read or write it directly — the platform offers extensions a small supported API for both directions, and finding it is the exercise. The tests always register with `LowerThreshold` < `UpperThreshold`; other combinations are not graded.

Pick all object IDs in the 50100–50199 range and reference every object outside your submission by name, never by literal ID. Captions are good practice but not graded.

## What the tests check

The tests insert a `"Receivables Cue"` record with a generated `"Overdue Amount"` and read it back; register generated thresholds through one instance of `"Receivables Cue Style"` and resolve amounts through another — below, between, above, and exactly at each of the two thresholds; check that the first registration returns `true`, that a second registration returns `false` and leaves the first thresholds in force; and check that `StyleFor` returns `None` when nothing was registered. The tests also verify the interop both ways: after `RegisterThresholds` succeeds, the registration must be visible to the platform's own cue-indicator setup (a platform-level attempt to record a setup for the same cue field is rejected as a duplicate), and `StyleFor` must resolve a setup that the tests record through the platform's cue-indicator API directly — so keeping thresholds in your own table or variables will not pass.

## Learn More

- [Creating Cues and Action Tiles on Role Centers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-cues-action-tiles) — what a cue field is and how role centers surface one.
- [Set Up a Colored Indicator on Cues](https://learn.microsoft.com/en-us/dynamics365/business-central/admin-how-set-up-colored-indicator-on-cues) — the exact three-band threshold semantics your registration reproduces, seen from the admin side.
- [Table object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object) — defining your cue table and its fields.
- [Enum data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-data-type) — working with enum values like the style your helper returns.
