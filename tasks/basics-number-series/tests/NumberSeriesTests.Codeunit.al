codeunit 50900 "Number Series Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstOrderGetsTheSeriesStartingNumber()
    var
        Order: Record "Workshop Order";
        PersistedOrder: Record "Workshop Order";
        Assert: Codeunit Assert;
        StartingNo: Code[20];
    begin
        // [SCENARIO] An order inserted with a blank "No." receives the series' starting number
        // [GIVEN] a fresh WORKSHOP series
        StartingNo := CreateWorkshopSeries('A');

        // [WHEN] inserting an order with a blank "No."
        Order.Init();
        Order.Insert(true);

        // [THEN] the order carries the starting number and is persisted under that key
        Assert.AreEqual(StartingNo, Order."No.",
            'Expected an order inserted with a blank "No." to receive the starting number of the WORKSHOP series');
        Assert.IsTrue(PersistedOrder.Get(StartingNo),
            StrSubstNo('Expected an order with number %1 in the database — the number must be assigned before the row is written', StartingNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConsecutiveOrdersAreNumberedSequentially()
    var
        FirstOrder: Record "Workshop Order";
        SecondOrder: Record "Workshop Order";
        ThirdOrder: Record "Workshop Order";
        Assert: Codeunit Assert;
        StartingNo: Code[20];
    begin
        // [SCENARIO] Every automatically numbered order advances the series by exactly one
        // [GIVEN] a fresh WORKSHOP series
        StartingNo := CreateWorkshopSeries('B');

        // [WHEN] inserting three orders with blank numbers
        FirstOrder.Init();
        FirstOrder.Insert(true);
        SecondOrder.Init();
        SecondOrder.Insert(true);
        ThirdOrder.Init();
        ThirdOrder.Insert(true);

        // [THEN] their numbers form a gapless sequence from the starting number
        Assert.AreEqual(IncStr(StartingNo), SecondOrder."No.",
            'Expected the second order to get the number right after the first — each insert must advance the series by one');
        Assert.AreEqual(IncStr(IncStr(StartingNo)), ThirdOrder."No.",
            'Expected the third order to continue the sequence without gaps');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignedOrdersRecordTheSeriesCode()
    var
        Order: Record "Workshop Order";
        PersistedOrder: Record "Workshop Order";
        Assert: Codeunit Assert;
        StartingNo: Code[20];
    begin
        // [SCENARIO] An automatically numbered order records which series produced its number
        // [GIVEN] a fresh WORKSHOP series
        StartingNo := CreateWorkshopSeries('C');

        // [WHEN] inserting an order with a blank "No."
        Order.Init();
        Order.Insert(true);

        // [THEN] "No. Series" on the persisted order is WORKSHOP
        Assert.IsTrue(PersistedOrder.Get(StartingNo),
            StrSubstNo('Expected an order with number %1 in the database', StartingNo));
        Assert.AreEqual('WORKSHOP', PersistedOrder."No. Series",
            'Expected "No. Series" to be stamped with WORKSHOP on an automatically numbered order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeekReturnsTheUpcomingNumber()
    var
        Order: Record "Workshop Order";
        Assert: Codeunit Assert;
        StartingNo: Code[20];
    begin
        // [SCENARIO] PeekNextOrderNo shows the number the next automatic order will get
        // [GIVEN] a fresh WORKSHOP series with nothing drawn from it yet
        StartingNo := CreateWorkshopSeries('D');

        // [WHEN] peeking the next order number
        // [THEN] it is the series' starting number
        Assert.AreEqual(StartingNo, Order.PeekNextOrderNo(),
            'Expected PeekNextOrderNo to return the number the next automatically numbered order will get');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertAfterPeekingStillGetsThePeekedNumber()
    var
        Order: Record "Workshop Order";
        Assert: Codeunit Assert;
        StartingNo: Code[20];
        Peeked: Code[20];
    begin
        // [SCENARIO] Peeking does not consume a number from the series
        // [GIVEN] a fresh WORKSHOP series, peeked twice
        StartingNo := CreateWorkshopSeries('E');
        Peeked := Order.PeekNextOrderNo();
        Peeked := Order.PeekNextOrderNo();

        // [WHEN] inserting an order with a blank "No."
        Order.Init();
        Order.Insert(true);

        // [THEN] the order still gets the starting number — the peeks consumed nothing
        Assert.AreEqual(StartingNo, Order."No.",
            'Expected the order inserted after peeking twice to still receive the starting number — peeking must not advance the series');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ManualNumberIsKept()
    var
        Order: Record "Workshop Order";
        Any: Codeunit Any;
        Assert: Codeunit Assert;
        ManualNo: Code[20];
    begin
        // [SCENARIO] A caller-supplied number survives insert unchanged
        // [GIVEN] a fresh WORKSHOP series and a manually chosen number
        CreateWorkshopSeries('F');
        ManualNo := CopyStr('TRYAL-' + Any.AlphabeticText(6), 1, MaxStrLen(ManualNo));

        // [WHEN] inserting an order with "No." already set
        Order.Init();
        Order."No." := ManualNo;
        Order.Insert(true);

        // [THEN] the manual number is kept
        Assert.AreEqual(ManualNo, Order."No.",
            'Expected a manually assigned "No." to survive insert unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ManualNumberDrawsNothingFromTheSeries()
    var
        ManualOrder: Record "Workshop Order";
        AutoOrder: Record "Workshop Order";
        Assert: Codeunit Assert;
        StartingNo: Code[20];
    begin
        // [SCENARIO] Inserting a manually numbered order leaves the series untouched
        // [GIVEN] a fresh WORKSHOP series and an inserted manually numbered order
        StartingNo := CreateWorkshopSeries('G');
        ManualOrder.Init();
        ManualOrder."No." := 'TRYAL-MANUAL';
        ManualOrder.Insert(true);

        // [WHEN] inserting the first automatically numbered order
        AutoOrder.Init();
        AutoOrder.Insert(true);

        // [THEN] it gets the starting number — the manual insert drew nothing
        Assert.AreEqual(StartingNo, AutoOrder."No.",
            'Expected the first automatic order after a manually numbered one to still get the starting number — a manual insert must not draw from the series');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FieldsAreDeclaredAsCodeTwenty()
    var
        Order: Record "Workshop Order";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] "No." and "No. Series" are declared exactly as promised
        Order."No." := 'abc';
        Assert.AreEqual('ABC', Order."No.",
            'Expected "No." to be a Code field — Code values are stored uppercase');
        Assert.AreEqual(20, MaxStrLen(Order."No."),
            'Expected "No." to be declared as Code[20] — its maximum length must be exactly 20');
        Order."No. Series" := 'workshop';
        Assert.AreEqual('WORKSHOP', Order."No. Series",
            'Expected "No. Series" to be a Code field — Code values are stored uppercase');
        Assert.AreEqual(20, MaxStrLen(Order."No. Series"),
            'Expected "No. Series" to be declared as Code[20] — its maximum length must be exactly 20');
    end;

    local procedure CreateWorkshopSeries(TestTag: Text[1]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        Any: Codeunit Any;
        StartingNo: Code[20];
    begin
        // The graded company can be reused between runs — clear any leftover
        // WORKSHOP series so the starting number is exactly what this test set.
        NoSeriesLine.SetRange("Series Code", 'WORKSHOP');
        NoSeriesLine.DeleteAll();
        if NoSeries.Get('WORKSHOP') then
            NoSeries.Delete();

        NoSeries.Init();
        NoSeries.Code := 'WORKSHOP';
        NoSeries.Description := 'Workshop orders';
        NoSeries."Default Nos." := true;
        NoSeries.Insert();

        StartingNo := CopyStr('WO' + TestTag + Format(Any.IntegerInRange(10, 89)) + '-001', 1, MaxStrLen(StartingNo));

        NoSeriesLine.Reset();
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := 'WORKSHOP';
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := StartingNo;
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Open := true;
        NoSeriesLine.Insert();

        exit(StartingNo);
    end;
}
