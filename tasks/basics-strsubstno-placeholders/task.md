# Placeholders, Not Concatenation

The sales team wants two pieces of text out of your extension: the sentence at the top of every order confirmation email, and the column line printed for each item on the warehouse picking slip. The current code glues both together with `+`. The result is exactly the kind of string a translator cannot reorder, a one-line order reads "1 lines", and the picking-slip columns wobble because nobody pads anything.

In AL, text that is shown to people lives in a `Label` variable, with a `Comment` describing each placeholder (CodeCop rule AA0470 flags a label without one), and the values are inserted with `StrSubstNo`. Placeholders come in two families: `%1`, `%2`, `%3` are replaced by the whole value, while a `#`-family placeholder is a fixed-width field — the value is left-aligned inside it, padded with spaces, and replaced by asterisks across the whole field when it does not fit. Your job is to rebuild both texts that way.

## Requirements

Create a **codeunit** named `"Order Text Builder"` with two public procedures:

```al
procedure ConfirmationText(OrderNo: Code[20]; CustomerName: Text; LineCount: Integer): Text
procedure SlipColumn(ItemNo: Code[20]; Description: Text): Text
```

Rules for `ConfirmationText`:

1. The result is exactly this sentence pair, with the three values dropped into the marked slots: `Dear <customer name>, your order <order number> with <count> lines is confirmed. Please quote <order number> in all correspondence.` Note that the customer name comes first even though it is the second argument, and that the order number appears twice. The count is the plain integer, digits only.
2. When `LineCount` is exactly 1, the middle reads `with 1 line is confirmed` — singular. Every other count, 0 included, uses `lines`. Use two labels, one per wording, and pick one; do not stitch the word onto the sentence.
3. Values are data, never template: an empty `CustomerName` produces `Dear , your order ...` (nothing between "Dear" and the comma — no error, no placeholder left behind), and a customer name that itself contains `%1` comes out unchanged, not expanded into the order number.

Rules for `SlipColumn`:

4. The result is always exactly 33 characters: the item number left-aligned in a field 8 characters wide, then one space, then the description left-aligned in a field 24 characters wide. A value shorter than its field is padded with spaces on the right — the trailing spaces are part of the result. A value that is exactly as long as its field fills it with no padding.
5. A value longer than its field is not truncated: the whole field is printed as asterisks instead, so an item number of 9 characters comes out as 8 asterisks and a 25-character description as 24 asterisks. An empty value leaves its field as spaces.
6. Build the line through the `#` placeholder family, not with `PadStr`: a `#` placeholder is exactly as wide as the characters it occupies, the digit included, and `StrSubstNo` does the padding and the asterisks for you.

Keep every text in a `Label` variable with a `Comment` that explains each placeholder, and produce both results with a single `StrSubstNo` call each. The tests can only see what your procedures return, so the labels, their comments and the way you build the strings are not graded — but they are the point of the exercise, and the analyzer will remind you.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

`ConfirmationText('SO-1001', 'Northwind Traders', 3)` returns:

```text
Dear Northwind Traders, your order SO-1001 with 3 lines is confirmed. Please quote SO-1001 in all correspondence.
```

`ConfirmationText('SO-1001', 'Northwind Traders', 1)` returns:

```text
Dear Northwind Traders, your order SO-1001 with 1 line is confirmed. Please quote SO-1001 in all correspondence.
```

`SlipColumn('A-10', 'Blue widget')` and `SlipColumn('ITEM-0009', 'Blue widget')` return the two lines below; the ruler shows the 8 + 1 + 24 character positions, and the dots stand for spaces:

```text
12345678 123456789012345678901234
A-10.... Blue.widget.............
******** Blue.widget.............
```

## What the tests check

The grading tests call both procedures with fixed and generated inputs and compare the **full returned string, character for character** — punctuation, the second sentence, padding spaces and overflow asterisks included. For `ConfirmationText` they cover a generated order number, customer name and line count above 1 (plural), a count of exactly 1 (singular), a count of 0 (plural), an empty customer name (`Dear , your order ...`), and a customer name containing `%1`, which must survive untouched. For `SlipColumn` they check the padding of short values, a value that fills its field exactly, an item number one character too long and a description one character too long (asterisks across the whole field), and an empty description (24 spaces) — every line must be exactly 33 characters, and the failure message tells you how long yours was.

## Learn More

- [Text.StrSubstNo method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strsubstno-method) — the `%n` and `#n` rules, including reuse of one value, left alignment and the overflow asterisks, with worked examples.
- [Label data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/label/label-data-type) — declaring a `Label` variable with `Comment`, `Locked` and `MaxLength`.
- [Working with labels](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-labels) — why user-facing text lives in labels and how translators consume them.
- [CodeCop Warning AA0470](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/analyzers/codecop-aa0470) — the rule that every placeholder needs a comment, with a good and a bad example.
