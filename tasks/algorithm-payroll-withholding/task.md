# The Payslip Engine

Your client's payroll add-on prints a monthly payslip: gross pay in, income tax and national insurance (NI) withheld, net pay out. The finance team re-keys the government's figures into setup tables every fiscal year, so the engine must be entirely table-driven — no rate, threshold, or allowance may live in code.

## What you are given

The starter contains three finished tables — submit them unchanged alongside your codeunit:

- Table `"Payslip Setup"` — one setup record: field 1 `"Primary Key"` (`Code[10]`, PK), field 2 `"Personal Allowance"` (`Decimal`), field 3 `"Taper Threshold"` (`Decimal`).
- Table `"Income Tax Band"` — field 1 `"Line No."` (`Integer`, PK), field 2 `Threshold` (`Decimal`), field 3 `"Rate %"` (`Decimal`).
- Table `"NI Contribution Band"` — the same three fields as the income tax band table.

## Requirements

Implement a **codeunit** named `"Payslip Engine"` with four public procedures, exactly as written:

```al
procedure PersonalAllowance(GrossPay: Decimal): Decimal
procedure IncomeTax(GrossPay: Decimal): Decimal
procedure NIContribution(GrossPay: Decimal): Decimal
procedure NetPay(GrossPay: Decimal): Decimal
```

How a band table works — the same semantics for both tables:

- Read the rows in ascending `Threshold` order. Each band charges its `"Rate %"` on the slice of the amount that lies above its own threshold and at most up to the next band's threshold; the highest band charges its rate on everything above its threshold.
- Any part of the amount at or below the lowest threshold is charged nothing.
- Rows may carry any `"Line No."` values in any order — only the thresholds order the bands, never the line numbers.

The four procedures:

- `PersonalAllowance` starts from the setup record's `"Personal Allowance"`. When gross pay exceeds the `"Taper Threshold"`, the allowance shrinks by 1 for every 2 of gross pay above the threshold — pay of threshold + X removes X / 2 of allowance. The result never drops below zero.
- `IncomeTax` charges the income tax bands on the taxable pay: gross pay minus `PersonalAllowance(GrossPay)`, floored at zero.
- `NIContribution` charges the NI bands on gross pay itself — the personal allowance plays no part in NI.
- `NetPay` is gross pay minus income tax minus NI contribution.
- Round every returned amount to the nearest cent (2 decimal places).

Worked example — allowance 12570.00, taper threshold 100000.00, tax bands (threshold → rate) 0 → 20, 37700 → 40, 125140 → 45, NI bands 12570 → 8, 50270 → 2:

- Gross pay 110000.00: allowance = 12570 − 10000 / 2 = 7570.00, so taxable pay is 102430.00; income tax = 37700 × 20% + 64730 × 40% = 33432.00; NI = 37700 × 8% + 59730 × 2% = 4210.60.
- Gross pay 130000.00: the allowance is fully tapered to 0.00 (130000 ≥ 100000 + 2 × 12570); income tax = 37700 × 20% + 87440 × 40% + 4860 × 45% = 44703.00; NI = 37700 × 8% + 79730 × 2% = 4610.60; net pay = 130000 − 44703.00 − 4610.60 = 80686.40.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

What you may rely on — the tests never violate this: gross pay is always positive; before any procedure is called, the setup record exists and both band tables hold at least two rows; every asserted value is exact at 2 decimal places once you have rounded to the nearest cent, and no half-cent rounding ties ever occur.

## What the tests check

`PersonalAllowance` is graded at gross pay exactly on the taper threshold (full allowance), inside the taper zone, exactly at the fully-tapered point (zero), far beyond it (still zero, never negative), and against a generated setup with a generated excess. `IncomeTax` is graded on pay within the allowance (zero), on taxable pay ending exactly at a band edge, just into the next band, in the taper zone (the tapered allowance must feed the taxable pay), when fully tapered, with band rows deliberately numbered out of threshold order, with a fractional rate whose raw charge carries more than 2 decimals — only the nearest-cent result passes — and against a fully generated band table whose expected tax the test computes independently — so hardcoding any example fails. `NIContribution` is graded at the lowest threshold (zero), inside the main band, above the upper threshold, and against generated NI bands. `NetPay` is graded on the worked example and on pay where nothing is due. All assertions are exact to the cent.

## Learn More

- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods) — reading the single setup record and stepping through the band rows.
- [Record.FindSet method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method) — the idiomatic way to loop a filtered, sorted record set.
- [System.Round method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method) — rounding a decimal to a chosen precision, such as the nearest cent.
- [Decimal data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type) — how AL's decimal arithmetic behaves before you round.
