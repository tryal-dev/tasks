# IBAN Verifier

Vendors paste their bank account numbers into Business Central in every imaginable shape — lowercase, grouped with spaces, sometimes with a typo that would send a payment to nowhere. Before a payment file leaves the company, every IBAN must pass the ISO 13616 check, and you are writing the verifier.

## Requirements

Create a **codeunit** named `"IBAN Verifier"` with one public procedure:

```al
procedure IsValid(IBAN: Text): Boolean
```

The procedure returns `true` when the input is a well-formed IBAN with correct check digits, and `false` otherwise — it must never raise an error, no matter how mangled the input is.

Rules, in order:

1. **Normalize** the input first: remove all spaces (wherever they appear) and convert to uppercase. Users type `de89 3704 0044 0532 0130 00` and mean `DE89370400440532013000`.
2. **Structure gate.** After normalization the candidate must be 15 to 34 characters long; characters 1–2 must be letters `A`–`Z` (the country code), characters 3–4 must be digits `0`–`9` (the check digits), and every remaining character must be a letter or a digit. Anything else — a hyphen, an empty string, a digit in the country code, a letter in the check-digit positions — returns `false`.
3. **Mod-97 check.** Move the first four characters to the end of the string, then replace every letter with its two-digit number: `A`=10, `B`=11, … `Z`=35. Read the result as one decimal integer; the IBAN is valid exactly when that integer mod 97 equals 1.
4. Country-specific rules — per-country lengths and BBAN formats from the IBAN registry — are **out of scope**: any country code made of two letters is acceptable as long as rules 2 and 3 hold.

Example: `GB82 WEST 1234 5698 7654 32` normalizes to `GB82WEST12345698765432`, rearranges to `WEST12345698765432GB82`, expands to `3214282912345698765432161182` — and that number mod 97 is 1, so the IBAN is valid. Flip a single character anywhere and the remainder changes, which is the whole point of the scheme.

## What the tests check

The grading tests call `IsValid` with real-world IBANs (spaced, lowercase, the 15-character Norwegian minimum, a synthetic IBAN exactly at the 34-character maximum, a 31-character Maltese IBAN with letters inside the account part), with corrupted variants (wrong check digits, a single-digit typo), and with structurally broken inputs — too short, longer than 34 characters, digits in the country code, letters in the check-digit slots, hyphens as separators, and the empty string. Several structurally broken inputs are crafted so their mod-97 remainder is 1 anyway: skipping the structure gate will not pass. One test generates a random IBAN and another corrupts its check digits, so hardcoding the examples fails. Fair warning: the expanded number of a long IBAN has over 60 digits, far beyond any AL integer type — `Evaluate` into a `BigInteger` will overflow.

## Learn More

- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)
- [Text.UpperCase(Text) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-uppercase-method)
- [Text.DelChr(Text [, Text] [, Text]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-delchr-method)
- [Text.CopyStr(Text, Integer [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method)
- [System.Evaluate(var Any, Text [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method)
