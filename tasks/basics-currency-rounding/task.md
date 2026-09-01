# Round Like the Currency Says

A custom pricing feature computes invoice totals and unit prices in code, and a reviewer spotted the same `0.01` hardcoded in every rounding call. Finance does not round that way: Swiss francs are invoiced to the nearest 0.05, yen carry no decimals at all, and each of those rules lives on the **Currency card** — or, for the local currency, in **General Ledger Setup**. Code that ignores the setup prints totals no cashier can settle.

Your job is a small codeunit that rounds the way the currency says.

## Requirements

Create a **codeunit** named `"Currency Rounding"` with two public procedures:

```al
procedure RoundInvoiceTotal(Amount: Decimal; CurrencyCode: Code[10]): Decimal
procedure RoundUnitPrice(Amount: Decimal; CurrencyCode: Code[10]): Decimal
```

Rules:

1. `RoundInvoiceTotal` rounds `Amount` to a multiple of the currency's `"Invoice Rounding Precision"`, in the direction its `"Invoice Rounding Type"` asks for — `Nearest`, `Up` or `Down`.
2. `RoundUnitPrice` rounds `Amount` to the **nearest** multiple of the currency's `"Unit-Amount Rounding Precision"`. The invoice rounding type plays no part here: a currency that rounds invoices up still rounds unit prices to the nearest.
3. A blank `CurrencyCode` means the local currency (LCY), and the values then come from General Ledger Setup: `"Inv. Rounding Precision (LCY)"`, `"Inv. Rounding Type (LCY)"` and `"Unit-Amount Rounding Precision"`. The `Currency` record's `Initialize` procedure handles this branch for you — given a blank code, it fills the record's rounding fields from General Ledger Setup; given any other code, it reads that currency card — so your code can read the same fields either way.
4. `Up` and `Down` mean what the AL `Round` method means by its `'>'` and `'<'` directions, not what a calculator's ceiling and floor mean: `'>'` moves **away from zero** and `'<'` moves **toward zero**, for negative amounts too. A credit memo total of -10.01 in a currency that rounds up to 0.05 becomes -10.05, and -10.99 in a currency that rounds down to whole units becomes -10.
5. `CurrencyCode` is always blank or the code of a currency that exists, and every precision the tests configure is greater than zero. Neither procedure writes anything — they read setup and return a value.

Two things to know before you start:

- `Round` takes the direction as a text argument: `'='` for nearest, `'>'` for up, `'<'` for down. `Currency.InvoiceRoundingDirection()` returns exactly that text for the record's `"Invoice Rounding Type"`, so there is nothing to translate by hand.
- `"Amount Rounding Precision"` is a third, different field (it rounds line amounts). Reading it instead of the invoice or unit-amount precision fails both procedures. Likewise, re-implementing the rounding with your own division-and-ceiling arithmetic goes wrong on negative amounts — let `Round` do it.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

| Call | Currency setup | Result |
|---|---|---|
| `RoundInvoiceTotal(10.01, 'CHF-like')` | Invoice Rounding Precision 0.05, type Up | 10.05 |
| `RoundInvoiceTotal(-10.01, 'CHF-like')` | same | -10.05 |
| `RoundInvoiceTotal(10.99, 'JPY-like')` | Invoice Rounding Precision 1.00, type Down | 10 |
| `RoundInvoiceTotal(-10.99, 'JPY-like')` | same | -10 |
| `RoundUnitPrice(12.3456, 'CHF-like')` | Unit-Amount Rounding Precision 0.001 | 12.346 |
| `RoundUnitPrice(7.46, 'JPY-like')` | Unit-Amount Rounding Precision 0.1 | 7.5 |

## What the tests check

The grading tests create three currencies of their own — one with an invoice rounding precision of 0.05 and type `Up` and a unit-amount precision of 0.001, another with 1.00 and type `Down` and a unit-amount precision of 0.1, and a third with 0.05 and type `Nearest` (checked with 10.02, which must become 10.00, and 10.03, which must become 10.05) — and set General Ledger Setup to an LCY invoice rounding precision of 0.25 with type `Up` and a unit-amount precision of 0.001. The `"Amount Rounding Precision"` is 0.01 on all of them, so a read of the wrong field shows up as a wrong number. Each procedure is called with the positive and negative amounts from the examples, with an amount that already sits on its precision (it must come back unchanged), with a generated amount, and with a blank currency code. Every comparison is an exact decimal equality.

## Learn More

- [System.Round method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method) — the precision and direction parameters, with a table showing what `'>'` and `'<'` do to negative numbers.
- [Set up invoice rounding](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-set-up-invoice-rounding) — where the invoice rounding precision and type live for foreign currencies and for LCY.
- [Set up currencies](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-set-up-currencies) — the Currency card fields, and how unit-amount rounding differs from amount rounding.
