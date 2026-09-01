codeunit 50900 "City Credit Aggregator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalSumsEveryCustomerInTheCity()
    var
        Aggregator: Codeunit "City Credit Aggregator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstLimit: Decimal;
        SecondLimit: Decimal;
        ThirdLimit: Decimal;
    begin
        FirstLimit := Any.DecimalInRange(100, 199, 2);
        SecondLimit := Any.DecimalInRange(200, 299, 2);
        ThirdLimit := Any.DecimalInRange(300, 399, 2);
        CreateCustomerInCityWithLimit('TRYAL-A1 Silverport', FirstLimit);
        CreateCustomerInCityWithLimit('TRYAL-A1 Silverport', SecondLimit);
        CreateCustomerInCityWithLimit('TRYAL-A1 Silverport', ThirdLimit);
        CreateCustomerInCityWithLimit('TRYAL-A1 Ironvale', Any.DecimalInRange(500, 599, 2));

        Assert.AreEqual(FirstLimit + SecondLimit + ThirdLimit, Aggregator.TotalCreditLimit('TRYAL-A1 Silverport'),
            'Expected the sum of all three credit limits in TRYAL-A1 Silverport — a loop that loses the first record or keeps only the last amount comes up short, and the TRYAL-A1 Ironvale customer must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalOfAOneCustomerCityIsThatCustomersLimit()
    var
        Aggregator: Codeunit "City Credit Aggregator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OnlyLimit: Decimal;
    begin
        OnlyLimit := Any.DecimalInRange(100, 999, 2);
        CreateCustomerInCityWithLimit('TRYAL-A2 Duskvale', OnlyLimit);

        Assert.AreEqual(OnlyLimit, Aggregator.TotalCreditLimit('TRYAL-A2 Duskvale'),
            'Expected the single customer''s credit limit — a loop that steps to the next record before reading the one it found returns 0 for a one-customer city');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalIsZeroForACityWithNoCustomers()
    var
        Aggregator: Codeunit "City Credit Aggregator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        CreateCustomerInCityWithLimit('TRYAL-A3 Emberly', Any.DecimalInRange(100, 999, 2));

        Assert.AreEqual(0.0, Aggregator.TotalCreditLimit('TRYAL-A3 Frostmoor'),
            'Expected 0 for a city no customer lives in — an empty set is a zero total, not a runtime error and not the sum of other cities');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalDoesNotMatchACityThatMerelyStartsTheSameWay()
    var
        Aggregator: Codeunit "City Credit Aggregator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NorthLimit: Decimal;
    begin
        NorthLimit := Any.DecimalInRange(100, 499, 2);
        CreateCustomerInCityWithLimit('TRYAL-A4 North', NorthLimit);
        CreateCustomerInCityWithLimit('TRYAL-A4 Northport', Any.DecimalInRange(500, 900, 2));

        Assert.AreEqual(NorthLimit, Aggregator.TotalCreditLimit('TRYAL-A4 North'),
            'Expected only the customer whose City is exactly TRYAL-A4 North — TRYAL-A4 Northport merely starts the same way and must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CappedTotalCountsAboveCapCustomersAtTheCap()
    var
        Aggregator: Codeunit "City Credit Aggregator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Cap: Decimal;
        BelowLimit: Decimal;
    begin
        Cap := Any.DecimalInRange(1000, 1500, 2);
        BelowLimit := Any.DecimalInRange(100, 900, 2);
        CreateCustomerInCityWithLimit('TRYAL-A5 Havenbrook', BelowLimit);
        CreateCustomerInCityWithLimit('TRYAL-A5 Havenbrook', Cap);
        CreateCustomerInCityWithLimit('TRYAL-A5 Havenbrook', Any.DecimalInRange(2000, 3000, 2));
        CreateCustomerInCityWithLimit('TRYAL-A5 Isleworth', Any.DecimalInRange(2000, 3000, 2));

        Assert.AreEqual(BelowLimit + Cap + Cap, Aggregator.TotalCreditLimitCapped('TRYAL-A5 Havenbrook', Cap),
            'Expected the below-cap customer at their own limit plus the at-cap and above-cap customers at the cap — dropping the above-cap customer, forgetting the cap, or counting the TRYAL-A5 Isleworth decoy all give a different total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CappedTotalKeepsLimitsAtOrBelowTheCapUnchanged()
    var
        Aggregator: Codeunit "City Credit Aggregator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Cap: Decimal;
        FirstLimit: Decimal;
        SecondLimit: Decimal;
    begin
        Cap := Any.DecimalInRange(1000, 2000, 2);
        FirstLimit := Any.DecimalInRange(100, 900, 2);
        SecondLimit := Any.DecimalInRange(100, 900, 2);
        CreateCustomerInCityWithLimit('TRYAL-A6 Larkspur', FirstLimit);
        CreateCustomerInCityWithLimit('TRYAL-A6 Larkspur', SecondLimit);

        Assert.AreEqual(FirstLimit + SecondLimit, Aggregator.TotalCreditLimitCapped('TRYAL-A6 Larkspur', Cap),
            'Expected the plain sum of the two limits — both are below the cap, so neither may be changed; a capped total that counts every customer at the cap is wrong');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CappedTotalIsZeroForACityWithNoCustomers()
    var
        Aggregator: Codeunit "City Credit Aggregator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        CreateCustomerInCityWithLimit('TRYAL-A7 Junction', Any.DecimalInRange(2000, 3000, 2));

        Assert.AreEqual(0.0, Aggregator.TotalCreditLimitCapped('TRYAL-A7 Nowhere', Any.DecimalInRange(1000, 2000, 2)),
            'Expected 0 from the capped total for a city no customer lives in — an empty set is a zero total, not a runtime error');
    end;

    local procedure CreateCustomerInCityWithLimit(CityName: Text[30]; CreditLimit: Decimal)
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.City := CityName;
        Customer."Credit Limit (LCY)" := CreditLimit;
        Customer.Modify(true);
    end;
}
