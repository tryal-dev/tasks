codeunit 50900 "Compound Interest Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MortgagePaymentMatchesTheTextbookValue()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The statement's worked example: 200,000 at 6% over 360 months
        Assert.AreNearlyEqual(1199.10, CompoundInterest.MonthlyPayment(200000, 6, 360), 0.01,
            'Expected the monthly payment on a 200,000 loan at 6% over 360 months to be 1199.10');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroRateLoanSplitsThePrincipalEvenly()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The annuity formula divides by zero at a 0% rate; the payment must be Principal / Months
        Assert.AreNearlyEqual(500, CompoundInterest.MonthlyPayment(12000, 0, 24), 0.01,
            'Expected an interest-free 12,000 loan over 24 months to cost exactly 500 a month — a 0% rate splits the principal evenly');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneMonthLoanRepaysPrincipalPlusOneMonthOfInterest()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] With Months = 1 the annuity formula collapses to Principal * (1 + r)
        Assert.AreNearlyEqual(1010, CompoundInterest.MonthlyPayment(1000, 12, 1), 0.01,
            'Expected a 1000 loan at 12% repaid in a single month to cost 1010 — the principal plus one month of interest at 1%');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthlyCompoundingBeatsTheNominalRate()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        Assert.AreNearlyEqual(12.68250301, CompoundInterest.EffectiveAnnualRate(12, 12), 0.0001,
            'Expected a 12% nominal rate compounded monthly to yield an effective 12.682503% — remember to return the unrounded percentage');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualCompoundingEqualsTheNominalRate()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        Assert.AreNearlyEqual(8, CompoundInterest.EffectiveAnnualRate(8, 1), 0.0001,
            'Expected an 8% nominal rate compounded once a year to yield exactly 8% — compounding once changes nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroNominalRateHasZeroEffectiveRate()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        Assert.AreNearlyEqual(0, CompoundInterest.EffectiveAnnualRate(0, 12), 0.0001,
            'Expected a 0% nominal rate to yield a 0% effective rate no matter how often it compounds');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoublingInTenYearsGrowsSevenPercentAYear()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        Assert.AreNearlyEqual(7.17734625, CompoundInterest.CAGR(1000, 2000, 10), 0.0001,
            'Expected a portfolio that doubles in 10 years to have a CAGR of 7.177346% — the tenth root of 2, minus 1, as a percentage');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnchangedValueHasZeroCagr()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        Assert.AreNearlyEqual(0, CompoundInterest.CAGR(5000, 5000, 8), 0.0001,
            'Expected a value that ends where it started to have a CAGR of 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShrinkingValueHasNegativeCagr()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        Assert.AreNearlyEqual(-6.69670085, CompoundInterest.CAGR(2000, 1000, 10), 0.0001,
            'Expected a portfolio that halves in 10 years to have a CAGR of -6.696701% — shrinking values must come out negative');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FractionalYearsAreSupported()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Years = 2.5 makes the exponent 0.4 — a whole-number power loop cannot get here
        Assert.AreNearlyEqual(7.56537569, CompoundInterest.CAGR(10000, 12000, 2.5), 0.0001,
            'Expected growth from 10,000 to 12,000 over 2.5 years to be a CAGR of 7.565376% — 1.2 raised to the power 1/2.5');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroStartValueIsAnError()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        asserterror CompoundInterest.CAGR(0, 1000, 5);
        Assert.ExpectedError('positive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeEndValueIsAnError()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        asserterror CompoundInterest.CAGR(1000, -50, 5);
        Assert.ExpectedError('positive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroYearsIsAnError()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
    begin
        asserterror CompoundInterest.CAGR(1000, 2000, 0);
        Assert.ExpectedError('positive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomZeroRateLoanSplitsThePrincipalEvenly()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Principal: Decimal;
        Months: Integer;
    begin
        // [SCENARIO] A generated interest-free loan defeats hardcoding the statement's 12,000 / 24 example
        Principal := Any.DecimalInRange(1000, 100000, 2);
        Months := Any.IntegerInRange(2, 120);

        Assert.AreNearlyEqual(Principal / Months, CompoundInterest.MonthlyPayment(Principal, 0, Months), 0.01,
            StrSubstNo('Expected an interest-free %1 loan over %2 months to split the principal evenly across the payments', Principal, Months));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomLoanMatchesTheAnnuityFormula()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Principal: Decimal;
        AnnualRatePct: Decimal;
        Months: Integer;
    begin
        Principal := Any.DecimalInRange(50000, 300000, 2);
        AnnualRatePct := Any.DecimalInRange(1, 12, 2);
        Months := Any.IntegerInRange(12, 360);

        Assert.AreNearlyEqual(ExpectedPayment(Principal, AnnualRatePct, Months),
            CompoundInterest.MonthlyPayment(Principal, AnnualRatePct, Months), 0.01,
            StrSubstNo('Expected the annuity payment for a %1 loan at %2 percent over %3 months', Principal, AnnualRatePct, Months));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomCompoundingMatchesTheEffectiveRateFormula()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NominalRatePct: Decimal;
        CompoundingsPerYear: Integer;
    begin
        NominalRatePct := Any.DecimalInRange(1, 15, 2);
        CompoundingsPerYear := Any.IntegerInRange(2, 365);

        Assert.AreNearlyEqual((Power(1 + NominalRatePct / 100 / CompoundingsPerYear, CompoundingsPerYear) - 1) * 100,
            CompoundInterest.EffectiveAnnualRate(NominalRatePct, CompoundingsPerYear), 0.0001,
            StrSubstNo('Expected the effective annual rate for a nominal %1 percent compounded %2 times a year', NominalRatePct, CompoundingsPerYear));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomGrowthMatchesTheCagrFormula()
    var
        CompoundInterest: Codeunit "Compound Interest";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartValue: Decimal;
        EndValue: Decimal;
        Years: Decimal;
    begin
        StartValue := Any.DecimalInRange(1000, 100000, 2);
        // A factor between 0.5 and 3 exercises shrinking as well as growing portfolios.
        EndValue := StartValue * Any.DecimalInRange(0.5, 3, 2);
        Years := Any.DecimalInRange(2, 20, 1);

        Assert.AreNearlyEqual((Power(EndValue / StartValue, 1 / Years) - 1) * 100,
            CompoundInterest.CAGR(StartValue, EndValue, Years), 0.0001,
            StrSubstNo('Expected the CAGR of growth from %1 to %2 over %3 years', StartValue, EndValue, Years));
    end;

    local procedure ExpectedPayment(Principal: Decimal; AnnualRatePct: Decimal; Months: Integer): Decimal
    var
        MonthlyRate: Decimal;
        GrowthFactor: Decimal;
    begin
        MonthlyRate := AnnualRatePct / 100 / 12;
        GrowthFactor := Power(1 + MonthlyRate, Months);
        exit(Principal * MonthlyRate * GrowthFactor / (GrowthFactor - 1));
    end;
}
