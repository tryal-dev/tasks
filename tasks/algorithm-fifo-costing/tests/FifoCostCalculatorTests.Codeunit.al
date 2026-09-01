codeunit 50900 "FIFO Cost Calculator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleShipmentCostsAtItsOnlyLayer()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] One receipt, one shipment drawing part of it
        AddEntry(Quantities, UnitCosts, 10, 2.50);
        AddEntry(Quantities, UnitCosts, -4, 0);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(1, Costs.Count(), 'Expected exactly one cost for a ledger with one shipment');
        Assert.AreEqual(10.00, Costs.Get(1), 'Expected 4 units shipped from a 10-unit layer at 2.50 to cost 4 x 2.50');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShipmentSpansLayersOldestFirst()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] A shipment larger than the oldest layer takes the rest from the next layer
        AddEntry(Quantities, UnitCosts, 5, 1.00);
        AddEntry(Quantities, UnitCosts, 5, 2.00);
        AddEntry(Quantities, UnitCosts, -8, 0);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(1, Costs.Count(), 'Expected exactly one cost for a ledger with one shipment');
        Assert.AreEqual(11.00, Costs.Get(1), 'Expected 8 units to cost 5 x 1.00 from the oldest layer plus 3 x 2.00 from the next — the oldest units ship first (newest-first gives 13.00, average cost gives 12.00)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PartiallyConsumedLayerServesTheNextShipment()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] The second shipment continues in the layer the first one only partly consumed
        AddEntry(Quantities, UnitCosts, 10, 3.00);
        AddEntry(Quantities, UnitCosts, 10, 4.00);
        AddEntry(Quantities, UnitCosts, -4, 0);
        AddEntry(Quantities, UnitCosts, -9, 0);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(2, Costs.Count(), 'Expected one cost per shipment, in chronological order');
        Assert.AreEqual(12.00, Costs.Get(1), 'Expected the first shipment of 4 to cost 4 x 3.00 from the oldest layer');
        Assert.AreEqual(30.00, Costs.Get(2), 'Expected the second shipment of 9 to cost 6 x 3.00 (what the oldest layer still held) plus 3 x 4.00 — a layer partially consumed by one shipment keeps only its remainder for the next');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExhaustedLayerHandsOverAtTheExactBoundary()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] A shipment that empties a layer exactly; the next shipment starts on the next layer
        AddEntry(Quantities, UnitCosts, 6, 2.00);
        AddEntry(Quantities, UnitCosts, 3, 7.00);
        AddEntry(Quantities, UnitCosts, -6, 0);
        AddEntry(Quantities, UnitCosts, -2, 0);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(2, Costs.Count(), 'Expected one cost per shipment, in chronological order');
        Assert.AreEqual(12.00, Costs.Get(1), 'Expected the first shipment to cost 6 x 2.00, emptying the oldest layer exactly');
        Assert.AreEqual(14.00, Costs.Get(2), 'Expected the second shipment to cost 2 x 7.00 — the 6-unit layer is empty and must not contribute anything');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReceiptAfterShipmentJoinsTheBackOfTheQueue()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] A receipt between two shipments becomes the newest layer, not the cheapest or the oldest
        AddEntry(Quantities, UnitCosts, 4, 1.00);
        AddEntry(Quantities, UnitCosts, -3, 0);
        AddEntry(Quantities, UnitCosts, 4, 10.00);
        AddEntry(Quantities, UnitCosts, -4, 0);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(2, Costs.Count(), 'Expected one cost per shipment, in chronological order');
        Assert.AreEqual(3.00, Costs.Get(1), 'Expected the first shipment to cost 3 x 1.00 from the only layer on hand');
        Assert.AreEqual(31.00, Costs.Get(2), 'Expected the second shipment to cost 1 x 1.00 (the old layer''s last unit) plus 3 x 10.00 from the newer layer — averaging everything received gives 22.00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShippingExactlyTheOnHandQuantitySucceeds()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] A shipment that consumes everything on hand drains inventory to
        // exactly zero and must succeed; a restock afterwards starts a fresh queue
        AddEntry(Quantities, UnitCosts, 5, 1.00);
        AddEntry(Quantities, UnitCosts, 3, 2.00);
        AddEntry(Quantities, UnitCosts, -8, 0);
        AddEntry(Quantities, UnitCosts, 4, 3.00);
        AddEntry(Quantities, UnitCosts, -2, 0);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(2, Costs.Count(), 'Expected one cost per shipment, in chronological order — shipping exactly what is on hand is not an over-shipment and must not raise an error');
        Assert.AreEqual(11.00, Costs.Get(1), 'Expected the shipment of exactly the 8 units on hand to cost 5 x 1.00 + 3 x 2.00, draining inventory to zero without an error');
        Assert.AreEqual(6.00, Costs.Get(2), 'Expected the shipment after the restock to cost 2 x 3.00 from the new layer alone — the emptied layers must contribute nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OvershippingReportsInsufficientInventory()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
    begin
        // [SCENARIO] The second shipment asks for 3 when only 2 remain
        AddEntry(Quantities, UnitCosts, 5, 1.00);
        AddEntry(Quantities, UnitCosts, -3, 0);
        AddEntry(Quantities, UnitCosts, -3, 0);

        asserterror Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.ExpectedError('Insufficient inventory');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LaterReceiptCannotFundAnEarlierShipment()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
    begin
        // [SCENARIO] Only 3 units are on hand when 5 are shipped — the 10-unit receipt arrives too late
        AddEntry(Quantities, UnitCosts, 3, 1.00);
        AddEntry(Quantities, UnitCosts, -5, 0);
        AddEntry(Quantities, UnitCosts, 10, 1.00);

        asserterror Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.ExpectedError('Insufficient inventory');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FractionalQuantitiesRoundOnlyTheShipmentTotal()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] The layer pieces are 1.114 and 0.884: rounded separately they sum to 1.99,
        // but the exact total 1.998 rounds to 2.00 — the rounding must happen once, at the end.
        AddEntry(Quantities, UnitCosts, 2, 0.557);
        AddEntry(Quantities, UnitCosts, 5, 0.52);
        AddEntry(Quantities, UnitCosts, -3.7, 0);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(1, Costs.Count(), 'Expected exactly one cost for a ledger with one shipment');
        Assert.AreEqual(2.00, Costs.Get(1), 'Expected 2 x 0.557 + 1.7 x 0.52 = 1.998 rounded once to 2.00 — rounding each layer''s piece separately loses a cent here');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AHalfCentTotalRoundsAwayFromZero()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] The exact cost 5 x 1.005 = 5.025 lands on a half cent: the tie
        // must round away from zero (5.03), not to the even cent (5.02)
        AddEntry(Quantities, UnitCosts, 5, 1.005);
        AddEntry(Quantities, UnitCosts, -5, 0);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(1, Costs.Count(), 'Expected exactly one cost for a ledger with one shipment');
        Assert.AreEqual(5.03, Costs.Get(1), 'Expected 5 x 1.005 = 5.025 to round to 5.03 — a half-cent tie rounds away from zero, not to the nearest even cent (5.02)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AReceiptsOnlyLedgerReturnsNoCosts()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
    begin
        // [SCENARIO] Receipts alone produce no output — one cost per shipment, not per entry
        AddEntry(Quantities, UnitCosts, 2, 1.00);
        AddEntry(Quantities, UnitCosts, 3, 2.00);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(0, Costs.Count(), 'Expected an empty result for a ledger with receipts only — costs are returned per shipment, not per entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedLedgerMatchesFifoExactly()
    var
        Calculator: Codeunit "FIFO Cost Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Quantities: List of [Decimal];
        UnitCosts: List of [Decimal];
        Costs: List of [Decimal];
        ExpectedCosts: List of [Decimal];
        OnHand: Decimal;
        Qty: Decimal;
        i: Integer;
    begin
        // [SCENARIO] A generated 24-entry ledger is costed and compared against an
        // independent FIFO computation, so hardcoding the fixed examples fails
        for i := 1 to 24 do
            if (OnHand < 2) or (Any.IntegerInRange(1, 3) > 2) then begin
                Qty := Any.DecimalInRange(1, 40, 2);
                AddEntry(Quantities, UnitCosts, Qty, Any.DecimalInRange(1, 20, 2));
                OnHand += Qty;
            end else begin
                Qty := Any.DecimalInRange(1, OnHand, 2);
                AddEntry(Quantities, UnitCosts, -Qty, 0);
                OnHand -= Qty;
            end;

        // Lists are reference types: a submission may legitimately consume the input
        // lists in place, so the reference expectation must be taken from them first.
        ExpectedCosts := ReferenceFifoCosts(Quantities, UnitCosts);

        Costs := Calculator.ComputeShipmentCosts(Quantities, UnitCosts);

        Assert.AreEqual(ExpectedCosts.Count(), Costs.Count(), 'Expected one cost per shipment of the randomized ledger, in chronological order');
        for i := 1 to ExpectedCosts.Count() do
            Assert.AreEqual(ExpectedCosts.Get(i), Costs.Get(i), StrSubstNo('Expected shipment %1 of the randomized ledger to be costed strictly oldest-layer-first, rounded once to the cent', i));
    end;

    local procedure AddEntry(var Quantities: List of [Decimal]; var UnitCosts: List of [Decimal]; Qty: Decimal; UnitCost: Decimal)
    begin
        Quantities.Add(Qty);
        UnitCosts.Add(UnitCost);
    end;

    local procedure ReferenceFifoCosts(Quantities: List of [Decimal]; UnitCosts: List of [Decimal]): List of [Decimal]
    var
        Costs: List of [Decimal];
        LayerQty: List of [Decimal];
        LayerUnitCost: List of [Decimal];
        Oldest: Integer;
        Qty: Decimal;
        Needed: Decimal;
        Take: Decimal;
        ShipmentCost: Decimal;
        i: Integer;
    begin
        Oldest := 1;
        for i := 1 to Quantities.Count() do begin
            Qty := Quantities.Get(i);
            if Qty > 0 then begin
                LayerQty.Add(Qty);
                LayerUnitCost.Add(UnitCosts.Get(i));
            end else begin
                Needed := -Qty;
                ShipmentCost := 0;
                while Needed > 0 do
                    if LayerQty.Get(Oldest) = 0 then
                        Oldest += 1
                    else begin
                        Take := LayerQty.Get(Oldest);
                        if Take > Needed then
                            Take := Needed;
                        ShipmentCost += Take * LayerUnitCost.Get(Oldest);
                        LayerQty.Set(Oldest, LayerQty.Get(Oldest) - Take);
                        Needed -= Take;
                    end;
                Costs.Add(Round(ShipmentCost, 0.01));
            end;
        end;
        exit(Costs);
    end;
}
