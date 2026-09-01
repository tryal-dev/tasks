# Print the Eight-Line Address Block

Your team is building a custom shipping document, and its layout reserves eight lines for the recipient's address.

The printed address has to look exactly like the one on every other Business Central document: the line order each country expects, the post code, city and county combined the way that country combines them, the country name in the recipient's language — and no blank line in the middle just because somebody left `Name 2` empty.

## Requirements

Create a **codeunit** named `"Document Address Block"` with a public procedure:

```al
procedure BuildAddressBlock(var AddressBlock: array[8] of Text[100]; Name: Text[100]; Name2: Text[100]; ContactName: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; CountryCode: Code[10]; LanguageCode: Code[10])
```

Rules:

1. Fill `AddressBlock[1]` through `AddressBlock[8]` with the printed address block for `CountryCode`. Lines the country's layout does not use must come back empty.
2. The layout is the country's own setup, not yours: the `"Address Format"` field on the Country/Region decides how post code, city and county combine and where the country name goes, and `"Contact Address Format"` decides whether the contact line comes first, right after the company name, or last.
3. When the country's `"Address Format"` is `Custom`, the block follows that country's Custom Address Format lines: only the fields listed there are printed, in the order the layout gives them. A layout position that names no field leaves no hole either — the lines below it move up, so a layout that uses positions 1-4 and 6 prints on lines 1 to 5.
4. The country name is printed through the Country/Region Translation for `LanguageCode` when one exists for that country and language, and as the country's own `Name` otherwise — including when `LanguageCode` is empty.
5. Empty input leaves no hole: an empty `Name2`, `Address2` or `County` must not print as a blank line — the lines below it move up. The one exception is the blank line that the `Blank Line+Post Code+City` format asks for; that one belongs to the layout and stays.
6. `CountryCode` always names a Country/Region that exists, and every other argument may be empty.

Do not hand-roll the concatenation — you will get one format right and the other four wrong.

Codeunit 365 `"Format Address"` is the base-application codeunit every standard document uses for this, and you call it from your codeunit like any other codeunit. It has a procedure that fills exactly this kind of `array[8] of Text[100]` from exactly these address parts (note its parameter order — the contact comes third, right after the two name lines), and a separate procedure that sets the language code used for the country name.

Watch out for one trap: that codeunit is `SingleInstance`, so the language code you give it stays set for the rest of the session. Set the language on every build — including when the caller passes an empty language code — or the previous document's language leaks into the next one.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

A country named `Trailside Republic`, set up with `"Address Format" = Post Code+City` and `"Contact Address Format" = After Company Name`, printing a fully filled address:

```text
1  Northwind Traders
2  Regional Office
3  Alicia Vega
4  12 Harbour Road
5  Building C
6  12345 Springfield
7  Blue County
8  Trailside Republic
```

A country named `Dala Kingdom`, set up with `"Address Format" = Blank Line+Post Code+City`, printing an address that carries only a name, a street, a city and a post code:

```text
1  Northwind Traders
2  12 Harbour Road
3  (empty)
4  75310 Uppsala
5  Dala Kingdom
6  (empty)
7  (empty)
8  (empty)
```

## What the tests check

The grading tests seed their own countries — one for each of the five address formats, one of them with a custom layout of its own and one with a country-name translation — and call `BuildAddressBlock` once per country.

Every test compares **all eight entries** of your array against the expected block, character for character, empty trailing lines included: a block that is one separator or one blank line off fails that test. One test builds its address from generated names, so returning fixed strings passes nothing.

One test calls you with an empty `LanguageCode` after the session language was left pointing at a country translation — the untranslated country name still has to come out.

Captions and tooltips are not graded here.

## Learn More

- [Codeunit object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object) — declaring a codeunit variable and calling another codeunit's procedures.
- [Array methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-array-methods) — declaring and passing an `array[8] of Text[100]`.
- [System.CompressArray method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-compressarray-method) — the platform method behind "print an address without blank lines".
- [Changing your language and region settings](https://learn.microsoft.com/en-us/dynamics365/business-central/about-locale-language) — what a custom address format for a country/region is, and how users set one up.
