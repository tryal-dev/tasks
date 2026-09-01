# Source Code on Every Entry

The first question an auditor asks about a custom posting routine is *where did this entry come from?* Business Central answers it with audit trail codes: a **Source Code** that says which feature created the entry, and a **Reason Code** that says why. That is why table `"Source Code Setup"` ships with nothing but its primary key — in Microsoft's own words, "each feature that introduces a new transaction source should add a field to set up a default source code". Your warranty-claim feature is exactly such a feature, and today it posts entries no auditor can trace.

Pick object IDs in the range 50100–50199, and reference every other object **by name**, never by ID.

## 1. Extend the setup

Create a **table extension** on the `"Source Code Setup"` table adding two fields:

- `"Warranty Claim Source Code"` — `Code[10]`, related to the `"Source Code"` table.
- `"Warranty Claim Reason Code"` — `Code[10]`, related to the `"Reason Code"` table.

*Related to* is load-bearing: validating either field with a code that does not exist in the related table must fail, with an error message that contains the offending code.

## 2. Initialize it

Create a **codeunit** named `"Warranty Claim Posting"` with two public procedures:

```al
procedure InitAuditCodes()
procedure PostWarrantyClaim(var GenJournalLine: Record "Gen. Journal Line")
```

`InitAuditCodes` makes a company ready to post warranty claims:

1. `"Source Code Setup"` is a singleton — one record, blank primary key. If the company has none, create it.
2. If `"Warranty Claim Source Code"` is blank, make sure a `"Source Code"` record with the code `WARRANTY` exists (create it when it doesn't), and store that code in the field.
3. If `"Warranty Claim Reason Code"` is blank, make sure a `"Reason Code"` record with the code `WARRCLAIM` exists (create it when it doesn't), and store that code in the field.
4. A code that is already filled in is never overwritten. Somebody who repoints the setup at their own codes must still have them after the next call.

The `Description` you give the two seeded records is up to you (not graded).

## 3. Stamp and post

`PostWarrantyClaim` receives one general journal line, already filled in by the caller, and posts it:

1. First make the company ready. A warranty claim posted in a company that has never seen the setup record must still go through, carrying the seeded codes.
2. Stamp the line's `"Source Code"` and `"Reason Code"` with the two setup values — whatever they hold at that moment. The line arrives with a source code of its own; yours replaces it.
3. Post the line, so that **both** `"G/L Entry"` records it produces — the one on `"Account No."` and the one on `"Bal. Account No."` — carry the two codes.
4. Nothing your code calls may `Commit`. Grading runs the whole test inside one transaction that is rolled back afterwards, and a `Commit` under that model raises an error instead of committing.

## What the tests check

The grading tests delete the setup record and check that `InitAuditCodes` recreates it, that it stores `WARRANTY` and `WARRCLAIM` in the two fields, and that those two codes really exist as `"Source Code"` and `"Reason Code"` records afterwards — a setup field pointing at a code nobody created is not enough. Another test repoints the setup at codes of its own and calls `InitAuditCodes` again, expecting both to survive. Seeding is graded on a company that already has the setup record too: one test leaves the singleton in place with both warranty fields blank and expects the two codes seeded there and created as records, and two more fill exactly one of the two fields with a generated code — the filled one has to survive while the blank one beside it is seeded, so a guard that looks at the two fields together fails. The posting tests generate a fresh source code and reason code, put them on the setup, post a line, and read both G/L entries back: stamping the literals `WARRANTY` and `WARRCLAIM` instead of reading the setup fails there, and so does putting the source code where the reason code belongs. One test posts with the setup record deleted and expects the seeded codes on the entry; one checks that the two entries carry the line's amount and its negative, so a routine that stamps but never posts fails. Two tests call `Validate` on each setup field with the code `ZZNOSUCH` and expect an error with a message that contains `ZZNOSUCH`. A final test checks that both fields are declared as `Code` with a length of exactly 10.

## Learn More

- [Setting Up Source Codes and Reason Codes for Audit Trails](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-setup-trail-codes) — what the two codes mean and how standard features use them.
- [Table Extension Object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — adding fields to a table you don't own.
- [TableRelation Property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property) — how a field is tied to the table its values live in.
- [Record.Validate(Any [, Any]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method) — what happens, and in which order, when a field value is validated.
