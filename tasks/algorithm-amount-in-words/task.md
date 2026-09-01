# Amount in Words

Your company prints checks, and the bank insists the amount appears in words next to the digits — `1234.56` on the amount line must read `one thousand two hundred thirty-four and 56/100` on the words line. The check report needs a reusable converter, and you are writing it.

## Requirements

Create a **codeunit** named `"Amount In Words"` with one public procedure:

```al
procedure ToWords(Amount: Decimal): Text
```

`Amount` is a check amount: at least `0`, below `1,000,000,000` (one billion), and never carrying more than two decimal places.

The returned text is the whole part spelled out in words, followed by the cents as a fraction:

1. The whole part is written in lowercase English words: `0`–`19` are single words (`zero`, `one`, … `nineteen`), round tens are single words (`twenty`, `thirty`, `forty`, `fifty`, `sixty`, `seventy`, `eighty`, `ninety`), and other two-digit numbers hyphenate the tens word and the units word (`forty-two`).
2. Hundreds read as the digit word plus `hundred`, then the remainder if any: `105` is `one hundred five` — **no** `and` inside the whole part; that word is reserved for the cents separator.
3. Millions and thousands read as their three-digit group (spelled per rules 1–2) followed by `million` or `thousand`. A group whose value is zero is omitted entirely: `1,000,000` is `one million`, `2,000,015` is `two million fifteen`.
4. A whole part of zero is the word `zero`.
5. After the whole part comes a space, the word `and`, a space, and the cents as exactly two digits over 100: `56/100`, `05/100`, `00/100`. The fraction is always present, even for whole amounts.
6. Words are separated by single spaces, with no leading or trailing spaces.
7. An `Amount` below `0` or at/above `1,000,000,000` must raise an error with a message that contains the text `out of range`.

Examples: `ToWords(1234.56)` = `one thousand two hundred thirty-four and 56/100`; `ToWords(0)` = `zero and 00/100`; `ToWords(0.99)` = `zero and 99/100`.

## What the tests check

The grading tests compare the returned text **character for character** against the rules above — spelling (it is `forty`, not `fourty`), hyphens, single spaces, lowercase, the zero-padded two-digit cents, and no `and` anywhere except before the fraction. They cover zero, the teens, round tens, compound tens, hundreds, amounts with skipped groups such as `1,000,000` and `2,000,015`, the largest supported amount `999,999,999.99`, and both out-of-range boundaries via the expected error. Several tests build their expected string from **randomly generated digits**, so hardcoding the example outputs will not pass.

## Learn More

- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)
- [Decimal data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type)
- [System.Round method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method)
- [System.Format method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-integer-method)
- [Dialog.Error method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method)
