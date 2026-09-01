# The Comma That Broke the Import

Monday's customer import from the webshop died on line 4,217: the buyer `"Davis, Sam"` turned into two columns, shifting every field after the name one position to the right — the city landed in the phone number. The export is perfectly valid CSV: fields containing commas are wrapped in double quotes, and a literal quote inside such a field is written as two quotes. The import code just splits on commas. Business Central integrations meet this format constantly — you are building the line parser that gets it right.

## Requirements

Create a **codeunit** named `"CSV Line Parser"` with one public procedure:

```al
procedure ParseLine(Line: Text): List of [Text]
```

Parsing rules — all seven are graded:

1. Fields are separated by commas; the returned list contains the field values in their original order.
2. A field may be enclosed in double quotes; the enclosing quotes are not part of the value.
3. Inside a quoted field, a comma is ordinary data, not a separator.
4. Inside a quoted field, a doubled quote `""` stands for one literal `"` in the value.
5. Everything else comes back exactly as written — spaces are never trimmed.
6. Empty fields are real fields: `first,,last` has three fields, `,mid,` has three fields, `""` is an empty field, and the empty line parses to exactly one field — the empty text.
7. A line whose quoted field is still open when the line ends is malformed: raise an error with a message that contains the text `unterminated quoted field` — this exact fragment; note the casing.

What you may rely on — the tests never violate this: apart from the malformed case in rule 7, every quote character in a test line either opens a field (at the start of the line or right after a separator comma), closes a quoted field, or is part of a doubled pair inside a quoted field. You will never see a quote in the middle of an unquoted field, or data between a closing quote and the next comma.

## What the tests check

Fixed cases for every rule above — plain splits, kept empty fields, preserved spaces, commas inside quotes, doubled quotes (including a field whose entire value is one `"` character), adjacent quoted fields, the empty line, and the unterminated-quote error — plus one line assembled from randomized field values containing commas and quotes, so hardcoding the examples fails. All comparisons are exact, character for character.

## Learn More

- [TextBuilder data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type)
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)
- [Text.CopyStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method)
- [Text.StrLen method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strlen-method)
- [Dialog.Error method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method)
