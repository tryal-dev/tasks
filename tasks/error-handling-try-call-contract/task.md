# When Your Try Isn't a Try

The pack station scans package codes into a batch, and before the shipment can be released the validator has to answer one question: which codes are good, and what is wrong with the rest. Two things must never happen. A single mistyped code must not abort the whole batch — catching scan errors is the entire reason the validator exists. And a broken configuration must not be filed away as if it were just one more bad code: when the setup the validator reads is unusable, nothing about the batch can be judged, and whoever started the run has to hear about it.

The starter already sketches the loop. It does not behave: the first bad code takes the run down with it, and the fix has a second trap waiting behind it.

## What you get

The starter ships a setup table named `"Package Scan Setup"` with the fields `"Primary Key"` (`Code[10]`, the primary key) and `"Code Length"` (`Integer`). It is a singleton — the one record that counts has a **blank** `"Primary Key"`. Keep the table unchanged and include it in your submission: the grading tests write it directly by these names.

It also ships the **codeunit** named `"Package Scan Validator"`, with the three public procedures below and a batch loop that you have to make work.

## Requirements

```al
procedure ResolveCodeLength(): Integer
procedure CheckScan(ScannedCode: Text; CodeLength: Integer)
procedure ValidateBatch(ScannedCodes: List of [Text]; var Failures: List of [Text]): Integer
```

### `ResolveCodeLength`

Reads the configuration and returns the required code length:

1. No `"Package Scan Setup"` record with a blank `"Primary Key"` — raise `Package Scan Setup is missing.`
2. `"Code Length"` zero or negative — raise `Code Length must be greater than zero in Package Scan Setup.`
3. Otherwise return `"Code Length"`.

### `CheckScan`

Checks one scanned code against a required length. It raises the exact message of the **first** broken rule below; a good code returns silently.

1. `'%1' must be exactly %2 characters long.` — when the code's length is not `CodeLength`. `%1` is the scanned code, `%2` is `CodeLength`. Note the single quotes around the code and the full stop.
2. `'%1' must contain digits only.` — when any character of the code is anything other than `0`–`9`. `%1` is the scanned code.

`ScannedCode` is whatever the scanner produced: it may be empty, too long, or full of letters.

### `ValidateBatch`

Returns how many codes passed, and reports the rest:

- Clear whatever `Failures` already holds before anything else — a second run must not inherit the first run's findings.
- A **scan** problem never reaches the caller. Each failing code adds exactly one entry to `Failures` — the exact message `CheckScan` raises for that code — and the codes after it are still checked. `Failures` follows the order of `ScannedCodes`. A batch in which every single code is broken still returns normally.
- A **configuration** problem is the exact opposite. The error `ResolveCodeLength` raises travels out of `ValidateBatch` to the caller with its message intact, and never lands in `Failures`. That holds whatever the batch looks like: a batch of perfectly good codes, a batch of broken ones, and an empty batch alike.
- With a usable configuration, an empty batch returns 0 and leaves `Failures` empty.

Pick object IDs in the range 50100–50199, and reference every object by name, never by ID. Captions and tooltips are good practice here but are not graded.

## What the tests check

`CheckScan` is called directly with a generated code of the required length (it must return silently), with a code one character too short and one too long, with a code of the right length carrying a letter, with one carrying a non-digit symbol, and with a code that breaks both rules at once — the raised messages are compared character for character, quotes and full stop included. `ResolveCodeLength` is checked against a configured length, against an empty setup table, and against a `"Code Length"` of exactly 0 and a negative one. `ValidateBatch` then runs on a usable setup: one broken code must come back as a single `Failures` entry and a return value of 0 — the call is made directly, so an error raised there fails the test; a broken-good-broken-good batch must return 2 with both messages in scan order; an all-good batch of three returns 3 with an empty `Failures`; an empty batch returns 0; and a `Failures` list pre-filled with leftovers comes back empty. Finally, the setup is broken — the record deleted, or its `"Code Length"` set to 0 — and `ValidateBatch` is expected to fail: the tests catch the error themselves and compare it with the exact message `ResolveCodeLength` raises, including for a batch whose codes are all fine and for an empty batch, and `Failures` must come back empty in each of those runs — a configuration error is never filed as a per-code failure.

## Learn More

- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling) — the map of AL's error-handling features and when each one fits.
- [Failure modeling and robust coding practices](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-robust-coding-practices) — why some failures should be absorbed and others must reach the caller.
- [System.GetLastErrorText() Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext--method) — reading the message of an error that was caught instead of shown.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the `Add`/`Count`/`Get` surface the batch result is built with.
