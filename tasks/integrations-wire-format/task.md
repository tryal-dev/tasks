# Locale-Proof Evaluate and Format

Your extension exchanges documents with an external REST service. On your machine every payload was perfect; then the first Danish customer went live and the service started rejecting documents — amounts arrived as `1.234,56` and dates as `05-02-2026`. Nothing in the code had changed: `Format` and `Evaluate` quietly follow the regional settings of the session they run in, and the customer's server doesn't speak your locale.

Your job is a conversion codeunit that writes and reads the same wire text on every server, whatever its regional settings.

## Requirements

Create a **codeunit** named `"Wire Format"` with four public procedures:

```al
procedure ToWireDecimal(Value: Decimal): Text
procedure ToWireDate(Value: Date): Text
procedure FromWireDecimal(WireText: Text; var Value: Decimal): Boolean
procedure FromWireDate(WireText: Text; var Value: Date): Boolean
```

Rules:

1. `ToWireDecimal` renders the value as culture-invariant wire text: a leading `-` for negative values, plain digits, and a dot `.` before any fractional part — never a group (thousand) separator, never a comma. `1234567.89` must come out as `1234567.89` and `-1234.5` as `-1234.5`.
2. `ToWireDate` renders the date as `YYYY-MM-DD` with zero-padded month and day: 3 February 2026 must come out as `2026-02-03`. Only real (non-zero) dates are graded.
3. `FromWireDecimal` parses wire decimal text into `Value` and returns `true`. Text that is not in wire format returns `false` — that includes locale-formatted text such as `1,5` (a comma is never valid on the wire) as well as outright garbage. It must never raise an error, whatever the text contains.
4. `FromWireDate` does the same for `YYYY-MM-DD` dates: `2026-01-23` parses to 23 January 2026; text in any other shape returns `false` without raising an error.
5. Round trip: any text `ToWireDecimal` or `ToWireDate` produces must be accepted by the matching `FromWire` procedure and yield exactly the original value.
6. After a failed parse, the returned `false` is the only graded signal — whatever is left in the `var` parameter is not checked.

## What the tests check

The `ToWire` procedures are compared against exact strings — note the dot, the leading minus and the zero padding. The `FromWire` procedures are fed valid wire text (which must parse to the exact value), locale-formatted text — comma decimals like `1,5` and day-first dates like `05-02-2026` (each must return `false` — not `true`, and not an error) — and garbage (which must return `false`). Two round-trip tests run on generated values, so hardcoding the examples won't pass.

## Learn More

- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property)
- [System.Format(Any [, Integer] [, Integer]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-integer-method)
- [Evaluate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method)
- [Formatting decimal values in fields](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-field-data)
