# The Accrual That Posts Itself

The rent is the same every month, and the cost belongs to the departments that occupy the building. Typing that journal twelve times a year is how typos become audit findings — so you build the journal once, and let it post itself period after period, splitting the cost on the way.

Your codeunit only *builds* the journal. The grading tests hand you the accounts, the departments and the percentages, then post the batch with the standard `Gen. Jnl.-Post Batch` routine — twice — and read the general ledger. None of your code runs while the batch posts, so everything below has to be carried by the journal setup you left behind.

## What you build

A **codeunit** named `"Recurring Rent Accrual"` with three public procedures:

```al
procedure CreateAccrualBatch(TemplateName: Code[10]; BatchName: Code[10])
procedure AddAccrualLine(TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date; AccrualAccountNo: Code[20]; LineAmount: Decimal; Method: Enum "Gen. Journal Recurring Method"; Frequency: DateFormula; ExpirationDate: Date): Integer
procedure AddDepartmentShare(TemplateName: Code[10]; BatchName: Code[10]; AccrualLineNo: Integer; ExpenseAccountNo: Code[20]; DepartmentCode: Code[20]; SharePct: Decimal)
```

- `CreateAccrualBatch` creates the journal the accrual lives in: a general journal template named `TemplateName`, holding a batch named `BatchName`. The names handed to you are always free — no template of that name exists yet.
- `AddAccrualLine` adds one line to that batch and returns its `"Line No."`. The line posts `LineAmount` to G/L account `AccrualAccountNo` under document number `DocumentNo`, is first due on `PostingDate`, comes back every `Frequency`, is treated according to `Method`, and stops after `ExpirationDate` (`0D` = never). `LineAmount` is signed the way it must reach the ledger: the rent accrual is a credit, so the tests pass a negative amount.
- `AddDepartmentShare` gives `SharePct` percent of the line identified by `AccrualLineNo` to G/L account `ExpenseAccountNo`, tagged with `DepartmentCode` — a value of global dimension 1. A line can be given any number of shares, and they always add up to 100 percent.

Pick object IDs in the range 50100–50199, and refer to every other object by name, never by ID.

## What has to happen when the batch is posted

1. **One run, one document.** Posting the batch writes one G/L entry for the accrual line — `LineAmount` on `AccrualAccountNo` — plus one entry per department share. Every entry of the run carries the line's posting date and its document number.
2. **The shares are the balancing entries.** A share posts its percentage of the line amount to `ExpenseAccountNo` with the opposite sign, and its `DepartmentCode` reaches the posted entry as its Global Dimension 1 Code. Together the shares cover the line exactly: their amounts sum to precisely minus the line amount, even when the percentages don't divide evenly (33.33 / 33.33 / 33.34 of 100.01 must still add up to 100.01, to the cent).
3. **A run leaves the journal ready for the next one.** The line and its shares stay in the journal, and the line's posting date has moved on by `Frequency`. Posting the batch again — with nobody editing anything in between — posts the whole accrual again, one frequency later.
4. **`Method` decides what happens to the amount.** With `"F  Fixed"` the line keeps its amount for the next run. With `"V  Variable"` the amount is cleared to 0 after posting, and the line waits in the journal for the next period's figure.
5. **`"RF Reversing Fixed"` reverses itself.** Everything the run posted is posted again mirrored — accrual line and department shares alike — dated the day after the posting date.
6. **`ExpirationDate` is the last date the line may post.** Once the line's posting date is later than its expiration date, the line posts nothing and does not move on either; other lines in the same batch post as usual.

## What the tests check

Ten tests build a journal through your three procedures, post it, and read what reached the general ledger: a random rent amount split over two departments by a random percentage (hardcoding the example figures won't survive), the accrual entry itself with an exact entry count and document number for a single run, a second run that must repeat the whole accrual one frequency later on its own, the line's posting date after a run, `"F  Fixed"` keeping the amount versus `"V  Variable"` clearing it, the mirrored entries of a `"RF Reversing Fixed"` line on the following day, a batch holding one live and one expired line, a line whose posting date falls exactly on its expiration date and must still post, and the 100.01 split three ways that must not lose a cent. Amounts are matched exactly, and department amounts are read from the Global Dimension 1 Code on the posted entries.

## Learn More

- [DateFormula data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dateformula/dateformula-data-type) — what a `Frequency` like `<1M>` is made of, and why it has to be evaluated rather than assigned.
- [System.CalcDate(DateFormula [, Date]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-dateformula-date-method) — how a date formula turns a due date into the next one.
- [Field calculation methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcfields-calcsums-fielderror-fieldname-init-testfield-and-validate-methods) — assigning a field skips the logic behind it; `Validate` is what fills in everything that hangs off a field.
- [Work with dimensions](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-dimensions) — global dimensions, shortcut dimension codes, and how a department code travels to a ledger entry.
