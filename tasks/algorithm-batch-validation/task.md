# Master Data Gatekeeper

A legacy purchasing system exports vendor applications as one long text: records separated by `|`, and each record a list of `KEY=VALUE` fields separated by `;`. Before the import job creates any vendors, the gatekeeper must answer one question: how many of these applications are actually importable? A record counts only when every mandatory field is present and passes its rule — everything else is quietly rejected.

## Requirements

Create a **codeunit** named `"Batch Validator"` with one public procedure:

```al
procedure CountValid(Batch: Text): Integer
```

`CountValid` returns the number of valid records in the batch. It never raises an error — an unreadable record is simply an invalid one. An empty or all-spaces `Batch` yields 0.

### Reading the batch

1. Records are separated by `|`. A record that is empty or only spaces is skipped entirely — it is neither valid nor invalid.
2. Fields within a record are separated by `;`. Field segments that are empty or only spaces are skipped.
3. Each field segment is cut at its **first** `=`: the part before it is the key, and everything after it is the value. Both are trimmed of leading and trailing spaces; inner spaces are preserved.
4. A field segment that has no `=`, or whose key is empty after trimming, makes the **whole record** invalid.
5. When the same key appears more than once in a record, the **last** occurrence is the one that gets validated.
6. Keys are case-sensitive. Keys other than the four mandatory ones below are ignored — extra fields never invalidate a record.

### The rules

A record is valid exactly when all four mandatory fields are present and each value passes its rule:

- `VAT` — exactly 2 uppercase letters `A`–`Z` followed by exactly 9 digits, for example `DE123456789`. Lowercase letters, a wrong length, or any other character fail.
- `POSTCODE` — exactly 5 digits. Leading zeros are fine: `00123` passes; `123`, `123456`, and `12A45` fail.
- `CREDIT` — digits only, and its numeric value is between 500 and 20000 **inclusive**. A sign, a thousands separator, or decimals fail (`-500`, `1,500`, `1500.00`); leading zeros are fine (`00500` is 500).
- `CURRENCY` — exactly `EUR`, `USD`, or `GBP`, case-sensitive (`eur` and `EURO` fail).

## What the tests check

The tests call `CountValid` and check every rule above: a fully valid record; each mandatory field missing in turn; extra unknown fields being ignored; a catalogue of bad VAT, POSTCODE, and CURRENCY values; the CREDIT boundaries 499/500/20000/20001; leading zeros in POSTCODE and CREDIT; spaces around keys and values; blank records and blank field segments; last-occurrence-wins for duplicate keys; a record invalidated by a segment without `=` and by an empty key; and a randomized batch where only the generated valid records may be counted. One record carries a 30-digit `CREDIT` — it is merely out of range, and your code must reject it without crashing.

## Learn More

- [Text.Split method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-split-text-method)
- [Text.Trim method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-trim-method)
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type)
- [System.Evaluate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method)
- [Text.CopyStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method)
