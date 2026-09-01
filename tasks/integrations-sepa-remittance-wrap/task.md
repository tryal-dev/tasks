# 140 Characters of Remittance

Your company pays vendors with SEPA credit transfers, and one payment usually settles a whole stack of purchase invoices. The pain.001 file gives you exactly one unstructured remittance line (`<Ustrd>`) per payment — at most 140 characters — and that line is all the vendor's accountant sees when reconciling the money. Your job is the small composer that squeezes the applied invoices into that line: everything when it fits, an honest "and N more" when it doesn't.

## Requirements

Create a **codeunit** named `"SEPA Remittance Builder"` with two public procedures:

```al
procedure AddInvoice(InvoiceNo: Text; Amount: Decimal)
procedure GetRemittanceText(): Text
```

Rules:

1. Each added invoice becomes one **entry**: the invoice number, a single space, and the amount rendered with exactly two decimals, a dot as decimal separator, and no thousand separators — `AddInvoice('INV-1001', 250)` becomes the entry `INV-1001 250.00`, whatever the server's regional settings. Only positive amounts are graded.
2. `GetRemittanceText` joins the entries with `, ` (comma and space), in the order they were added. With no invoices added it returns an empty string.
3. The remittance text is hard-capped at **140 characters**. When the full join is at most 140 characters, return it untouched — a join of exactly 140 is fine.
4. Entries are atomic: an entry is either present in full or omitted entirely — never cut an entry in the middle.
5. When the full join does not fit, keep the longest possible run of **leading** entries and end the text with the suffix `and N more`, where `N` is the number of omitted invoices. The suffix is joined like an entry: `..., INV-1009 10.00, and 4 more`. When not even the first entry fits alongside the suffix, the text is just `and N more`.
6. The suffix consumes capacity too: keep k entries only if the k entries, their separators, and the suffix together stay within 140 characters — `N` is then the total minus k. Dropping entries until the entries alone fit and appending the suffix afterwards overshoots the cap; the count must reflect the space the suffix itself takes.
7. A single entry longer than 140 characters could never be transmitted at all: `AddInvoice` must raise an error the moment such an invoice is added, and the error text must mention the limit `140`.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

Every comparison is an exact string — note the single space inside an entry, the comma and space between entries, the exact `and N more` wording, and the two forced decimals (`250` renders as `250.00`, `13.5` as `13.50`, `1234567.8` as `1234567.80` with no thousand separator). One fixture joins to exactly 140 characters and must come back untouched; another is 141 characters and must become `<first entry>, and 1 more`. Rule 6 is graded with a fixture where ten entries fit on their own but only nine fit next to the suffix — so `N` is 4, not 3. Rule 7 is graded with `asserterror` on `AddInvoice`, and the error text must contain `140`. Two tests run on generated amounts and a generated invoice count, so hardcoding the examples won't pass.

## Learn More

- [Make payments with SEPA credit transfer](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-make-payments-with-bank-data-conversion-service-or-sepa-credit-transfer) — where the remittance line you are composing actually travels: Business Central's SEPA credit transfer payment export.
- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property) — how `Format` expressions control decimals and separators independently of regional settings.
- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type) — the string toolbox for composing and measuring the line.
- [Text.StrLen method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strlen-method) — the length check every capacity decision hangs on.
