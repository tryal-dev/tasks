# Initials Make the Vendor Code

Your purchasing team is tired of inventing vendor numbers by hand. The new rule is simple: a vendor's number is the initials of its company name — `Portable Network Graphics` becomes `PNG` — and when that number is already taken, a counter is appended. Company names being what they are (`O'Brien & Sons`, `Liquid-crystal display`, `7-Eleven Stores`), the simple rule needs precise edges.

## Requirements

Create a **codeunit** named `"Vendor Code Suggestion"` with two public procedures:

```al
procedure SuggestVendorNo(Name: Text): Code[20]
procedure UniqueVendorNo(Name: Text): Code[20]
```

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

### `SuggestVendorNo`

Builds the code from the initials of `Name`:

1. Spaces and hyphens (`-`) separate words. Several separators in a row, or separators at the start or end of the name, only separate — they never produce an initial of their own.
2. Inside a word, only letters `A`–`Z` / `a`–`z` and digits `0`–`9` count. Every other character — apostrophes, `&`, `.`, `,`, `!`, quotes, parentheses, `/` and the rest — is dropped, and dropping it does **not** split the word: `O'Brien` is one word, `It's` is one word.
3. A word's initial is its first letter or digit after the dropping, converted to uppercase. A word left with nothing (`&` on its own, `...`) contributes no initial.
4. The code is the initials in order, cut to the first 20 — a longer name never raises an error.
5. An empty name, or one without any letter or digit, yields the empty code.

The tests use names made of these letters, digits, spaces, hyphens and the other printable ASCII characters (`` !"#$%&'()*+,./:;<=>?@[\]^_`{|}~ ``) only — no accented or non-Latin characters.

Examples: `Portable Network Graphics` → `PNG`; `Liquid-crystal display` → `LCD`; `Thank George It's Friday!` → `TGIF`; `O'Brien & Sons` → `OS`; `7-Eleven Stores` → `7ES`; `Smith (Holdings) Ltd.` → `SHL`.

### `UniqueVendorNo`

Returns a number for `Name` that no `Vendor` record has yet:

1. Let the *base* be `SuggestVendorNo(Name)`. If no vendor has `"No."` equal to the base, return the base.
2. Otherwise try `<base>-2`, then `<base>-3`, `<base>-4`, … in that order and return the first candidate no vendor has. The first free candidate wins: while `-2` is free, a taken `-3` changes nothing.
3. Only an exact `"No."` match counts as taken — a vendor whose number merely starts with the base (`PNGX`) does not block `PNG`.
4. Every candidate must fit in 20 characters. When the base plus the suffix would be longer, shorten the base from the right by just enough to make room: a taken `ABCDEFGHIJKLMNOPQRST` (20 initials) gives `ABCDEFGHIJKLMNOPQR-2`.
5. The procedure only reads the `Vendor` table — it never inserts, modifies or deletes a vendor.

## What the tests check

The grading tests call `SuggestVendorNo` and compare the returned code **character for character**: the examples above, a lowercase name coming back uppercased, a digits-only name such as `365 24 7` → `327`, doubled separators and a trailing space (`Liquid--crystal  display ` → `LCD`), a name whose punctuation goes beyond the examples (`Johnson; Johnson: #1 Supply_Co, "Inc"/Ltd @Home *Plus+ [Group] $5%` → `JJ1SIHPG5` — none of these characters is an initial and none of them splits a word), the empty name and a punctuation-only name both giving the empty code, and a 25-word name cut to exactly 20 characters without an error. Several tests build their names from **randomly generated words** — lowercase, capitalised and digit-led, joined by a mix of spaces and hyphens that are sometimes doubled or placed at the start or end, with random characters from the punctuation set above before, inside and after words and as words of their own — and expect exactly the chosen words' initials, so hardcoding the examples cannot pass. The `UniqueVendorNo` tests seed vendors directly in the `Vendor` table and assert the exact number returned: the base when it is free; `-2` when the base is taken; `-4` when the base, `-2` and `-3` are all taken; `-2` when only the base and `-3` are taken; the untouched base when only a longer number starting with it exists; the trimmed 18-character base plus `-2` for a taken 20-character base; and that the vendor count is unchanged afterwards. The tests run in a real company where other vendors exist — the seeded numbers are built from random words, so your result must be driven purely by the rules above.

## Learn More

- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type) — the toolbox for taking a name apart, one character or one word at a time.
- [Char data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type) — a single character you can compare against ranges of letters and digits.
- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type) — what a `Code[20]` return value does with a 25-character string.
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods) — checking whether a record with a given primary key exists without raising an error when it does not.
