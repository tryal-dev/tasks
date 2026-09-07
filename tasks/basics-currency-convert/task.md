# Let the Base App Convert

A supplier sends price lists in EUR and GBP, and a small import has to store each price in local currency (LCY) as well. The first version of the import filtered the exchange rate table by hand, multiplied by whatever it found, and produced LCY amounts that were a cent or two off the invoices posting later created for the very same prices. Business Central already knows how to turn a foreign-currency amount into LCY — every posting routine asks the `Currency Exchange Rate` table (table 330) to do it — and the fix is to ask the same way.

## Requirements

Create a **codeunit** named `"LCY Converter"` with one public procedure:

```al
procedure ToLCY(Amount: Decimal; CurrencyCode: Code[10]; OnDate: Date): Decimal
```

Rules:

1. A blank `CurrencyCode` means the amount already is in LCY: return `Amount` unchanged.
2. Otherwise the amount is converted with the exchange rate row of `CurrencyCode` whose `"Starting Date"` is the latest on or before `OnDate` — a row applies from the very day it starts and stays in force until a newer row takes over. A rate row is a pair: `"Exchange Rate Amount"` units of the currency equal `"Relational Exch. Rate Amount"` units of LCY, so the converted amount is `Amount` divided by `"Exchange Rate Amount"` and multiplied by `"Relational Exch. Rate Amount"`. A row stored as 100 EUR = 745.00 LCY converts exactly like a row stored as 1 EUR = 7.45 LCY.
3. The result is an LCY amount, so it is rounded to the nearest multiple of General Ledger Setup's `"Amount Rounding Precision"` — whatever value the setup holds when `ToLCY` is called — for negative amounts too. The foreign currency's own `"Amount Rounding Precision"` rounds amounts in that currency, never their LCY counterpart — the tests give the currency a different precision, so rounding with the wrong one shows up as a wrong number.
4. When no rate row starts on or before `OnDate`, let the base app's own error surface: do not catch it, and do not return 0 or the unconverted amount instead.
5. `ToLCY` writes nothing. `OnDate` is always a real date, every rate row the tests seed has a blank `"Relational Currency Code"` (no triangulation), and `"Fix Exchange Rate Amount"` keeps its default.

Do the lookup and the arithmetic the way posting does. Table 330 has two public procedures that together are the whole conversion:

- `ExchangeRate(Date, CurrencyCode)` finds the rate row in force on the date and returns the **currency factor**: `"Exchange Rate Amount"` divided by `"Relational Exch. Rate Amount"` — for 1 EUR = 7.45 LCY that is 1 / 7.45. When no row has started yet it raises the table's own `There is no Currency Exchange Rate within the filter` error, which is exactly what rule 4 asks for. A blank code returns a factor of 1.
- `ExchangeAmtFCYToLCY(Date, CurrencyCode, Amount, Factor)` divides `Amount` by the factor you pass in — the header's `"Currency Factor"` when a document is posted, the value `ExchangeRate` returned for your date here. It does **not** look the factor up itself: a factor of 0 divides by zero.

For the rounding, `Currency.Initialize` with a **blank** code copies General Ledger Setup's `"Amount Rounding Precision"` into the `Currency` record — the same move `basics-currency-rounding` uses for invoice rounding. `Round` without a precision argument reads that setup field too, which is why posting code often just wraps the conversion in a plain `Round`.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

General Ledger Setup rounds LCY amounts to 0.01. Rate rows are written as `"Exchange Rate Amount"` : `"Relational Exch. Rate Amount"`.

| Call | Rate rows of the currency | Result |
|---|---|---|
| `ToLCY(1234.56, 'EUR', 2024-03-15)` | 1 : 7.45 from 2024-03-01 | 9197.47 (9197.472 rounded) |
| `ToLCY(1234.59, 'EUR', 2024-03-15)` | same | 9197.70 (9197.6955 rounded) |
| `ToLCY(-1234.59, 'EUR', 2024-03-15)` | same | -9197.70 |
| `ToLCY(250, 'EUR', 2024-03-15)` | 100 : 745 from 2024-03-01 | 1862.50 |
| `ToLCY(100, 'EUR', 2024-04-15)` | 1 : 7.00 from 2024-01-01, 1 : 7.45 from 2024-03-01, 1 : 7.90 from 2024-06-01 | 745.00 |
| `ToLCY(100, 'EUR', 2024-03-01)` | 1 : 7.00 from 2024-01-01, 1 : 7.45 from 2024-03-01 | 745.00 |
| `ToLCY(100, 'EUR', 2024-02-28)` | 1 : 7.45 from 2024-03-01 | error: `There is no Currency Exchange Rate within the filter` |
| `ToLCY(1234.56, '', any date)` | — | 1234.56 |

With General Ledger Setup rounding LCY amounts to 0.05 instead, the first call returns 9197.45 — 9197.472 rounded to the nearest 0.05.

## What the tests check

The grading tests create their own currencies (each with an `"Amount Rounding Precision"` of 0.001, deliberately different from the LCY precision) and seed exchange rate rows through the `Library - ERM` helpers. General Ledger Setup's `"Amount Rounding Precision"` is set to 0.01 in every test but one, which sets it to 0.05 and expects the 1234.56 example to come back as 9197.45 rather than 9197.47. The rounding and negative-amount examples are graded with the fixed amounts and the 1 : 7.45 row shown above. The other conversions use a generated rate with two decimals between 5 and 9 and a generated whole-number amount, and must equal the amount times the rate exactly: the rate seeded per unit (1 : rate), the same rate seeded per hundred units (100 : rate × 100), and the rate as the middle of three rows starting January 1, March 1 and June 1 (rate − 1, rate, rate + 1) converted on April 15. The two date-boundary tests seed a row on a generated starting date in 2024: converting on that very date must use that row rather than the earlier one, and converting the day before it, when it is the only row, must fail with an error whose text contains `There is no Currency Exchange Rate within the filter`. A blank currency code is tested with a generated two-decimal amount, which must come back exactly as passed. Every comparison is an exact decimal equality.

## Learn More

- [Update currency exchange rates](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-how-update-currencies) — what Exchange Rate Amount and Relational Exch. Rate Amount mean, and the formula posting applies to them.
- [Set up currencies](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-set-up-currencies) — why a currency's Amount Rounding Precision applies to foreign-currency amounts only, never to their LCY counterpart.
- [System.Round method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method) — the precision argument, and where the default precision comes from when it is omitted.
