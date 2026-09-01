# EAN-13 Check Digit

Every item barcode your warehouse scans ends in a check digit — one digit computed from the other twelve, put there to catch typos and misreads before they become wrong stock counts. Business Central keeps these codes in the item's GTIN field, and a scanner integration should refuse any code whose check digit does not add up. You are writing the small codeunit that computes and validates EAN-13 check digits.

## Requirements

Create a **codeunit** named `"EAN Check Digit"` with two public procedures:

```al
procedure CalculateCheckDigit(FirstTwelve: Text): Integer
procedure IsValid(Barcode: Text): Boolean
```

### The EAN-13 rule

An EAN-13 barcode is 13 digits, and the 13th is the check digit, computed from the first twelve:

1. Number the twelve digits 1 to 12 from the left.
2. Digits in odd positions (1st, 3rd, 5th, …) count once; digits in even positions (2nd, 4th, 6th, …) count three times.
3. Add it all up. The check digit is the smallest amount you must add to that weighted sum to reach a multiple of 10 — so it is always a single digit, and it is `0` when the sum already ends in 0.

Worked example for `400638133393`: the odd positions contribute 4+0+3+1+3+9 = 20, the even positions contribute (0+6+8+3+3+3) × 3 = 69, the weighted sum is 89, and 89 needs 1 to reach 90 — the check digit is `1` and the full barcode is `4006381333931`.

### `CalculateCheckDigit`

- `FirstTwelve` must be exactly 12 characters long and consist only of digits `0`–`9`. For any other input — wrong length (including a full 13-digit barcode), letters, spaces, punctuation — raise an error with a message that contains the text `12 digits`.
- For valid input, return the check digit `0`–`9` computed by the rule above.

### `IsValid`

- Returns `true` exactly when `Barcode` is 13 characters long, all of them digits `0`–`9`, and the 13th digit equals the check digit computed from the first twelve.
- For everything else — wrong length, non-digit characters, a wrong check digit — return `false`. `IsValid` never raises an error, no matter the input.

## What the tests check

The tests compute check digits for fixed codes — including one whose weighted sum ends in 0, where the check digit must be `0`, not 10 — and verify that `CalculateCheckDigit` raises the promised error (message checked for `12 digits`) on wrong-length and non-digit input. `IsValid` is tested with a genuine barcode, all nine wrong check digits for it, 12- and 14-character codes, the empty text, and codes with letters in them. Randomly generated barcodes — valid ones and ones with a single corrupted digit — are graded against an independent implementation of the standard, so hardcoding the examples fails.

## Learn More

- [Text.CopyStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method)
- [System.Evaluate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method)
- [Text.StrCheckSum method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strchecksum-method)
- [Char data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type)
- [Dialog.Error method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method)
