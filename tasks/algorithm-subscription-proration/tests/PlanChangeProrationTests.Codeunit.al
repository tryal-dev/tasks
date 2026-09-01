codeunit 50900 "Plan Change Proration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangeOnPeriodStartCreditsAndChargesTheFullPrices()
    var
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
    begin
        // [SCENARIO] A change effective on the first period day leaves no old-plan days at all
        Prorate(20260101D, 20260131D, 20260101D, 19.99, 34.99, CreditAmount, ChargeAmount);

        AssertAmounts(19.99, 34.99, CreditAmount, ChargeAmount,
            'when the change is effective on the period start, every day is unused old plan and every day is billable new plan');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MidMonthUpgradeProratesByActualPeriodDays()
    var
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
    begin
        // [SCENARIO] January 1-31, change on January 16: 16 remaining days of 31
        Prorate(20260101D, 20260131D, 20260116D, 20.00, 46.50, CreditAmount, ChargeAmount);

        AssertAmounts(10.32, 24.00, CreditAmount, ChargeAmount,
            'a January period has 31 days and the change day through January 31 is 16 remaining days — a 30-day convention or an off-by-one day count lands elsewhere');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FebruaryDowngradeUsesTwentyEightPeriodDays()
    var
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
    begin
        // [SCENARIO] February 1-28, 2026 (no leap), downgrade on February 12: 17 remaining days of 28
        Prorate(20260201D, 20260228D, 20260212D, 57.40, 28.00, CreditAmount, ChargeAmount);

        AssertAmounts(34.85, 17.00, CreditAmount, ChargeAmount,
            'February 2026 has exactly 28 days — dividing by 30 misprices every remaining day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeapYearFebruaryUsesTwentyNinePeriodDays()
    var
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
    begin
        // [SCENARIO] February 1-29, 2028 (leap year), upgrade on February 15: 15 remaining days of 29
        Prorate(20280201D, 20280229D, 20280215D, 29.00, 87.00, CreditAmount, ChargeAmount);

        AssertAmounts(15.00, 45.00, CreditAmount, ChargeAmount,
            'February 2028 has 29 days — both a 28-day and a 30-day assumption misprice the period');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CancellationChargesExactlyZeroForTheRemainingDays()
    var
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
    begin
        // [SCENARIO] April 1-30, cancel effective April 21: credit 10 of 30 days, bill nothing new
        Prorate(20260401D, 20260430D, 20260421D, 25.99, 0, CreditAmount, ChargeAmount);

        AssertAmounts(8.66, 0.00, CreditAmount, ChargeAmount,
            'a cancellation credits the unused days at the old price and charges exactly 0.00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangeOnTheLastPeriodDayProratesExactlyOneDay()
    var
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
    begin
        // [SCENARIO] January 1-31, change on January 31: the change day itself is still a billable new-plan day
        Prorate(20260101D, 20260131D, 20260131D, 31.00, 15.50, CreditAmount, ChargeAmount);

        AssertAmounts(1.00, 0.50, CreditAmount, ChargeAmount,
            'a change on the last period day leaves exactly one remaining day — a day count of zero here is the classic off-by-one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HalfCentSharesRoundUpAwayFromZero()
    var
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
    begin
        // [SCENARIO] 8-day period, 3 remaining days: 0.28*3/8 = 0.105 and 21.00*3/8 = 7.875,
        // both exactly half a cent — nearest-cent with ties away from zero gives 0.11 and 7.88
        Prorate(20260501D, 20260508D, 20260506D, 0.28, 21.00, CreditAmount, ChargeAmount);

        AssertAmounts(0.11, 7.88, CreditAmount, ChargeAmount,
            'an exact half-cent share rounds up (away from zero) — truncation and banker''s rounding both land a cent short on the credit');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SamePriceSwitchReconcilesToNetZero()
    var
        Any: Codeunit Any;
        PeriodStart: Date;
        ChangeDate: Date;
        PeriodLength: Integer;
        Price: Decimal;
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
    begin
        // [SCENARIO] A randomized plan change that keeps the price must credit and charge the same amount
        PeriodStart := Any.DateInRange(365);
        PeriodLength := Any.IntegerInRange(7, 92);
        ChangeDate := PeriodStart + Any.IntegerInRange(0, PeriodLength - 1);
        Price := Any.DecimalInRange(1, 500, 2);

        Prorate(PeriodStart, PeriodStart + PeriodLength - 1, ChangeDate, Price, Price, CreditAmount, ChargeAmount);

        Assert.AreEqual(CreditAmount, ChargeAmount,
            StrSubstNo('Expected a switch that keeps the price %1 to net to exactly zero — credit and charge must cover the same remaining days with the same rounding (period %2..%3, change on %4)',
                Price, PeriodStart, PeriodStart + PeriodLength - 1, ChangeDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomPlanChangeMatchesIndependentProration()
    var
        Any: Codeunit Any;
        PeriodStart: Date;
        PeriodEnd: Date;
        ChangeDate: Date;
        PeriodLength: Integer;
        OldPrice: Decimal;
        NewPrice: Decimal;
        CreditAmount: Decimal;
        ChargeAmount: Decimal;
        RemainingDays: Integer;
    begin
        // [SCENARIO] A fully randomized upgrade is checked against proration computed independently in the test
        PeriodStart := Any.DateInRange(365);
        PeriodLength := Any.IntegerInRange(7, 92);
        PeriodEnd := PeriodStart + PeriodLength - 1;
        ChangeDate := PeriodStart + Any.IntegerInRange(0, PeriodLength - 1);
        OldPrice := Any.DecimalInRange(1, 500, 2);
        NewPrice := Any.DecimalInRange(1, 500, 2);
        RemainingDays := PeriodEnd - ChangeDate + 1;

        Prorate(PeriodStart, PeriodEnd, ChangeDate, OldPrice, NewPrice, CreditAmount, ChargeAmount);

        AssertAmounts(
            Round(OldPrice * RemainingDays / PeriodLength, 0.01),
            Round(NewPrice * RemainingDays / PeriodLength, 0.01),
            CreditAmount, ChargeAmount,
            StrSubstNo('for a period %1..%2 with the change on %3, %4 of %5 period days remain on the new plan', PeriodStart, PeriodEnd, ChangeDate, RemainingDays, PeriodLength));
    end;

    local procedure Prorate(PeriodStart: Date; PeriodEnd: Date; ChangeDate: Date; OldPrice: Decimal; NewPrice: Decimal; var CreditAmount: Decimal; var ChargeAmount: Decimal)
    var
        PlanChangeProrator: Codeunit "Plan Change Prorator";
    begin
        // Garbage sentinels: an implementation that forgets to assign an output
        // (or adds to it instead of setting it) must fail visibly.
        CreditAmount := -987654.32;
        ChargeAmount := -987654.32;
        PlanChangeProrator.ProrateChange(PeriodStart, PeriodEnd, ChangeDate, OldPrice, NewPrice, CreditAmount, ChargeAmount);
    end;

    local procedure AssertAmounts(ExpectedCredit: Decimal; ExpectedCharge: Decimal; ActualCredit: Decimal; ActualCharge: Decimal; Context: Text)
    begin
        Assert.AreEqual(ExpectedCredit, ActualCredit, StrSubstNo('Expected CreditAmount to be the remaining days at the old price, penny-exact: %1', Context));
        Assert.AreEqual(ExpectedCharge, ActualCharge, StrSubstNo('Expected ChargeAmount to be the remaining days at the new price, penny-exact: %1', Context));
    end;
}
