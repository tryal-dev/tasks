# Stop at the First Bad Line

Your intercompany import lands draft journal batches of tens of thousands of lines, and every batch is pre-checked before posting. Telemetry shows the check dragging entire batches across the wire even when the third line already fails — the AL loop exits early, but the money was spent by the read that fetched everything up front. The sibling routine that counts a batch's defects has the opposite nature: it genuinely must see every line. Same table, two different reads — your job is to choose correctly for each.

## Requirements

Your starter includes the table `"Draft Journal Line"` (`"Batch Name"`, `"Line No."`, `"Account No."`, `Amount`; primary key `"Batch Name", "Line No."`). Submit it unchanged — the grading tests seed it directly.

Implement the **codeunit** named `"Journal Preflight"` with two public procedures:

```al
procedure CheckBatch(BatchName: Code[10]): Integer
procedure CountDefects(BatchName: Code[10]): Integer
```

Rules:

1. A line is **defective** when its `"Account No."` is empty **or** its `Amount` is exactly 0. A negative amount is valid.
2. `CheckBatch` returns the `"Line No."` of the defective line with the **lowest** line number in the batch, or 0 when the batch has no defective line — including a batch with no lines at all.
3. `CountDefects` returns how many lines of the batch are defective; a line that breaks both rules counts **once**.
4. Lines belonging to other batches never influence either answer.
5. Neither procedure ever raises an error — an unknown batch name is a normal input.
6. **The budget:** grading seeds a 20,000-line batch whose third line is the only defect. After a warm-up call, one `CheckBatch` call on that batch must read **at most 2,000 rows**, measured with `SessionInformation.SqlRowsRead` around the single call. The verdict is sitting in the first handful of lines — a read that asks SQL for the complete filtered set pays for all 20,000 rows no matter where your loop stops, and fails. `CountDefects` is graded on a 3,000-line batch with its own generous ceiling of **12,000 rows**: counting legitimately needs the full pass, and a single whole-batch read fits that budget with room to spare.

## What the tests check

The correctness tests seed `TRYAL-*` batches with generated line numbers, amounts, and defect counts, so hardcoded answers have nothing to latch onto: the first-defect tests plant a later second defect that must not win and a defective neighbour batch that must not leak, the counting tests mix blank-account and zero-amount defects and include a line breaking both rules (counted once), and clean, negative-amount, and empty batches must come back as 0. The two budget tests warm up with one throwaway call, then invalidate the server's data cache with a decoy write plus `SelectLatestVersion` — a repeated call served from cache memory reads zero rows, so cached reads can't smuggle a whole-set fetch past the budget — and snapshot `SessionInformation.SqlRowsRead` around one graded call each: `CheckBatch` over the 20,000-line batch under the 2,000-row ceiling, `CountDefects` over the 3,000-line batch under the 12,000-row ceiling, both also asserting the returned answer is still correct.

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## Learn More

- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods) — how AL's record-search methods differ and when each fits.
- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — scoping a read to one batch before touching any rows.
- [SessionInformation.SqlRowsRead() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-sqlrowsread-method) — the counter the budget tests snapshot around the graded call.
- [Performance articles for developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer) — the AL performance patterns behind budgets like this one.
