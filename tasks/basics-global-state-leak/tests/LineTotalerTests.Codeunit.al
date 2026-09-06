codeunit 50900 "Line Totaler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalReturnsTheSumOfTheAmounts()
    var
        LineTotaler: Codeunit "Line Totaler";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amounts: List of [Decimal];
    begin
        // [SCENARIO] One call on a fresh instance sums every amount in the list
        AddGeneratedAmounts(Any, Amounts, 6);

        Assert.AreEqual(SumOf(Amounts), LineTotaler.Total(Amounts),
            'Expected Total to return the sum of every amount in the list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalOfAnEmptyListIsZero()
    var
        LineTotaler: Codeunit "Line Totaler";
        Assert: Codeunit Assert;
        Amounts: List of [Decimal];
    begin
        // [SCENARIO] An empty list totals 0 without raising an error
        Assert.AreEqual(0.0, LineTotaler.Total(Amounts),
            'Expected an empty list to total 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeAmountsReduceTheTotal()
    var
        LineTotaler: Codeunit "Line Totaler";
        Assert: Codeunit Assert;
        Amounts: List of [Decimal];
    begin
        // [SCENARIO] A credit line's negative amount is subtracted, neither skipped nor flipped
        Amounts.Add(120.00);
        Amounts.Add(-45.25);
        Amounts.Add(10.10);

        Assert.AreEqual(84.85, LineTotaler.Total(Amounts),
            'Expected 120 + (-45.25) + 10.10 to total exactly 84.85 — a negative amount reduces the total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalingTheSameListTwiceReturnsTheSameSum()
    var
        LineTotaler: Codeunit "Line Totaler";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amounts: List of [Decimal];
    begin
        // [SCENARIO] A second call on the same instance returns the list's sum, not twice the sum
        // [GIVEN] one Line Totaler instance that has already totaled the list once
        AddGeneratedAmounts(Any, Amounts, 4);
        LineTotaler.Total(Amounts);

        // [WHEN] the same list is totaled again on that instance
        // [THEN] the result is the list's sum — nothing from the first call is included
        Assert.AreEqual(SumOf(Amounts), LineTotaler.Total(Amounts),
            'Expected the second Total of the same list on the same instance to equal the list''s sum — the first call''s total must not be carried into the second');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondListOnTheSameInstanceReturnsOnlyItsOwnSum()
    var
        LineTotaler: Codeunit "Line Totaler";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstAmounts: List of [Decimal];
        SecondAmounts: List of [Decimal];
    begin
        // [SCENARIO] Each call totals exactly the list it is given, whatever the instance totaled before
        // [GIVEN] one Line Totaler instance that has already totaled a first list
        AddGeneratedAmounts(Any, FirstAmounts, 5);
        AddGeneratedAmounts(Any, SecondAmounts, 2);
        LineTotaler.Total(FirstAmounts);

        // [WHEN] a second, different list is totaled on that instance
        // [THEN] the result is the second list's sum alone
        Assert.AreEqual(SumOf(SecondAmounts), LineTotaler.Total(SecondAmounts),
            'Expected a second call on the same instance to return only the second list''s sum — the first list''s total must not leak into it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyListAfterAnEarlierCallStillTotalsZero()
    var
        LineTotaler: Codeunit "Line Totaler";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FilledAmounts: List of [Decimal];
        EmptyAmounts: List of [Decimal];
    begin
        // [SCENARIO] An empty list totals 0 even on an instance that has totaled other amounts
        // [GIVEN] one Line Totaler instance that has already totaled a non-empty list
        AddGeneratedAmounts(Any, FilledAmounts, 3);
        LineTotaler.Total(FilledAmounts);

        // [WHEN] an empty list is totaled on that instance
        // [THEN] the result is 0
        Assert.AreEqual(0.0, LineTotaler.Total(EmptyAmounts),
            'Expected an empty list to total 0 even after the same instance totaled other amounts — nothing from the earlier call may remain');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalLeavesTheGivenListUntouched()
    var
        LineTotaler: Codeunit "Line Totaler";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amounts: List of [Decimal];
        AmountsBefore: Text;
    begin
        // [SCENARIO] The caller's list still holds the same amounts in the same order after Total
        AddGeneratedAmounts(Any, Amounts, 4);
        AmountsBefore := JoinAmounts(Amounts);

        LineTotaler.Total(Amounts);

        Assert.AreEqual(AmountsBefore, JoinAmounts(Amounts),
            'Expected the caller''s list to hold the same amounts in the same order after Total — a List is a reference type, so the procedure must read it, not consume it');
    end;

    // One Any instance per test drives every generated amount of that test,
    // so two lists built in the same test never come out identical.
    local procedure AddGeneratedAmounts(var Any: Codeunit Any; var Amounts: List of [Decimal]; HowMany: Integer)
    var
        i: Integer;
    begin
        for i := 1 to HowMany do
            Amounts.Add(Any.DecimalInRange(1, 500, 2));
    end;

    local procedure SumOf(Amounts: List of [Decimal]) Sum: Decimal
    var
        Amount: Decimal;
    begin
        foreach Amount in Amounts do
            Sum += Amount;
    end;

    local procedure JoinAmounts(Amounts: List of [Decimal]) Joined: Text
    var
        Amount: Decimal;
    begin
        foreach Amount in Amounts do
            Joined += Format(Amount, 0, 9) + ',';
    end;
}
