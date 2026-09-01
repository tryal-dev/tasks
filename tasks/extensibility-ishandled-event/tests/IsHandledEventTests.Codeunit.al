codeunit 50900 "IsHandled Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DefaultFreightIsTenPercentRoundedToTheCent()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] With no subscriber bound, the default formula decides the charge
        Amount := Any.DecimalInRange(100, 900, 2);

        Assert.AreEqual(Round(Amount * 0.1, 0.01), Calculator.CalculateFreight(Amount),
            StrSubstNo('Expected the default charge — one tenth of %1, rounded to the cent — when no subscriber is bound', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SubscriberOverrideWinsWhenIsHandledIsSet()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        FreightEventMock: Codeunit "Freight Event Mock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Sentinel: Decimal;
    begin
        // [SCENARIO] A subscriber that sets IsHandled takes over the calculation entirely
        Sentinel := Any.DecimalInRange(200, 400, 2);
        FreightEventMock.ArrangeOverride(Sentinel);
        BindSubscription(FreightEventMock);

        Assert.AreEqual(Sentinel, Calculator.CalculateFreight(Any.DecimalInRange(100, 900, 2)),
            'Expected CalculateFreight to return exactly what the subscriber left in Freight after setting IsHandled — either OnBeforeCalculateFreight never fired, or the default formula still ran');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverrideToZeroFreightIsRespected()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        FreightEventMock: Codeunit "Freight Event Mock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] An override to exactly 0 is a valid handled result, not "nothing happened"
        FreightEventMock.ArrangeOverride(0);
        BindSubscription(FreightEventMock);

        Assert.AreEqual(0, Calculator.CalculateFreight(Any.DecimalInRange(100, 900, 2)),
            'Expected a handled Freight of exactly 0 to be returned as-is — checking the Freight value instead of IsHandled breaks the free-freight case');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritingFreightWithoutIsHandledDoesNotOverride()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        FreightEventMock: Codeunit "Freight Event Mock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] Only IsHandled decides — a written Freight alone must not stick
        FreightEventMock.ArrangeWriteWithoutHandling(777);
        BindSubscription(FreightEventMock);
        Amount := Any.DecimalInRange(100, 900, 2);

        Assert.AreEqual(Round(Amount * 0.1, 0.01), Calculator.CalculateFreight(Amount),
            'Expected the default charge when the subscriber wrote Freight but never set IsHandled — only IsHandled may hand the result over');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BoundPromotionGrantsFreeFreightAboveTheThreshold()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        FreeFreightPromotion: Codeunit "Free Freight Promotion";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] While bound, the promotion makes any large order ship for free
        BindSubscription(FreeFreightPromotion);
        Amount := Any.DecimalInRange(1001, 5000, 2);

        Assert.AreEqual(0, Calculator.CalculateFreight(Amount),
            StrSubstNo('Expected free freight for an amount of %1 while the promotion is bound', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BoundPromotionGrantsFreeFreightAtExactlyTheThreshold()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        FreeFreightPromotion: Codeunit "Free Freight Promotion";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The threshold is inclusive: exactly 1000 already ships for free
        BindSubscription(FreeFreightPromotion);

        Assert.AreEqual(0, Calculator.CalculateFreight(1000),
            'Expected free freight at exactly 1000 — the promotion applies to amounts of 1000 OR MORE');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BoundPromotionLeavesSmallOrdersToTheDefault()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        FreeFreightPromotion: Codeunit "Free Freight Promotion";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] Below the threshold the bound promotion stays out of the way
        BindSubscription(FreeFreightPromotion);
        Amount := Any.DecimalInRange(100, 999, 2);

        Assert.AreEqual(Round(Amount * 0.1, 0.01), Calculator.CalculateFreight(Amount),
            StrSubstNo('Expected the default charge for an amount of %1 — below 1000 the promotion must leave the event untouched', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BoundPromotionChargesDefaultJustBelowTheThreshold()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        FreeFreightPromotion: Codeunit "Free Freight Promotion";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The boundary is exactly 1000: one cent less still pays the default charge
        BindSubscription(FreeFreightPromotion);

        Assert.AreEqual(100.00, Calculator.CalculateFreight(999.99),
            'Expected the default charge for 999.99 — the promotion starts at 1000, so one cent below it the event must stay untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnboundPromotionNeverFires()
    var
        Calculator: Codeunit "Freight Charge Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] Nothing bound the promotion, so even a huge order pays the default
        Amount := Any.DecimalInRange(1000, 5000, 2);

        Assert.AreEqual(Round(Amount * 0.1, 0.01), Calculator.CalculateFreight(Amount),
            StrSubstNo('Expected the default charge for %1 while the promotion is NOT bound — it must participate only during an explicit BindSubscription', Amount));
    end;
}
