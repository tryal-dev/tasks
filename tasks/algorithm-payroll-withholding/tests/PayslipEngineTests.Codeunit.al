codeunit 50900 "Payslip Engine Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FullAllowanceAtTheTaperThreshold()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Gross pay exactly at the taper threshold keeps the full allowance — the taper starts only ABOVE it
        SeedStandardPayroll();
        Assert.AreEqual(12570.0, PayslipEngine.PersonalAllowance(100000.0), 'Expected the full personal allowance at gross pay exactly equal to the taper threshold — the taper applies only to pay above it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllowanceTapersOnePerTwoAboveThreshold()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 10000 above the threshold removes 5000 of allowance
        SeedStandardPayroll();
        Assert.AreEqual(7570.0, PayslipEngine.PersonalAllowance(110000.0), 'Expected the allowance reduced by 1 for every 2 of gross pay above the taper threshold: 12570 - 10000/2');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllowanceIsZeroExactlyAtFullTaper()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] At threshold + 2 x allowance the reduction equals the allowance exactly
        SeedStandardPayroll();
        Assert.AreEqual(0.0, PayslipEngine.PersonalAllowance(125140.0), 'Expected an allowance of exactly zero at gross pay of taper threshold + 2 x allowance (100000 + 25140)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllowanceNeverGoesNegative()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Far past the full-taper point the allowance stays at zero instead of going negative
        SeedStandardPayroll();
        Assert.AreEqual(0.0, PayslipEngine.PersonalAllowance(180000.0), 'Expected the allowance floored at zero for gross pay far above the full-taper point — it must never go negative');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedTaperReductionMatchesFormula()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Allowance: Integer;
        TaperThreshold: Integer;
        HalfExcess: Integer;
        GrossPay: Integer;
    begin
        // [SCENARIO] A generated setup and a generated excess taper by exactly half the excess — hardcoded UK numbers fail here
        Allowance := Any.IntegerInRange(8000, 15000);
        TaperThreshold := Any.IntegerInRange(60000, 120000);
        HalfExcess := Any.IntegerInRange(1, 3000);
        GrossPay := TaperThreshold + 2 * HalfExcess;

        ClearPayroll();
        SeedSetup(Allowance, TaperThreshold);
        SeedStandardBands();

        Assert.AreEqual(Allowance - HalfExcess, PayslipEngine.PersonalAllowance(GrossPay), StrSubstNo('Expected the setup allowance of %1 reduced by half of the %2 of gross pay above the taper threshold of %3', Allowance, 2 * HalfExcess, TaperThreshold));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoIncomeTaxWhenPayWithinAllowance()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Gross pay below the personal allowance leaves nothing taxable
        SeedStandardPayroll();
        Assert.AreEqual(0.0, PayslipEngine.IncomeTax(10000.0), 'Expected zero income tax when gross pay is entirely covered by the personal allowance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncomeTaxAtTopOfFirstBand()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Taxable pay ending exactly at the second band's threshold is taxed at the first rate only
        SeedStandardPayroll();
        Assert.AreEqual(7540.0, PayslipEngine.IncomeTax(50270.0), 'Expected 37700 x 20% for gross pay of 50270 — taxable pay ends exactly at the 37700 threshold, so the 40% band never applies');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncomeTaxJustIntoSecondBand()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Two units into the second band add exactly 2 x 40% — the higher rate applies only to the slice above the threshold
        SeedStandardPayroll();
        Assert.AreEqual(7540.80, PayslipEngine.IncomeTax(50272.0), 'Expected 37700 x 20% + 2 x 40% for gross pay of 50272 — the 40% rate applies only to the slice above 37700, never to the whole taxable pay');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncomeTaxInTaperZoneUsesTaperedAllowance()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] In the taper zone taxable pay grows by the lost allowance: 110000 - 7570 = 102430 taxable
        SeedStandardPayroll();
        Assert.AreEqual(33432.0, PayslipEngine.IncomeTax(110000.0), 'Expected 37700 x 20% + 64730 x 40% for gross pay of 110000 — taxable pay must use the TAPERED allowance of 7570, not the full 12570');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncomeTaxWhenAllowanceFullyTapered()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Past the full-taper point the whole gross pay is taxable — a negative allowance would overtax
        SeedStandardPayroll();
        Assert.AreEqual(44703.0, PayslipEngine.IncomeTax(130000.0), 'Expected 37700 x 20% + 87440 x 40% + 4860 x 45% for gross pay of 130000 — the allowance is fully tapered to zero, not negative');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BandsFollowThresholdOrderNotLineNoOrder()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The same standard bands seeded with shuffled line numbers tax identically — Line No. carries no meaning
        // The shuffle inverts the relative order of the bands the amount engages: a walk in
        // Line No. order charges 9730 x 40% first and then 47430 x 20% for the "0" row = 13378
        ClearPayroll();
        SeedSetup(12570.0, 100000.0);
        SeedTaxBand(1, 37700.0, 40.0);
        SeedTaxBand(2, 125140.0, 45.0);
        SeedTaxBand(3, 0.0, 20.0);
        SeedNIBand(1, 12570.0, 8.0);
        SeedNIBand(2, 50270.0, 2.0);

        Assert.AreEqual(11432.0, PayslipEngine.IncomeTax(60000.0), 'Expected 37700 x 20% + 9730 x 40% for gross pay of 60000 even though the band rows were inserted with Line No. values out of threshold order — only the thresholds order the bands');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncomeTaxRoundsRawChargeToTheNearestCent()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A fractional rate makes the raw charge 7430 x 33.33% = 2476.419 — only nearest-cent rounding returns 2476.42
        ClearPayroll();
        SeedSetup(12570.0, 100000.0);
        SeedTaxBand(1, 0.0, 33.33);
        SeedTaxBand(2, 50000.0, 40.0);
        SeedNIBand(1, 12570.0, 8.0);
        SeedNIBand(2, 50270.0, 2.0);

        Assert.AreEqual(2476.42, PayslipEngine.IncomeTax(20000.0), 'Expected the taxable pay of 7430 x 33.33% = 2476.419 rounded to the nearest cent — the returned amount must be rounded to 2 decimal places, never truncated or left unrounded');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedTaxBandsMatchIndependentComputation()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Allowance: Integer;
        Threshold2: Integer;
        Threshold3: Integer;
        Rate1: Integer;
        Rate2: Integer;
        Rate3: Integer;
        GrossPay: Integer;
        TaxablePay: Integer;
        Expected: Decimal;
    begin
        // [SCENARIO] A fully generated three-band table taxes exactly what the slice arithmetic says — hardcoded rates or thresholds fail here
        Allowance := Any.IntegerInRange(8000, 15000);
        Threshold2 := Any.IntegerInRange(5000, 15000);
        Threshold3 := Threshold2 + Any.IntegerInRange(10000, 20000);
        Rate1 := Any.IntegerInRange(5, 25);
        Rate2 := Rate1 + Any.IntegerInRange(5, 20);
        Rate3 := Rate2 + Any.IntegerInRange(5, 15);
        GrossPay := Threshold3 + Allowance + Any.IntegerInRange(1000, 20000);

        ClearPayroll();
        SeedSetup(Allowance, 200000.0);
        SeedTaxBand(3, 0.0, Rate1);
        SeedTaxBand(1, Threshold2, Rate2);
        SeedTaxBand(2, Threshold3, Rate3);
        SeedNIBand(1, 12570.0, 8.0);
        SeedNIBand(2, 50270.0, 2.0);

        TaxablePay := GrossPay - Allowance;
        Expected := Threshold2 * Rate1 / 100 + (Threshold3 - Threshold2) * Rate2 / 100 + (TaxablePay - Threshold3) * Rate3 / 100;
        Assert.AreEqual(Expected, PayslipEngine.IncomeTax(GrossPay), StrSubstNo('Expected each generated band (thresholds 0/%1/%2, rates %3/%4/%5) to charge its rate only on its own slice of the taxable pay of %6', Threshold2, Threshold3, Rate1, Rate2, Rate3, TaxablePay));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoNIAtOrBelowFirstThreshold()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Gross pay exactly at the lowest NI threshold has no slice above it — nothing due
        SeedStandardPayroll();
        Assert.AreEqual(0.0, PayslipEngine.NIContribution(12570.0), 'Expected zero NI at gross pay exactly equal to the lowest NI threshold — pay at or below the lowest threshold is charged nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NIChargedOnGrossPayAboveThreshold()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] NI runs on gross pay with its own bands — the personal allowance plays no part
        SeedStandardPayroll();
        Assert.AreEqual(1394.40, PayslipEngine.NIContribution(30000.0), 'Expected (30000 - 12570) x 8% — NI is computed on gross pay against the NI band table, without any personal allowance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NIDropsToUpperRateAboveSecondThreshold()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Above the upper threshold the 2% band takes over for that slice only
        SeedStandardPayroll();
        Assert.AreEqual(3210.60, PayslipEngine.NIContribution(60000.0), 'Expected 37700 x 8% + 9730 x 2% for gross pay of 60000 — each NI band charges only its own slice');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedNIBandsMatchIndependentComputation()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Threshold1: Integer;
        Threshold2: Integer;
        Rate1: Integer;
        Rate2: Integer;
        GrossPay: Integer;
        Expected: Decimal;
    begin
        // [SCENARIO] Generated NI bands charge exactly per the slice arithmetic — hardcoded NI rates fail here
        Threshold1 := Any.IntegerInRange(8000, 15000);
        Rate1 := Any.IntegerInRange(5, 12);
        Threshold2 := Threshold1 + Any.IntegerInRange(30000, 45000);
        Rate2 := Any.IntegerInRange(1, 4);
        GrossPay := Threshold2 + Any.IntegerInRange(1000, 30000);

        ClearPayroll();
        SeedSetup(12570.0, 100000.0);
        SeedTaxBand(1, 0.0, 20.0);
        SeedTaxBand(2, 37700.0, 40.0);
        SeedNIBand(2, Threshold1, Rate1);
        SeedNIBand(1, Threshold2, Rate2);

        Expected := (Threshold2 - Threshold1) * Rate1 / 100 + (GrossPay - Threshold2) * Rate2 / 100;
        Assert.AreEqual(Expected, PayslipEngine.NIContribution(GrossPay), StrSubstNo('Expected the generated NI bands (thresholds %1/%2, rates %3/%4) to charge their rates on their own slices of the gross pay of %5', Threshold1, Threshold2, Rate1, Rate2, GrossPay));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NetPayCombinesTaxAndNI()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The worked example: gross 130000 minus tax 44703.00 minus NI 4610.60
        SeedStandardPayroll();
        Assert.AreEqual(80686.40, PayslipEngine.NetPay(130000.0), 'Expected gross pay of 130000 minus income tax of 44703.00 minus NI of 4610.60');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NetPayEqualsGrossWhenNothingIsDue()
    var
        PayslipEngine: Codeunit "Payslip Engine";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Below both the allowance and the lowest NI threshold nothing is withheld
        SeedStandardPayroll();
        Assert.AreEqual(10000.0, PayslipEngine.NetPay(10000.0), 'Expected net pay equal to gross pay when it is below both the personal allowance and the lowest NI threshold');
    end;

    local procedure ClearPayroll()
    var
        PayrollSetup: Record "Payslip Setup";
        IncomeTaxBand: Record "Income Tax Band";
        NIContributionBand: Record "NI Contribution Band";
    begin
        PayrollSetup.DeleteAll();
        IncomeTaxBand.DeleteAll();
        NIContributionBand.DeleteAll();
    end;

    local procedure SeedSetup(PersonalAllowance: Decimal; TaperThreshold: Decimal)
    var
        PayrollSetup: Record "Payslip Setup";
    begin
        PayrollSetup.Init();
        PayrollSetup."Personal Allowance" := PersonalAllowance;
        PayrollSetup."Taper Threshold" := TaperThreshold;
        PayrollSetup.Insert();
    end;

    local procedure SeedTaxBand(LineNo: Integer; Threshold: Decimal; RatePct: Decimal)
    var
        IncomeTaxBand: Record "Income Tax Band";
    begin
        IncomeTaxBand.Init();
        IncomeTaxBand."Line No." := LineNo;
        IncomeTaxBand.Threshold := Threshold;
        IncomeTaxBand."Rate %" := RatePct;
        IncomeTaxBand.Insert();
    end;

    local procedure SeedNIBand(LineNo: Integer; Threshold: Decimal; RatePct: Decimal)
    var
        NIContributionBand: Record "NI Contribution Band";
    begin
        NIContributionBand.Init();
        NIContributionBand."Line No." := LineNo;
        NIContributionBand.Threshold := Threshold;
        NIContributionBand."Rate %" := RatePct;
        NIContributionBand.Insert();
    end;

    local procedure SeedStandardBands()
    begin
        SeedTaxBand(1, 0.0, 20.0);
        SeedTaxBand(2, 37700.0, 40.0);
        SeedTaxBand(3, 125140.0, 45.0);
        SeedNIBand(1, 12570.0, 8.0);
        SeedNIBand(2, 50270.0, 2.0);
    end;

    local procedure SeedStandardPayroll()
    begin
        ClearPayroll();
        SeedSetup(12570.0, 100000.0);
        SeedStandardBands();
    end;
}
