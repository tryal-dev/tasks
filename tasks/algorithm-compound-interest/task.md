# Math Without an Operator

The CFO wants three numbers Business Central will not give her out of the box: what a loan costs per month, what a nominal interest rate really amounts to over a year, and how fast a portfolio has actually grown. Every one of these formulas raises a number to a power — and when you reach for `^` or `**`, the AL compiler politely informs you that no such operator exists. Your job is to build the small finance codeunit anyway.

## Requirements

Create a **codeunit** named `"Compound Interest"` with three public procedures:

```al
procedure MonthlyPayment(Principal: Decimal; AnnualRatePct: Decimal; Months: Integer): Decimal
procedure EffectiveAnnualRate(NominalRatePct: Decimal; CompoundingsPerYear: Integer): Decimal
procedure CAGR(StartValue: Decimal; EndValue: Decimal; Years: Decimal): Decimal
```

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

### `MonthlyPayment` — the annuity formula

- The monthly rate is r = AnnualRatePct ÷ 100 ÷ 12, so `MonthlyPayment(200000, 6, 360)` uses r = 0.005.
- The payment is Principal × r × (1 + r)^Months ÷ ((1 + r)^Months − 1). For the 200,000 loan at 6% over 360 months that is 1,199.10 a month.
- **Zero-rate special case:** when AnnualRatePct is 0, the formula above divides by zero — an interest-free loan simply splits the principal evenly, so return Principal ÷ Months.
- The tests only pass Principal > 0, AnnualRatePct ≥ 0 and Months ≥ 1; you do not need to validate these inputs.

### `EffectiveAnnualRate` — what a nominal rate compounds to

- A nominal annual rate of NominalRatePct, compounded CompoundingsPerYear times a year, really yields ((1 + NominalRatePct ÷ 100 ÷ CompoundingsPerYear)^CompoundingsPerYear − 1) × 100 percent per year.
- Example: 12% compounded monthly is `EffectiveAnnualRate(12, 12)` = 12.682503…% — return the percentage, not the fraction.
- With annual compounding (CompoundingsPerYear = 1) the effective rate equals the nominal rate, and a 0% nominal rate yields 0 — both fall out of the formula with no special casing.
- The tests only pass NominalRatePct ≥ 0 and CompoundingsPerYear ≥ 1.

### `CAGR` — compound annual growth rate

- A value that grew from StartValue to EndValue over Years years grew at ((EndValue ÷ StartValue)^(1 ÷ Years) − 1) × 100 percent per year.
- `Years` is a Decimal and may be fractional: 2.5 years is a valid holding period, and the exponent 1 ÷ Years is then not a whole number.
- When EndValue is smaller than StartValue the result is negative, and when they are equal it is 0.
- If StartValue, EndValue or Years is zero or negative, the math is meaningless — raise an error with a message that contains the word `positive`.

Return the raw computed values — **do not round**. Payments are graded within ±0.01, so rounding a payment to the cent happens to survive, but rounding a rate to two decimals will fail the ±0.0001 tolerance on the rate procedures.

## What the tests check

Fixed textbook cases are asserted within tolerance (±0.01 on payments, ±0.0001 on percentage rates): the 200,000 mortgage above, an interest-free loan, a one-month loan (which must come out at Principal × (1 + r)), monthly versus annual compounding, a 0% nominal rate, a portfolio that doubles in ten years (7.1773…% a year), one that halves (negative CAGR), one that is flat (0), and a fractional 2.5-year holding period. `CAGR` must raise the promised error (message checked for `positive`) for a zero or negative StartValue, EndValue and Years. Finally, randomly generated loans, rates and growth histories are graded against an independent computation of the same formulas, so hardcoding the examples fails.

## Learn More

- [AL operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-operators) — the complete operator list; note which arithmetic operators AL does and does not have.
- [Arithmetic operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-arithmetic-operators) — how AL converts types when Integers and Decimals mix in a formula.
- [Decimal data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type) — range and precision of the type all three procedures return.
- [Dialog.Error method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method) — raising the validation error `CAGR` promises.
