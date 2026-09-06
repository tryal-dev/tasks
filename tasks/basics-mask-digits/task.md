# Mask the Card Number

Your extension stores the payment reference an accountant typed on the customer - a card number, sometimes a bank account or the phone number registered with the payment provider. Support staff need to see *which* card is on file without seeing the card: show nothing but the last four digits, and keep the separators so the masked value still reads like the original. The first version blanked everything except the last four *characters*, so a reference with a short final group leaked a digit and a card number with spaces hid one too many. Replace it with two small procedures.

## Requirements

Create a **codeunit** named `"Card Number Mask"` with two public procedures:

```al
procedure MaskDigits(Input: Text): Text
procedure DigitCount(Input: Text): Integer
```

Rules for `MaskDigits`:

1. A digit is one of the ten characters `0` to `9`. Every digit except the last four digits of the input is replaced by one `*`; the last four digits stay as they are.
2. "Last four" counts digits, not characters - the separators between them do not count. In `12-34-567` the digits are `1234567`, the last four are `4567`, so the result is `**-*4-567`.
3. Every character that is not a digit - hyphen, space, plus sign, parentheses, dot, letters - stays exactly where it is, so the result has the same length as the input and lines up with it position by position: `4111-1111-1111-1234` becomes `****-****-****-1234`, `4111 1111 1111 1234` becomes `**** **** **** 1234`, and `GB82 WEST 1234 5698 7654 32` becomes `GB** WEST **** **** **54 32`.
4. An input with four or fewer digits comes back unchanged - all of its digits are among the last four, so nothing is masked. With exactly five digits only the first one is masked: `12345` becomes `*2345`.
5. An empty input returns the empty text, and an input without any digit comes back unchanged. Neither raises an error.

`DigitCount` returns how many characters of `Input` are digits `0` to `9`: 16 for `4111-1111-1111-1234`, 11 for `+1 (555) 010-9999`, 0 for the empty text or for a text without digits. Every other character, whatever it is, is not counted. Whether `MaskDigits` calls `DigitCount` to learn how many digits it has to hide is your call (not graded), but it is the natural design.

Pick object IDs in the house range 50100-50199 and reference other objects by name, never by ID.

## Working with single characters

A `Text` can be indexed like an array, and the index is one-based: reading position `i` gives you a `Char`, and assigning a `Char` to position `i` - a one-character literal such as `'*'` is accepted - overwrites that character in place. That works for positions 1 to `StrLen` of the text. Position `StrLen + 1` is special: assigning to it appends one character, which is how a result can be built sequentially into an initially empty variable. Any position beyond that is a run-time error - the Char data type page's own example is position 5 of a three-character text, one past the position that would have appended. The simplest approach here is to copy the input into the result variable first and overwrite the digits in that copy: the result has the same length as the input, so every position you need already exists. Building the result by appending one character at a time works too.

To test a `Char` for being a digit, the `in` operator compares it against a set of values written in square brackets, and two dots between the first and the last value of a range make the range - the ten digits are the range from `'0'` to `'9'`. Since Business Central 2023 release wave 1, `foreach` walks a `Text` one `Char` at a time, which makes `DigitCount` a loop of three lines.

## Examples

| `Input` | `MaskDigits` | `DigitCount` |
|---|---|---|
| `4111-1111-1111-1234` | `****-****-****-1234` | 16 |
| `12-34-567` | `**-*4-567` | 7 |
| `+1 (555) 010-9999` | `+* (***) ***-9999` | 11 |
| `12-34` | `12-34` | 4 |
| `Ext. 42` | `Ext. 42` | 2 |
| (empty) | (empty) | 0 |

## What the tests check

The grading tests call `MaskDigits` and compare the returned text **character for character**: the hyphen-separated card number above, a space-separated card number built from generated digits (so a hardcoded answer passes nothing), `12-34-567` (the last four digits, not the last four characters), the IBAN-style value with letters, the phone-style value with plus sign, parentheses and hyphen, an input with exactly four digits, one with fewer than four, one with exactly five, the empty text, and a generated text without digits. `DigitCount` is checked on the card number (16), on a phone-style text with punctuation and letters (11), on the empty text and on a generated text without digits (0), and on a generated mix of letters and digit runs whose digit count the test knows. Every comparison is exact, and each failure message shows the expected and the actual value.

## Learn More

- [Char data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type) — reading a character of a text into a `Char`, assigning a one-character literal to one, and the run-time error for a position beyond the null terminator of the text.
- [AL control statements](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements) — `for`, `foreach` (including `foreach` over a `Text`) and `break`.
- [Relational operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-relational-operators) — the `in` operator and the value sets it tests against.
- [Text.StrLen method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strlen-method) — the upper bound of every index loop over a text.
