# Reverse It, Once

An entry was posted with the wrong sign, and the accountant wants it gone. Business Central does not delete posted entries — it reverses them: an offsetting entry with the same document number and posting date, the amount and quantity negated, and both sides flagged and cross-referenced so the audit trail shows what undid what. The hard part is not the arithmetic. It is refusing to reverse anything that must not be reversed, and making sure a refusal in the middle of a document leaves the ledger exactly as it was.

The starter ships the table finished. Do not rename it or its fields — the grading tests bind to every name below character for character.

## The table you get

Table `"Reversible Ledger Entry"` — primary key `"Entry No."` (Integer), plus a secondary key on `"Document No."`, `"Reversed Entry No."`; fields `"Document No."` (Code[20]), `"Posting Date"` (Date), `"Account No."` (Code[20]), `Description` (Text[50]), `Amount` (Decimal), `Quantity` (Decimal), `"Applied Amount"` (Decimal), `Reversed` (Boolean), `"Reversed by Entry No."` (Integer), `"Reversed Entry No."` (Integer).

The three bookkeeping fields have the same meaning as in the real G/L Entry table: an entry that has been reversed carries `Reversed` = true and the number of the entry that reversed it in `"Reversed by Entry No."`; a reversal entry carries `Reversed` = true and the number of the entry it reversed in `"Reversed Entry No."`. So `"Reversed Entry No." <> 0` is what makes an entry a reversal, and only a reversal has it set.

## Requirements

Implement both procedures in the codeunit `"Ledger Entry Reversal"`:

```al
procedure ReverseEntry(EntryNo: Integer): Integer
procedure ReverseDocument(DocumentNo: Code[20]): Integer
```

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID. Captions are good practice but not graded.

### `ReverseEntry`

1. The entry must exist. If there is no `"Reversible Ledger Entry"` with that `"Entry No."`, fail with an error message that contains `does not exist`.
2. Refuse, in exactly this order, so an entry that trips more than one rule always reports the first of them:
   1. the entry is itself a reversal (`"Reversed Entry No." <> 0`) — error text contains `is a reversal`;
   2. the entry has already been reversed (`Reversed` is true) — error text contains `already reversed`;
   3. the entry is partly applied (`"Applied Amount" <> 0`) — error text contains `partly applied`.
3. Otherwise write one new `"Reversible Ledger Entry"`, the reversal: `"Entry No."` is the highest entry number currently in the table plus 1 (the table already holds entries — never assume you start at 1); `"Document No."`, `"Posting Date"`, `"Account No."` and `Description` are copies of the original's; `Amount` and `Quantity` are the original's negated; `"Applied Amount"` stays 0.
4. Flag both sides. On the reversal: `Reversed` = true and `"Reversed Entry No."` = the original's `"Entry No."`, with `"Reversed by Entry No."` left at 0. On the original: `Reversed` = true and `"Reversed by Entry No."` = the new entry's number, with `"Reversed Entry No."` left at 0.
5. Return the new reversal entry's `"Entry No."`.

### `ReverseDocument`

6. Its scope is every entry carrying `DocumentNo` that is not itself a reversal — that is, `"Reversed Entry No." = 0`. Entries of other documents, and the reversal entries already sitting in this document, are invisible to it. Note that the reversals you write carry the document number too, so they land inside the document while you are working on it.
7. If the document has no entry in scope, fail with an error message that contains `nothing to reverse`.
8. Every entry in scope must pass the same refusals as `ReverseEntry`, rules 2.2 and 2.3, and is reversed by the same rules 3 and 4 — in ascending `"Entry No."` order, so the lowest new entry number belongs to the lowest original entry number.
9. All or nothing. If any entry in scope is refused, the whole call fails and the ledger is left exactly as it was: no reversal entry survives, and no entry has been flagged. Reversing half a document and reporting an error is the one outcome that must never happen.
10. Return the number of entries reversed.

## What the tests check

The tests reverse a clean entry and assert the negated `Amount` and `Quantity`, the copied document number, posting date, account and description, the returned entry number continuing the ledger, both `Reversed` flags with their two cross-references, and that the entry plus its reversal net to zero on both `Amount` and `Quantity`. Each refusal is checked with its error text (matching is case-insensitive, but the quoted phrases must appear exactly as written), including a second attempt on an already reversed entry, which must leave the ledger byte-identical, an attempt on the reversal entry itself, and an entry tripping two refusals at once, which must report the earlier of them. For `ReverseDocument`: a clean three-entry document (the returned count, one reversal per entry, both totals netting to zero), the reversal order, the two `Reversed` flags and both cross-references on every entry of the document and on the reversal written for it, the empty document, a neighbouring document that must stay untouched, a second run on an already reversed document, a document holding a partly applied entry — and a five-entry document whose third entry was already reversed, where the call must fail with `already reversed` and the ledger must afterwards hold exactly the entries it held before, with the other four entries still unflagged. Amounts, quantities, dates and descriptions are generated, so hardcoding the examples will not survive.

## Learn More

- [Reverse journal postings and undo receipts/shipments](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-how-reverse-journal-posting) — what a reversal means in Business Central, and why an entry may only be reversed once.
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods) — reading one entry by key and walking a filtered set.
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling) — raising the refusals, and what an error does to the work already done.
- [Database.Commit() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method) — where one write transaction ends and the next begins.
