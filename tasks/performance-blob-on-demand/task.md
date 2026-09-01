# Blobs Are Billed Separately

Operations archives every outbound document into a custom table, and each entry keeps its payload in a `Content` Blob field. Newer entries also record the payload's size in bytes at archive time; entries archived before that column existed carry `0` there, and their size can only be learned by measuring the stored payload itself. Finance wants a storage total per department — and the first attempt made the DBA flinch: the archive holds hundreds of documents, and the job dragged every single payload across the wire to add up a column of numbers it mostly already had. A Blob is never fetched with its row; every payload you ask for is billed as its own trip to the database, so the audit must ask only for the payloads it genuinely needs.

## Requirements

Keep the table `"Archived Document"` exactly as shipped in the starter — the tests seed and read it by that name. Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

The starter also ships a codeunit `"Archive Payload Audit"` with one public procedure — keep both names and this exact signature:

```al
procedure TotalPayloadBytes(var ArchivedDocument: Record "Archived Document"; DepartmentCode: Code[20]): Integer
```

Rules:

1. Consider exactly the archived documents whose `"Department Code"` equals `DepartmentCode` — the record instance arrives with no filters set and nothing read into it, so narrowing down to the department is the procedure's job.
2. Each document contributes its `"Recorded Size"` when that field is greater than `0`; otherwise it contributes the byte count of its stored `Content` payload (an empty payload contributes 0). Return the sum. A recorded size is authoritative even when the stored payload happens to differ — the tests seed such disagreements on purpose.
3. A department with no archived documents returns `0`; the procedure never raises an error.
4. Do the whole pass on the very record instance you were handed — the tests inspect it afterwards, so don't swap the work onto a copy. After the call returns, the instance must rest on the department's last archive entry (the highest `"Entry No."` inside the department).
5. **The statement budget:** one call over a department of 35–45 documents, roughly a third of them legacy, must execute **at most 25 SQL statements**. Grading measures `SessionInformation.SqlStatementsExecuted` around a single call — an implementation that goes back to the database for every document's payload spends one statement per document and fails.
6. **The row budget:** the same call must read **at most 120 rows**, measured with `SessionInformation.SqlRowsRead`, while the archive table holds about 600 documents — most of them belonging to other departments. An implementation that scans the whole archive and picks the department in code reads 600+ rows and fails, whatever its total says.

Payload discipline — fetching a payload only for the documents that need measuring, never hauling every payload along with its row — is the point of the exercise, but it is not graded on its own: the grading session can count SQL statements and rows, not the bytes that crossed the wire, so only the two budgets above and the arithmetic judge your choice.

## What the tests check

The tests seed `"Archived Document"` entries with department codes, recorded sizes and payload lengths generated fresh every run, so hardcoded totals fail; recorded sizes are chosen to disagree with the actual stored payloads, so an implementation that measures everything "to be safe" fails on arithmetic, not just on cost. Decoy documents in other departments must stay out of the total. Rule 4 is asserted directly on the record instance after a call: its `"Entry No."` must be the department's last entry. The two budget tests warm the caches with one throwaway call, then invalidate the server's data cache with a decoy write — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle payload traffic past the budget — and snapshot the `SessionInformation` counters around a second call, asserting the total is correct before judging the cost.

## Learn More

- [Blob Data Type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-data-type) — what makes a Blob different from every normal field on the row.
- [Performance Articles for Developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer) — how AL data access translates to SQL cost, and the `SessionInformation` counters the budget tests measure with.
- [Blob.Length Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-length-method) — the byte count of a stored payload.
- [Record.SetAutoCalcFields Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setautocalcfields-method) — the one-statement way to bring every payload along, and therefore the thing to weigh against fetching on demand.
