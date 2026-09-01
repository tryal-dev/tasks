codeunit 50900 "Rate At Date Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FindsTheRateStartingExactlyOnTheLookupDate()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NewRate: Decimal;
        RatePct: Decimal;
    begin
        // [SCENARIO] On the very day a new rate starts, the new rate applies — not the previous one
        NewRate := Any.DecimalInRange(1, 25, 2);
        SeedRate('TRYAL-R1', DMY2Date(1, 1, 2023), NewRate + 10);
        SeedRate('TRYAL-R1', DMY2Date(1, 3, 2023), NewRate);

        Assert.IsTrue(CommissionRateFinder.FindRateAt('TRYAL-R1', DMY2Date(1, 3, 2023), RatePct),
            'Expected FindRateAt to find a rate on the exact day that rate starts');
        Assert.AreEqual(NewRate, RatePct,
            'Expected the rate starting on the lookup date itself to apply, not the earlier one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FindsTheLatestRateStartedBeforeTheLookupDate()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LatestRate: Decimal;
        RatePct: Decimal;
    begin
        // [SCENARIO] A date between starting dates gets the latest rate already in force
        LatestRate := Any.DecimalInRange(1, 25, 2);
        SeedRate('TRYAL-R2', DMY2Date(1, 1, 2023), LatestRate + 10);
        SeedRate('TRYAL-R2', DMY2Date(1, 2, 2023), LatestRate + 20);
        SeedRate('TRYAL-R2', DMY2Date(1, 3, 2023), LatestRate);

        Assert.IsTrue(CommissionRateFinder.FindRateAt('TRYAL-R2', DMY2Date(20, 3, 2023), RatePct),
            'Expected FindRateAt to find a rate on a date after the rate''s starting date — a rate stays in force until a newer one takes over');
        Assert.AreEqual(LatestRate, RatePct,
            'Expected the rate with the latest starting date on or before the lookup date to win, not an earlier one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnoresARateStartingAfterTheLookupDate()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrentRate: Decimal;
        RatePct: Decimal;
    begin
        // [SCENARIO] A rate scheduled for the future does not apply yet
        CurrentRate := Any.DecimalInRange(1, 25, 2);
        SeedRate('TRYAL-R3', DMY2Date(1, 3, 2023), CurrentRate);
        SeedRate('TRYAL-R3', DMY2Date(1, 6, 2023), CurrentRate + 10);

        CommissionRateFinder.FindRateAt('TRYAL-R3', DMY2Date(15, 4, 2023), RatePct);

        Assert.AreEqual(CurrentRate, RatePct,
            'Expected the rate in force on the lookup date — a rate starting after that date must not apply yet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FindsNoRateTheDayBeforeTheFirstRateStarts()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
        Found: Boolean;
        RatePct: Decimal;
    begin
        // [SCENARIO] One day before the earliest starting date, no rate applies and the dirty var comes back as 0
        SeedRate('TRYAL-R4', DMY2Date(1, 3, 2023), 7.5);

        RatePct := 87.5;
        Found := CommissionRateFinder.FindRateAt('TRYAL-R4', DMY2Date(28, 2, 2023), RatePct);

        Assert.IsFalse(Found,
            StrSubstNo('Expected FindRateAt to return false the day before the first rate starts, got true with RatePct %1', RatePct));
        Assert.AreEqual(0, RatePct,
            'Expected RatePct to be set to 0 when no rate applies, whatever value the caller passed in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FindsNoRateWhenTheSalespersonHasNoRates()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
        Found: Boolean;
        RatePct: Decimal;
    begin
        // [SCENARIO] A salesperson without rate rows gets no rate, even though another salesperson has one
        SeedRate('TRYAL-R5Z', DMY2Date(1, 1, 2023), 9.5);

        RatePct := 55.5;
        Found := CommissionRateFinder.FindRateAt('TRYAL-R5A', DMY2Date(1, 4, 2023), RatePct);

        Assert.IsFalse(Found,
            StrSubstNo('Expected FindRateAt to return false for a salesperson with no rate rows — another salesperson''s rates must not apply; got true with RatePct %1', RatePct));
        Assert.AreEqual(0, RatePct,
            'Expected RatePct to be set to 0 when the salesperson has no rate rows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoesNotBorrowTheRateOfAnotherSalesperson()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OwnRate: Decimal;
        RatePct: Decimal;
    begin
        // [SCENARIO] Another salesperson's newer rate never wins over the queried salesperson's own rate
        OwnRate := Any.DecimalInRange(1, 25, 2);
        SeedRate('TRYAL-R6A', DMY2Date(1, 3, 2023), OwnRate);
        SeedRate('TRYAL-R6Z', DMY2Date(1, 4, 2023), OwnRate + 10);

        CommissionRateFinder.FindRateAt('TRYAL-R6A', DMY2Date(10, 4, 2023), RatePct);

        Assert.AreEqual(OwnRate, RatePct,
            'Expected the queried salesperson''s own rate — another salesperson''s rate row must never influence the result');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TreatsAZeroRateAsFound()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
        Found: Boolean;
        RatePct: Decimal;
    begin
        // [SCENARIO] A 0% rate row is a real rate: found = true, and it beats the earlier non-zero rate
        SeedRate('TRYAL-R7', DMY2Date(1, 1, 2023), 5.0);
        SeedRate('TRYAL-R7', DMY2Date(1, 3, 2023), 0);

        Found := CommissionRateFinder.FindRateAt('TRYAL-R7', DMY2Date(15, 3, 2023), RatePct);

        Assert.IsTrue(Found,
            'Expected FindRateAt to return true for an applying 0% rate — "found a 0% rate" and "found no rate" are different answers');
        Assert.AreEqual(0, RatePct,
            'Expected the 0% rate starting on March 1 to win over the earlier 5% rate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetRateAtReturnsTheApplicableRate()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ApplicableRate: Decimal;
    begin
        // [SCENARIO] GetRateAt returns the rate in force between two starting dates
        ApplicableRate := Any.DecimalInRange(1, 25, 2);
        SeedRate('TRYAL-R8', DMY2Date(1, 1, 2023), ApplicableRate + 10);
        SeedRate('TRYAL-R8', DMY2Date(1, 3, 2023), ApplicableRate);
        SeedRate('TRYAL-R8', DMY2Date(1, 6, 2023), ApplicableRate + 20);

        Assert.AreEqual(ApplicableRate, CommissionRateFinder.GetRateAt('TRYAL-R8', DMY2Date(15, 4, 2023)),
            'Expected GetRateAt to return the rate with the latest starting date on or before the lookup date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetRateAtReturnsZeroWhenNoRateApplies()
    var
        CommissionRateFinder: Codeunit "Commission Rate Finder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] GetRateAt returns 0 when every rate row starts after the lookup date
        SeedRate('TRYAL-R9', DMY2Date(1, 6, 2023), 8.25);

        Assert.AreEqual(0, CommissionRateFinder.GetRateAt('TRYAL-R9', DMY2Date(1, 4, 2023)),
            'Expected GetRateAt to return 0 when no rate row starts on or before the lookup date');
    end;

    local procedure SeedRate(SalespersonCode: Code[20]; StartingDate: Date; RatePct: Decimal)
    var
        CommissionRate: Record "Commission Rate";
    begin
        CommissionRate.Init();
        CommissionRate."Salesperson Code" := SalespersonCode;
        CommissionRate."Starting Date" := StartingDate;
        CommissionRate."Rate %" := RatePct;
        CommissionRate.Insert(true);
    end;
}
