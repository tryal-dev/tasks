# Validate with Luhn

A customer types a credit card number into your payment page, a colleague pastes a registration number into a vendor card — and one mistyped digit later, the payment provider rejects the whole batch at eleven at night. The Luhn checksum exists to catch exactly these slips at the keyboard, before anything is sent anywhere: card numbers, IMEIs, and many national registration numbers all carry a check digit chosen so the full number passes it.

Your job is the validator itself.

## Requirements

Create a **codeunit** named `"Luhn Validator"` with one public procedure:

```al
procedure IsValid(Input: Text): Boolean
```

`IsValid` returns whether `Input` passes the Luhn check. It never raises an error — malformed input simply returns `false`.

The rules:

1. Spaces are allowed anywhere in the input and are ignored; every other non-digit character (letters, dashes, punctuation) makes the input invalid.
2. After ignoring spaces, the input must be at least two characters long — the empty string and a single digit are invalid.
3. The checksum: starting from the **rightmost** digit, double every second digit (the 2nd, 4th, 6th, … counted from the right). If doubling a digit produces a value greater than 9, subtract 9 from it. Sum the resulting digits together with the untouched ones.
4. The input is valid exactly when that sum is divisible by 10.

Worked example — `"059"`: the 9 stays 9, the 5 doubles to 10, which becomes 1, the 0 stays 0. The sum is 9 + 1 + 0 = 10, divisible by 10 — valid. `"159"` by the same walk sums to 11 — invalid.

## What the tests check

The tests call `IsValid` on fixed cases — a valid and an invalid 16-digit card number, `"0"` and `" 0"` and the empty string (all invalid by rule 2), a valid number with spaces scattered through it, a valid number re-spelled with dashes and with a letter (both invalid by rule 1), a number whose validity hinges on the subtract-9 step, an even-length number whose validity hinges on counting positions from the right, and an all-zero number (valid — the sum 0 is divisible by 10). Two more tests generate a random number, append the check digit the tests compute independently, and expect `true` — then corrupt that digit and expect `false`, so hardcoding the examples cannot pass.

## Learn More

- [Text.StrCheckSum(Text [, Text] [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strchecksum-method)
- [Text.StrLen(Text) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strlen-method)
- [Text.CopyStr(Text, Integer [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method)
- [System.Evaluate(var Any, Text [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method)
- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)
