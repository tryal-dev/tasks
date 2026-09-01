# One Procedure, Any Type

Your team's audit log helper receives event payloads from all over the system — a customer record here, an amount there, sometimes just a flag. The payload arrives as a `Variant`, and your job is to render whatever is inside into one stable, machine-readable log line. A `Variant` will happily hold almost anything; the catch is that *you* must find out what it holds before you can safely convert it, and the type probes are not as innocent as they look.

## Requirements

Create a **codeunit** named `"Variant Formatter"` with two public procedures:

```al
procedure FormatValue(Value: Variant): Text
procedure TryFormatValue(Value: Variant; var FormattedValue: Text): Boolean
```

`FormatValue` inspects the Variant with its type probes (`IsRecord`, `IsBoolean`, `IsGuid`, `IsOption`, `IsInteger`, `IsDecimal`, `IsDate`, `IsCode`, `IsText`) and returns the payload in the canonical shape `<type name>: <payload>` — type name, colon, one space, then the payload rendered as follows:

- **Record** (any table): `Record: ` followed by the table's name — a Customer record gives `Record: Customer`.
- **Boolean**: `Boolean: true` or `Boolean: false` — lowercase, never `Yes`/`No`.
- **Guid**: `Guid: ` followed by the default AL rendering of a Guid — uppercase hex wrapped in braces, like `Guid: {6B29FC40-CA47-1067-B31D-00DD010662DA}`.
- **Option**: `Option: ` followed by the value's zero-based position among the option's members, as plain digits — the third member gives `Option: 2`, not its name.
- **Integer**: `Integer: ` followed by plain digits, with a leading minus for negative values.
- **Decimal**: `Decimal: ` followed by the number with a dot as the decimal separator and no thousands separators, whatever the server's regional settings — `Decimal: 1234567.5`, never `1.234.567,5`.
- **Date**: `Date: ` followed by the date as `yyyy-mm-dd` — `Date: 2026-04-07`.
- **Code**: `Code: ` followed by the stored value (Code values are stored uppercased, so that is what comes back).
- **Text**: `Text: ` followed by the payload exactly as it was passed in — no trimming, no case changes.
- Anything else (Time, DateTime, Char, BigInteger, …): raise an error with the exact message `Unsupported value type.`

`TryFormatValue` is the companion for callers that must never crash:

- For a supported payload it sets `FormattedValue` to exactly what `FormatValue` would return and returns `true`.
- For an unsupported payload it returns `false` and sets `FormattedValue` to empty text — clearing whatever the variable held before the call — and it never raises an error.

Two warnings, because both failure modes are invisible until run time:

- The probes are **not guaranteed to be mutually exclusive**: a Code payload can also answer `true` to `IsText`, and an Option payload is integer-backed and can also answer `true` to `IsInteger`. A chain that asks the general question before the specific one sends the value down the wrong branch and produces the wrong tag.
- The plain one-argument `Format` obeys the server's regional settings for dates and decimals — a solution that relies on it can look right on your machine and still fail on the grading container. The canonical shapes above are fixed.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The tests call `FormatValue` with one Variant per supported type and compare the returned text **exactly** — note the colon-space separator, the lowercase booleans, the `yyyy-mm-dd` date shape, and the dot decimal separator with no thousands separators. Integer, decimal, text, guid, and date inputs are randomly generated, so the payload must really be converted, not recognized. A randomly generated lowercase Text payload must come back byte-for-byte, while a Code payload assigned from randomly generated lowercase text must come back uppercased as stored; option payloads are graded with two differently shaped option lists and two different member positions, so the zero-based number must be read from the value; records are graded with two different tables, so the table name must be read, not hardcoded. One test passes a Time value and expects `FormatValue` to fail with the exact message `Unsupported value type.` — the entire message is compared, period included; two more drive `TryFormatValue` — a supported payload (a negative integer, so the leading minus is graded too) must yield `true` plus the formatted text, and a DateTime payload must yield `false` with `FormattedValue` cleared to empty even though the variable held leftover content before the call.

## Learn More

- [Variant data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type) — the full catalog of `Is<Type>` probes available on a Variant.
- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property) — the standard format numbers, including the culture-invariant XML format.
- [RecordRef.GetTable method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-gettable-method) — turning a record payload into something you can ask for its table name.
- [Option data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type) — why option values are integer-backed.
