# Wrap It in a TryFunction

Every night a job imports amount lines from a legacy system, and every night one malformed line kills the entire run with a raw runtime error. The fix is not to make the conversion infallible — it's to catch its failure, report why it failed, and make sure a failed line never leaves half-written data behind.

## Requirements

The starter ships a table `"Legacy Amount Entry"` (primary key `"Entry Code"` of type `Code[20]`, plus `Amount` of type `Decimal`). Keep it exactly as given — the tests read it by name.

Implement the **codeunit** named `"Legacy Amount Import"` with three public procedures:

```al
procedure ParseAmount(AmountText: Text): Decimal
procedure TryParseAmount(AmountText: Text; var Amount: Decimal; var FailureReason: Text): Boolean
procedure ImportLine(EntryCode: Code[20]; AmountText: Text): Boolean
```

Rules:

1. An amount text is **valid** when `Evaluate` accepts it as a `Decimal` and the value is not negative. Zero is valid.
2. `ParseAmount` returns the decimal value of a valid amount text. For an invalid one — garbage text or a negative number — it raises an error with a message that contains the offending text wrapped in single quotes, followed by ` is not a valid amount` (so for input `abc` the message contains `'abc' is not a valid amount` — note the quotes and the exact phrase).
3. `TryParseAmount` must **never raise an error**, whatever `AmountText` contains. On success it returns `true`, puts the value into `Amount`, and leaves `FailureReason` empty. On failure it returns `false` and puts the message of the error that `ParseAmount` would raise into `FailureReason`.
4. `FailureReason` always describes the **latest** attempt: after two failed calls it names the second input, and after a failure followed by a success it is empty again — no stale error text may leak through.
5. `ImportLine` converts `AmountText` and, if it is valid, inserts one `"Legacy Amount Entry"` with that code and the parsed amount, returning `true`. If it is invalid, it returns `false`, raises no error, and inserts **nothing** — the table must hold no row for that entry code, not even a partially filled one.

## What the tests check

The tests call `ParseAmount` with generated valid amounts, zero, garbage and negatives, asserting the returned value or (via a caught error) the exact message phrase from rule 2. `TryParseAmount` is called directly — if it raises, the test fails — and its return value, `Amount` and `FailureReason` are checked for success, failure, failure-after-failure and success-after-failure. `ImportLine` is checked both ways: a valid line must land in `"Legacy Amount Entry"` with the right amount, and an invalid line must return `false` and leave the table without any row for that code.

## Learn More

- [Handling errors using try methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods)
- [TryFunction attribute](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-tryfunction-attribute)
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling)
- [Handle errors by using application language in Dynamics 365 Business Central](https://learn.microsoft.com/en-us/training/modules/handle-errors/)
