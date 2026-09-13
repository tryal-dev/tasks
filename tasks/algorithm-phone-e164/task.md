# One Phone Format for the SMS Gateway

The SMS gateway your company just signed up with accepts one number format only: E.164 — a `+`, the country calling code, then the subscriber number, digits only and at most 15 of them. The contact records hold whatever people typed over the years: `(0)151 234-5678`, `+49 (151) 2345678`, `0049151…`, sometimes with an extension tacked on the end. Every message to a badly formatted number bounces, and the gateway bills the bounce. You are writing the normalizer that runs before every send.

## Requirements

Create a **codeunit** named `"Phone E164 Formatter"` with one public procedure:

```al
procedure ToE164(Raw: Text; DefaultCountryPrefix: Text): Text
```

`Raw` is the number as typed. `DefaultCountryPrefix` is the country calling code to assume for numbers entered in national format, always given with its leading `+` — for example `+49` or `+1`. Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

Apply the rules in this order:

1. **Trim, then cut the extension.** Leading and trailing whitespace is ignored. If the remaining text contains the letter `x` (either case), it introduces an extension: the `x` and everything after it are discarded, so `0151 234 5678 x123` is the number `0151 234 5678`.
2. **A `+` belongs only at the start.** After step 1, a `+` may appear only as the very first character. A `+` anywhere else — including a second one — makes the number invalid: raise the error `Phone number %1 has a + that is not at the start.`, where `%1` is `Raw` exactly as it was passed in.
3. **No letters.** If any letter `a`–`z` / `A`–`Z` remains after step 1, raise `Phone number %1 contains letters.`
4. **Keep the digits and decide the shape.** Every character that is not a digit `0`–`9` — spaces, parentheses, dashes, dots, slashes, the `+` itself — is dropped; what remains is the digit string. Then:
   - If the text from step 1 starts with `+`, the number is already international: the result is `+` followed by the digit string.
   - Otherwise, if the digit string starts with `00`, that is the international dialling prefix: the result is `+` followed by the digit string without its first two zeros.
   - Otherwise the number is national: drop one leading `0` from the digit string if there is one (the national trunk prefix) and put `DefaultCountryPrefix` in front.
5. **Length.** Count the digits of the result — the country code counts, the dropped trunk `0` does not. If fewer than 8 or more than 15 remain, raise `Phone number %1 has %2 digits, but an E.164 number has 8 to 15.`, where `%2` is that count. Exactly 8 and exactly 15 digits are valid.

The result is always a `+` followed by digits and nothing else, so a number that is already in that form comes back unchanged.

Examples with `DefaultCountryPrefix` = `+49`:

- `(0)151 234-5678` → `+491512345678`
- `030/123.456-78` → `+493012345678`
- `+49 (151) 2345678` → `+491512345678`
- `0049 151 2345678` → `+491512345678`
- `0151 234 5678 x123` → `+491512345678`
- `+491512345678` → `+491512345678`
- `49+151 2345678` → error: the `+` is not at the start
- `0151 234 ABCD` → error: letters
- `01234` → error: after dropping the `0` and adding `+49`, only 6 digits remain

## What the tests check

The grading tests call `ToE164` with each input shape above and compare the result **character for character**: the national number with the trunk zero in parentheses and a dash, a national number written with a slash, a dot and a dash (`030/123.456-78`), the `+` form with parentheses and spaces, the `00` form, an extension after a lowercase and after an uppercase `x`, an input padded with spaces, a national number without a trunk zero (`212 555 0123` with `+1`), and an already canonical number that must come back unchanged. The `+` and `00` inputs are passed with a **different** `DefaultCountryPrefix` than the number carries, so a solution that always prepends the default prefix fails; the national shape is also driven with a randomly generated prefix and subscriber number, so hardcoding `+49` fails too. The error tests use a `+` in the middle, a doubled `+`, uppercase letters, lowercase letters, the empty input, and results of 6, 7 and 16 digits — they assert that an error is raised and that its text contains the message given above, spelled exactly, with `Raw` substituted for `%1` and the count for `%2`. `Raw` is the input as typed: the 7-digit case is `+49 12345 x7` with `+49`, so its message must quote the extension too, and the `7` must not count the extension's digit; the 6-digit case is `01234` with `+49`, where the count must include the country code and exclude the dropped trunk zero. Exactly 8 and exactly 15 digits must be accepted.

## Learn More

- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type) — the full toolbox for taking a string apart: `StrPos`, `CopyStr`, `UpperCase` and the rest.
- [Text.DelChr(Text [, Text] [, Text]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-delchr-method) — removes a set of characters from a string; read the remarks on the `Where` and `Which` parameters twice.
- [Text.Trim() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-trim-method) — strips the whitespace at both ends in one call.
- [Dialog.Error(Text [, Any,...]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method) — raising an error whose placeholders are filled from a label.
