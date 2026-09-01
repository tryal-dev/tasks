# Statement with Running Balance

Support gets the same call every day: "what happened to my wallet balance?" Your company sells prepaid customer wallets — deposits in, charges out — and support wants what Business Central's own customer statement report shows: the transactions listed newest first, each line carrying the balance the account had right after that transaction. You are building that statement engine in miniature.

## What you are given

The starter contains two finished tables — submit them unchanged alongside your codeunit:

- Table `"Wallet Transaction"` — the ledger: field 1 `"Entry No."` (`Integer`, PK), field 2 `"Account No."` (`Code[20]`), field 3 `"Posting Date"` (`Date`), field 4 `Amount` (`Decimal`), field 5 `Description` (`Text[100]`), plus a secondary key on (`"Account No."`, `"Posting Date"`, `"Entry No."`).
- Table `"Wallet Statement Line"` — the statement buffer: field 1 `"Line No."` (`Integer`, PK), plus `"Entry No."`, `"Posting Date"`, `Amount`, `Description`, and `"Running Balance"`.

## Requirements

Implement a **codeunit** named `"Wallet Statement Builder"` with these two public procedures, exactly as written:

```al
procedure RecordTransaction(AccountNo: Code[20]; PostingDate: Date; Amount: Decimal; Description: Text[100]): Integer
procedure BuildStatement(AccountNo: Code[20]; var WalletStatementLine: Record "Wallet Statement Line" temporary)
```

`RecordTransaction` must:

- insert one `"Wallet Transaction"` carrying exactly the values it was called with, and return the assigned `"Entry No."`;
- assign entry numbers as one ledger-wide sequence shared by all accounts: the new entry number is one greater than the highest `"Entry No."` already in the table, and 1 when the table is empty — not derived from the row count.

`BuildStatement` must fill the caller's buffer with the statement of the given account:

- empty the buffer first — lines from a previous build must not survive;
- include exactly the transactions whose `"Account No."` matches, and nothing else;
- order newest first: `"Posting Date"` descending, and within the same date the higher `"Entry No."` (the later-recorded transaction) on top;
- number the lines `"Line No."` = 1 for the newest transaction, then 2, 3, ... down to the oldest, without gaps;
- copy `"Entry No."`, `"Posting Date"`, `Amount`, and `Description` from each transaction onto its line;
- set `"Running Balance"` to the wallet's balance immediately after that transaction: the line's own amount plus the amounts of every older transaction of the same account (older = earlier posting date, or same date with a lower entry number) — so the bottom line's running balance equals its own amount, and the top line's equals the account's total.

Amounts can be negative (charges), so the running balance may dip below zero partway through a statement.

## What the tests check

The tests exercise both procedures independently: they call `RecordTransaction` and read your `"Wallet Transaction"` table directly (stored fields, the returned entry number, the sequence continuing from a pre-seeded high entry number), and they seed the table directly and call `BuildStatement`, then walk the buffer line by line — newest-first order including the same-day tie, line numbers 1..n, field-by-field copies, exact running balances, account filtering, the buffer emptied on a rebuild, and an empty statement for an account with no transactions. One test generates a random ledger of deposits and charges and verifies every guarantee on it, so hardcoding the examples fails. All decimal comparisons are exact.

## Learn More

- [Temporary tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables)
- [Table keys](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys)
- [Record.SetCurrentKey(Any [, Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method)
- [Record.SetAscending(Any, Boolean) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setascending-method)
- [Record.FindSet([Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method)
