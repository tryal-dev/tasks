codeunit 50100 "Compound Interest"
{
    procedure MonthlyPayment(Principal: Decimal; AnnualRatePct: Decimal; Months: Integer): Decimal
    begin
        // TODO: annuity formula — and remember an interest-free loan has nothing to compound.
        exit(0);
    end;

    procedure EffectiveAnnualRate(NominalRatePct: Decimal; CompoundingsPerYear: Integer): Decimal
    begin
        // TODO: compound the per-period rate CompoundingsPerYear times and return a percentage.
        exit(0);
    end;

    procedure CAGR(StartValue: Decimal; EndValue: Decimal; Years: Decimal): Decimal
    begin
        // TODO: reject non-positive inputs, then take the Years-th root of the total growth.
        exit(0);
    end;
}
