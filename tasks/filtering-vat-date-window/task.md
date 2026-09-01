# VAT Totals by VAT Date

The December VAT return came out wrong twice this year: an invoice posted in early January belonged on December's return, and an invoice posted in late December belonged on January's. Both are correct bookings — VAT reporting periods are simply cut by a document's **VAT date**, which is allowed to differ from its posting date. Your job is the little aggregation routine the VAT return will be built on, and it must slice VAT Entries the way the tax office does.

## Requirements

Create a **codeunit** named `"VAT Period Totals"` with one public procedure:

```al
procedure VatTotalsForPeriod(VatBusPostingGroup: Code[20]; VatProdPostingGroup: Code[20]; FromDate: Date; ToDate: Date; var TotalBase: Decimal; var TotalAmount: Decimal)
```

Rules:

1. The procedure sums the `Base` and `Amount` fields of the `VAT Entry` records that belong to the VAT period from `FromDate` through `ToDate` — **both boundary days included** — and returns the sums in `TotalBase` and `TotalAmount`.
2. An entry belongs to the period containing its VAT date, stored in the `"VAT Reporting Date"` field (the UI shows it as **VAT Date**). For entries that have a VAT date, the posting date plays no role.
3. Entries with a **blank** VAT date (they were migrated from the old system) belong to the period containing the date the company's default points at: the `"VAT Reporting Date"` field on `General Ledger Setup` (shown as **Default VAT Date**) says whether that is the entry's `"Posting Date"` or its `"Document Date"`.
4. Only entries whose `"VAT Bus. Posting Group"` **and** `"VAT Prod. Posting Group"` both equal the parameters count.
5. Both results are signed sums — credit memos carry negative base and amount and reduce the totals.
6. The procedure sets both outputs: a period with no matching entries returns 0 in `TotalBase` and `TotalAmount` whatever values the caller passed in — that is a normal answer, not an error.
7. `FromDate` and `ToDate` are always real (nonblank) dates with `FromDate` on or before `ToDate`.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The grading tests insert VAT Entries directly, under posting-group codes generated per test and with amounts generated at run time — the answers cannot be hardcoded, and entries already in the company never interfere. For a December period they assert **exact totals in both outputs** for: an entry VAT-dated in December but posted in January (it must count); an entry posted in December but VAT-dated in January (it must not); the signed sum of several entries including a negative credit memo; entries VAT-dated exactly on `FromDate` and exactly on `ToDate` (both count, the days just outside do not); decoy entries sharing only one of the two posting groups (they must not count); blank-VAT-date entries under **both** Default VAT Date settings — each time paired with a decoy whose *other* date lies inside the window, plus a blank-dated decoy under a different posting-group pair whose fallback date is inside the window, so a fallback to the wrong date field fails and the posting-group filters must hold for the blank-date entries too; and a period with no matching entries, called with nonzero values already in the output parameters (expect 0 in both).

## Learn More

- [Work with VAT Date](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-work-with-vat#working-with-vat-date) — how the VAT date decides which return an entry lands on.
- [Set up a default VAT date](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-setup-vat#set-up-a-default-vat-date-for-documents-and-journals) — the Default VAT Date setting the blank-date fallback obeys.
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method) — range filters on a date field.
- [Record.CalcSums Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcsums-method) — summing columns under the current filters.
