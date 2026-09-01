# The Next Serial Number

Your vendor ships every unit with a serial number already printed on it, and the numbers follow the vendor's own pattern — `SN-2024-0099`, `A10B20`, `LOT-0005`. When the warehouse posts a goods receipt for the next batch, your extension has to hand out the serial numbers that continue that pattern from the last one recorded, so nobody types a hundred labels by hand.

## Requirements

Create a **codeunit** named `"Serial Number Generator"` with two public procedures:

```al
procedure NextSerials(LastSerial: Text; Qty: Integer): List of [Text]
procedure Advance(Serial: Text; By: Integer): Text
```

Rules:

1. `Advance` returns `Serial` with the number closest to the **end** of the text increased by `By`. Every other character stays exactly as it is, including any earlier numbers: `A10B20` advanced by 1 is `A10B21`, not `A11B21`. `By` is always 1 or greater.
2. Leading zeros are preserved: `SN-2024-0099` advanced by 1 is `SN-2024-0100`, and `LOT-0005` advanced by 20 is `LOT-0025`.
3. When the number needs one more digit, the text simply grows: `X999` advanced by 1 is `X1000`.
4. A dot is not a decimal point here — the digits after it are a number of their own: `B1.9` advanced by 1 is `B1.10`.
5. `NextSerials` returns `Qty` serials in order: the first is `LastSerial` advanced by 1, and each further one is the previous serial advanced by 1. `Qty` is 0 or greater; for 0 the list is empty.
6. A serial with no digits anywhere cannot be advanced. Both procedures must then raise the error `Serial number %1 contains no digits to increment.` with the offending serial in place of `%1` — never return a blank text or hand out an empty serial.

AL already knows how to do this arithmetic. `IncStr` moves the number closest to the end of a text by one with exactly the rules above, and since Business Central 26 the overload `IncStr(Text, BigInteger)` moves it by any step in a single call. When the text contains no digits at all, `IncStr` does not fail — it returns an empty string, and that empty result is your cue to raise the error. Use object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The grading tests call `NextSerials` with `SN-2024-0099` and 1 (expecting exactly one element, `SN-2024-0100`), with `A10B20` and a random quantity between 2 and 8 (expecting that many elements — `A10B21`, `A10B22`, … in order), with `X999` and 2 (expecting `X1000` then `X1001`), with `B1.9` and 1 (expecting `B1.10`), and with a quantity of 0 (expecting an empty list). `Advance` is called with `LOT-0005` and 20 (expecting `LOT-0025`), with `LOT-0005` and a random step up to 9000 (expecting the four-digit number to grow by exactly that step, still zero-padded to four digits), and with `SN-2024-0099` and 1 (expecting `SN-2024-0100`). Finally each procedure is called with a random all-letter serial and must raise an error with a message that starts with `Serial number <that serial> contains no digits`. Every string comparison is exact — note the leading zeros.

## Learn More

- [Text.IncStr(Text) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-incstr-method) — the exact rules for which number moves, how `99` becomes `100`, and what a text without digits returns.
- [Text.IncStr(Text, BigInteger) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-incstr-string-biginteger-method) — the overload that moves the number by any step in one call.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — `Add`, `Count` and `Get` on a `List of [Text]`, and why a list is 1-based.
- [Dialog.Error(Text [, Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method) — raising an error with `%1` placeholders filled from your values.
