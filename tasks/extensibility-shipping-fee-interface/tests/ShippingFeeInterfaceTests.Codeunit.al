codeunit 50900 "Shipping Fee Interface Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlatRateChargesTheSameFeeForAnyParcel()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
    begin
        Calculator := "Shipping Fee Method"::"Flat Rate";

        Assert.AreEqual(9.9, Calculator.CalculateFee(Any.DecimalInRange(1, 100, 2), Any.DecimalInRange(1, 5000, 2)),
            'Expected the Flat Rate calculator to charge exactly 9.90 whatever the weight and the order amount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ByWeightChargesTheWeightTimesTheRate()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
        WeightKg: Decimal;
    begin
        WeightKg := Any.DecimalInRange(4, 50, 2);
        Calculator := "Shipping Fee Method"::"By Weight";

        Assert.AreEqual(Round(WeightKg * 1.6, 0.01), Calculator.CalculateFee(WeightKg, Any.DecimalInRange(1, 5000, 2)),
            StrSubstNo('Expected the By Weight fee for a %1 kg parcel to be the weight times 1.60, rounded to the nearest cent — the order amount plays no part', WeightKg));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ByWeightRoundsTheFeeToTheNearestCent()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
    begin
        Calculator := "Shipping Fee Method"::"By Weight";

        Assert.AreEqual(6.45, Calculator.CalculateFee(4.03, Any.DecimalInRange(1, 5000, 2)),
            'Expected a 4.03 kg parcel to cost 6.45 — 4.03 times 1.60 is 6.448, which must be rounded to the nearest cent');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ByWeightRoundsTheFeeDownWhenTheNearestCentIsBelow()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
    begin
        Calculator := "Shipping Fee Method"::"By Weight";

        Assert.AreEqual(6.43, Calculator.CalculateFee(4.02, Any.DecimalInRange(1, 5000, 2)),
            'Expected a 4.02 kg parcel to cost 6.43 — 4.02 times 1.60 is 6.432, which must round down to 6.43, not up');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ByWeightChargesTheMinimumForLightParcels()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
        WeightKg: Decimal;
    begin
        WeightKg := Any.DecimalInRange(3, 2);
        Calculator := "Shipping Fee Method"::"By Weight";

        Assert.AreEqual(5.0, Calculator.CalculateFee(WeightKg, Any.DecimalInRange(1, 5000, 2)),
            StrSubstNo('Expected a %1 kg parcel to be charged exactly the 5.00 minimum — its computed fee is below it', WeightKg));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ByWeightChargesExactlyTheMinimumAtTheBoundaryWeight()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
    begin
        Calculator := "Shipping Fee Method"::"By Weight";

        Assert.AreEqual(5.0, Calculator.CalculateFee(3.125, Any.DecimalInRange(1, 5000, 2)),
            'Expected a 3.125 kg parcel to cost exactly 5.00 — its computed fee (3.125 times 1.60) lands exactly on the minimum');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FreeOverThresholdShipsFreeAtExactlyTheThreshold()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
    begin
        Calculator := "Shipping Fee Method"::"Free Over Threshold";

        Assert.AreEqual(0, Calculator.CalculateFee(Any.DecimalInRange(1, 100, 2), 100.0),
            'Expected an order of exactly 100.00 to ship free — the threshold amount itself qualifies');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FreeOverThresholdShipsFreeAboveTheThreshold()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
        Amount: Decimal;
    begin
        Amount := Any.DecimalInRange(101, 5000, 2);
        Calculator := "Shipping Fee Method"::"Free Over Threshold";

        Assert.AreEqual(0, Calculator.CalculateFee(Any.DecimalInRange(1, 100, 2), Amount),
            StrSubstNo('Expected an order of %1 to ship free — it is above the 100.00 threshold, whatever the parcel weighs', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FreeOverThresholdChargesTheFlatFeeJustBelowTheThreshold()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Calculator: Interface "Shipping Fee Calculator";
    begin
        Calculator := "Shipping Fee Method"::"Free Over Threshold";

        Assert.AreEqual(7.5, Calculator.CalculateFee(Any.DecimalInRange(1, 100, 2), 99.99),
            'Expected an order of 99.99 to pay the flat 7.50 fee — free shipping starts only at 100.00');
    end;
}
