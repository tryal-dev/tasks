# Dispatch by Fully Qualified Name

Your customer's operations team keeps inventing nightly clean-up chores — reprocess stuck tickets today, recalibrate meter readings tomorrow — and until now every new chore meant redeploying the processing engine with one more hardcoded case. Business Central 28 ends that: a record can report its own fully qualified name, `RecordRef.Open` accepts one as text, and so does `Codeunit.Run`. You will build an engine whose only knowledge of tables and handlers is what a setup row tells it — the binding is data, not code.

## Requirements

The starter declares two tables — keep their names, fields and types exactly as given:

- `"Dispatch Job"` — the configuration: `Code` (Code[20], primary key), `"Target Table Name"` (Text[250], holds a fully qualified table name), `"Handler Name"` (Text[250], holds a fully qualified codeunit name), `"Current Record ID"` (RecordId).
- `"Dispatch Run Log"` — the outcome report: `"Entry No."` (Integer, primary key), `"Job Code"` (Code[20]), `"Target Record ID"` (RecordId), `Succeeded` (Boolean), `"Error Message"` (Text[2048]).

Implement this procedure in the codeunit `"Qualified Dispatch Engine"`:

```al
procedure RunJob(JobCode: Code[20])
```

Rules:

1. Fetch the `"Dispatch Job"` identified by `JobCode` (what happens for a nonexistent job code is not graded).
2. If the job's `"Target Table Name"` cannot be opened as a table, the engine must fail with an error of its own with a message that contains, with the placeholders filled in and the rest exactly as written: `Dispatch job <Code> cannot open target table <Target Table Name>` — note the casing and spacing — and it must write no log entries for that job.
3. Otherwise process every row of the target table, one row at a time: set `"Current Record ID"` on your in-memory job record to the row's RecordId (no database write is needed), then run the codeunit named by `"Handler Name"`, passing that job record as the run argument. Handlers are ordinary codeunits with `TableNo = "Dispatch Job"` that locate the row through `"Current Record ID"` — the grading tests supply them; you write none.
4. A handler that errors on a row must neither abort the run nor undo the work of rows already processed: record the failure and continue with the next row.
5. When `RunJob` returns, `"Dispatch Run Log"` must hold exactly one entry per processed row: `"Job Code"` = the job's code, `"Target Record ID"` = the row's RecordId, `Succeeded` = whether the handler ran without error, `"Error Message"` = empty on success, otherwise the error text (truncated to the field length). Give each entry a unique `"Entry No."`; the numbering scheme itself is not graded.

The engine must not reference any concrete target table or handler codeunit — the grading tests bring their own probe tables and handler codeunits, declared in the AL namespace `TryAL.Dispatch`, and register them purely as setup data. Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The tests declare two structurally different probe tables and one handler codeunit for each — one flips a ticket's status to `PROCESSED`, the other doubles a meter's decimal reading (readings are randomized) — then register jobs whose `"Target Table Name"` comes straight from `Record.FullyQualifiedName()`, commit the seeded data, and call `RunJob`. They assert: every row of the named table is transformed by the configured handler; the other table and the other job's log stay untouched; the log holds one `Succeeded` entry per processed row with an empty `"Error Message"`, linked by `"Target Record ID"`; a corrupted middle row makes its handler error, yet the run still processes the remaining rows, keeps the earlier rows' work, and logs the failing row with `Succeeded = false` and the handler's error text inside `"Error Message"`; and a job pointing at `TryAL.Dispatch.NoSuchProbeTable` fails with the exact contract error from rule 2 and writes nothing to the log.

## Learn More

- [Adopting namespaces in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-structure) — what a fully qualified name is and which BC 28 overloads accept one.
- [RecordRef.Open(Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-open-string-boolean-string-method) — opening a table from its qualified name.
- [Codeunit.Run(Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-string-table-method) — running a codeunit from its qualified name, with a record argument and the commit behavior the return value brings.
- [Record.FullyQualifiedName() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fullyqualifiedname-method) — how the tests produce the table names they register.
