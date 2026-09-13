# The Ledger That Refuses to Commit

Every posting routine in Business Central shares one guarantee: a general ledger transaction that does not balance never reaches the database. Not because somebody remembered to check at the end of the routine, but because the platform itself refuses to commit it. In this task you build that guarantee into a tiny petty cash ledger — a cash box whose every movement is recorded as legs that must sum to zero.

The starter ships one finished data object. Do not rename it or its fields — the grading tests bind to every name below character for character. Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## The object you get

- Table `"Petty Cash Entry"` — primary key `"Entry No."` (Integer); fields `"Document No."` (Code[20]), `"Account No."` (Code[20]) and `Amount` (Decimal); a secondary key on `"Account No."` with `Amount` as its SumIndexField.

## Requirements

Implement both procedures in the codeunit `"Petty Cash Ledger"`:

```al
procedure PostEntry(DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
procedure PostTransfer(DocumentNo: Code[20]; FromAccount: Code[20]; ToAccount: Code[20]; Amount: Decimal)
```

Rules:

1. Posting a leg — `PostEntry` inserts exactly one `"Petty Cash Entry"` carrying the document no., the account no. and the amount; a positive amount puts money into the account, a negative one takes it out. Assign a unique `"Entry No."` yourself (the usual highest-existing-plus-one is fine; the exact numbers are not graded). An `Amount` of zero fails immediately with an error message that contains `must not be zero`.
2. Posting a transfer — `PostTransfer` moves `Amount` from `FromAccount` to `ToAccount`: exactly two entries under `DocumentNo`, `-Amount` on `FromAccount` and `+Amount` on `ToAccount`. An `Amount` that is zero or negative fails immediately with an error message that contains `must be positive`.
3. The ledger invariant — every committed transaction is balanced: the moment a transaction commits, the sum of `Amount` over every entry in `"Petty Cash Entry"` is zero. Because every transaction that was ever committed was itself balanced, that is the same as saying that the legs posted since the current transaction began sum to zero.
4. Deferred refusal — posting a leg that leaves the ledger unbalanced must not raise an error: the call returns normally and the entry is readable inside the transaction that wrote it. The refusal comes later, when the transaction tries to commit: the commit fails, and nothing posted in that transaction survives — not even a perfectly balanced transfer posted alongside the offending leg. The error is raised by the commit itself, so its text is the platform's, not yours.
5. Balancing later is fine — legs posted through separate calls or under different document numbers balance each other. What must sum to zero is the transaction, not the call and not the document. The tests post every leg of a transaction through one instance of `"Petty Cash Ledger"`.
6. The transaction belongs to the caller — never call `Commit` in your code and raise no dialogs. The tests commit; after a refused commit they expect the ledger to work normally again in the next transaction, so whatever you compute the balance from must not outlive a rolled-back transaction.
7. One variable carries the mark — however you tell the platform that the ledger is unbalanced, set that state and lift it through the same record variable, kept as a global of the codeunit for the whole transaction. The platform binds the state to the record variable that set it: a fresh local variable in every call leaves the first call's mark in force, marking the table consistent through another variable does not lift it, and the commit is refused even though the ledger balances.

## What the tests check

The transfer legs with generated accounts and amounts (hardcoding won't survive); a balanced transfer, two single legs that cancel out, and legs under two document numbers — each followed by a `Commit()` that must go through and leave the legs in the table; a single leg posted outside any error guard, which must be written and readable without raising anything (if your code raises there, that test fails with your own message); a lone leg, and a lone leg next to a balanced transfer (posted before it and after it), each followed by `asserterror Commit()` — the commit must be refused for an inconsistent ledger and afterwards no entry of that transaction may exist; a balanced transfer committed in the transaction right after a refused one; and the immediate guards for a zero leg and for a zero or negative transfer. Where a commit is expected to go through and is refused with the platform's inconsistency error, the usual cause is rule 7: the mark was set through one record variable and lifted through another. Where a commit is expected to be refused and yours goes through, the failure reads the framework's own `An error was expected inside an ASSERTERROR statement`; where the commit is refused for any other reason, the actual error text is shown. Error-text matching is case-insensitive, but the quoted phrases must appear exactly as written.

## Learn More

- [Database.Commit() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method) — how write transactions begin, end and are made permanent.
- [Record Data Type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type) — the full list of instance methods a record variable gives you; the one you need is in there.
- [Record.CalcSums Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcsums-method) — totalling a column without looping over the rows.
- [TransactionModel Attribute](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-transactionmodel-attribute) — why the grading tests run as AutoCommit and call `Commit()` themselves.
