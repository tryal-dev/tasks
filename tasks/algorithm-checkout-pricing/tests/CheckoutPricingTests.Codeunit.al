codeunit 50900 "Checkout Pricing Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleScanCostsTheUnitPrice()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] One scanned item with no deal costs exactly its unit price
        Checkout.SetUnitPrice('BREAD', 1.15);

        Checkout.Scan('BREAD');

        Assert.AreEqual(1.15, Checkout.Total(), 'Expected a single scanned item to cost its unit price');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnitPricesAccumulateAcrossItems()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A plain basket sums quantity times unit price per item
        Checkout.SetUnitPrice('BREAD', 1.15);
        Checkout.SetUnitPrice('APPLE', 0.40);

        ScanTimes(Checkout, 'BREAD', 2);
        ScanTimes(Checkout, 'APPLE', 3);

        Assert.AreEqual(3.50, Checkout.Total(), 'Expected two breads at 1.15 plus three apples at 0.40');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompleteMultibuyGroupPaysTheOfferPrice()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Exactly one complete offer group is charged the offer price instead of unit prices
        Checkout.SetUnitPrice('MILK', 0.85);
        Checkout.SetMultibuyOffer('MILK', 3, 2.00);

        ScanTimes(Checkout, 'MILK', 3);

        Assert.AreEqual(2.00, Checkout.Total(), 'Expected three milks on a 3-for-2.00 offer to cost the offer price');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BelowOfferQuantityPaysUnitPrices()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A quantity below the offer quantity earns no discount at all
        Checkout.SetUnitPrice('MILK', 0.85);
        Checkout.SetMultibuyOffer('MILK', 3, 2.00);

        ScanTimes(Checkout, 'MILK', 2);

        Assert.AreEqual(1.70, Checkout.Total(), 'Expected two milks below the 3-for-2.00 offer to pay plain unit prices');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MultibuyRepeatsPerGroupAndRemainderPaysUnitPrice()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Seven milks on 3-for-2.00 form two offer groups plus one leftover at the unit price
        Checkout.SetUnitPrice('MILK', 0.85);
        Checkout.SetMultibuyOffer('MILK', 3, 2.00);

        ScanTimes(Checkout, 'MILK', 7);

        Assert.AreEqual(4.85, Checkout.Total(), 'Expected two complete 3-for-2.00 groups plus one leftover milk at 0.85');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InterleavedScansStillFormOfferGroups()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Milk scans separated by other items still count together into an offer group
        Checkout.SetUnitPrice('BREAD', 1.15);
        Checkout.SetUnitPrice('MILK', 0.85);
        Checkout.SetMultibuyOffer('MILK', 3, 2.00);

        Checkout.Scan('MILK');
        Checkout.Scan('BREAD');
        Checkout.Scan('MILK');
        Checkout.Scan('MILK');

        Assert.AreEqual(3.15, Checkout.Total(), 'Expected the three interleaved milks to form a 2.00 offer group next to the 1.15 bread');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BulkBreakBelowMinimumPaysTheNormalUnitPrice()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] One unit below the bulk minimum, every unit still costs the normal price
        Checkout.SetUnitPrice('SUGAR', 2.00);
        Checkout.SetBulkPrice('SUGAR', 5, 1.70);

        ScanTimes(Checkout, 'SUGAR', 4);

        Assert.AreEqual(8.00, Checkout.Total(), 'Expected four sugars below the bulk minimum of 5 to pay the normal 2.00 each');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BulkBreakAtMinimumRepricesEveryUnit()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Reaching the bulk minimum reprices all units — 8.50, not 9.70 with only the fifth discounted
        Checkout.SetUnitPrice('SUGAR', 2.00);
        Checkout.SetBulkPrice('SUGAR', 5, 1.70);

        ScanTimes(Checkout, 'SUGAR', 5);

        Assert.AreEqual(8.50, Checkout.Total(), 'Expected all five sugars at the 1.70 bulk price — the break reprices the first four units too');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalCanBeReadAfterEveryScan()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A running total read mid-basket does not disturb the total after further scans
        Checkout.SetUnitPrice('MILK', 0.85);
        Checkout.SetMultibuyOffer('MILK', 3, 2.00);
        ScanTimes(Checkout, 'MILK', 2);
        Assert.AreEqual(1.70, Checkout.Total(), 'Expected the running total after two milks to be two unit prices');

        Checkout.Scan('MILK');

        Assert.AreEqual(2.00, Checkout.Total(), 'Expected the third milk to complete the 3-for-2.00 group even though Total was already read mid-basket');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyBasketTotalsZero()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Configured prices but no scans total zero
        Checkout.SetUnitPrice('BREAD', 1.15);

        Assert.AreEqual(0, Checkout.Total(), 'Expected an empty basket to total 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScanningAnUnpricedItemFails()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Scanning an item with no configured unit price errors, naming the item
        Checkout.SetUnitPrice('BREAD', 1.15);

        asserterror Checkout.Scan('CAVIAR');

        Assert.ExpectedError('no price');
        Assert.IsSubstring(GetLastErrorText(), 'CAVIAR');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedBasketPricesIndependently()
    var
        Checkout: Codeunit "Checkout Pricing";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PlainPrice: Decimal;
        OfferUnitPrice: Decimal;
        OfferPrice: Decimal;
        BulkNormalPrice: Decimal;
        BulkPrice: Decimal;
        Expected: Decimal;
        OfferQty: Integer;
        BulkMin: Integer;
        PlainQty: Integer;
        OfferItemQty: Integer;
        BulkQty: Integer;
        MaxQty: Integer;
        i: Integer;
    begin
        // [SCENARIO] A basket with random prices, quantities and all three deal shapes matches an independently computed total
        PlainPrice := Any.DecimalInRange(1, 9, 2);
        OfferUnitPrice := Any.DecimalInRange(1, 9, 2);
        // Deal parameters deliberately avoid every constant and ratio the fixed tests use
        // (N = 3, M = 5, normal 2.00, bulk = 85% of normal): BulkPrice <= 2 while
        // BulkNormalPrice >= 3, so a submission that hardcodes the examples cannot pass.
        OfferQty := Any.IntegerInRange(4, 6);
        OfferPrice := OfferUnitPrice * (OfferQty - 1);
        BulkNormalPrice := Any.DecimalInRange(3, 9, 2);
        BulkPrice := Any.DecimalInRange(1, 2, 2);
        BulkMin := Any.IntegerInRange(6, 9);
        PlainQty := Any.IntegerInRange(1, 6);
        OfferItemQty := Any.IntegerInRange(OfferQty + 1, 3 * OfferQty);
        BulkQty := BulkMin - 1 + Any.IntegerInRange(1, 4);
        Checkout.SetUnitPrice('APPLE', PlainPrice);
        Checkout.SetUnitPrice('MILK', OfferUnitPrice);
        Checkout.SetMultibuyOffer('MILK', OfferQty, OfferPrice);
        Checkout.SetUnitPrice('SUGAR', BulkNormalPrice);
        Checkout.SetBulkPrice('SUGAR', BulkMin, BulkPrice);
        // The expected total is computed here, independently of the code under test.
        Expected := PlainQty * PlainPrice +
            (OfferItemQty div OfferQty) * OfferPrice + (OfferItemQty mod OfferQty) * OfferUnitPrice +
            BulkQty * BulkPrice;
        MaxQty := PlainQty;
        if OfferItemQty > MaxQty then
            MaxQty := OfferItemQty;
        if BulkQty > MaxQty then
            MaxQty := BulkQty;

        for i := 1 to MaxQty do begin
            if i <= PlainQty then
                Checkout.Scan('APPLE');
            if i <= OfferItemQty then
                Checkout.Scan('MILK');
            if i <= BulkQty then
                Checkout.Scan('SUGAR');
        end;

        Assert.AreEqual(Expected, Checkout.Total(),
            StrSubstNo('Expected the randomized interleaved basket to price independently: APPLE %1 x %2; MILK %3 x %4 on %5-for-%6; SUGAR %7 x %8 with bulk %9 from %10',
                PlainQty, PlainPrice, OfferItemQty, OfferUnitPrice, OfferQty, OfferPrice, BulkQty, BulkNormalPrice, BulkPrice, BulkMin));
    end;

    local procedure ScanTimes(var Checkout: Codeunit "Checkout Pricing"; ItemCode: Code[20]; Quantity: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Quantity do
            Checkout.Scan(ItemCode);
    end;
}
