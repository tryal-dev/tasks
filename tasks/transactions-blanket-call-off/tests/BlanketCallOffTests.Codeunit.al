codeunit 50900 "Blanket Call Off Tests"
{
    // [FEATURE] [Sales] [Blanket Order]
    Subtype = Test;
    TestPermissions = Disabled;

    // Standard posting commits on its own; CommitBehavior::Ignore on every test
    // silences those commits so the run stays rollback-safe and can grade in the
    // shared warm company.

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CallOffCreatesAnOrderForTheCalledOffTranche()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        CreatedOrder: Record "Sales Header";
        CreatedOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        TrancheQty: Decimal;
        OrderNo: Code[20];
    begin
        // [SCENARIO] Calling off a tranche creates one sales order for that quantity
        Initialize();
        // [GIVEN] a blanket order line for a generated quantity
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, LibraryRandom.RandIntInRange(60, 120));
        TrancheQty := LibraryRandom.RandIntInRange(5, 25);

        // [WHEN] calling off part of it
        OrderNo := BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", TrancheQty);

        // [THEN] the returned number is a real sales order for the same customer, carrying just that tranche
        Assert.IsTrue(OrderNo <> '',
            'Expected CallOff to return the number of the sales order it created, got an empty code');
        Assert.IsTrue(CreatedOrder.Get(CreatedOrder."Document Type"::Order, OrderNo),
            StrSubstNo('Expected a sales order with the returned number %1 to exist', OrderNo));
        Assert.AreEqual(BlanketOrderHeader."Sell-to Customer No.", CreatedOrder."Sell-to Customer No.",
            'Expected the called-off order to be for the blanket order''s customer');
        CreatedOrderLine.SetRange("Document Type", CreatedOrderLine."Document Type"::Order);
        CreatedOrderLine.SetRange("Document No.", OrderNo);
        Assert.AreEqual(1, CreatedOrderLine.Count(),
            StrSubstNo('Expected the called-off order %1 to carry exactly one line — the tranche of the blanket line that was called off', OrderNo));
        CreatedOrderLine.FindFirst();
        Assert.AreEqual(BlanketOrderLine."No.", CreatedOrderLine."No.",
            'Expected the called-off order line to be for the item on the blanket line');
        Assert.AreEqual(TrancheQty, CreatedOrderLine.Quantity,
            'Expected the called-off order line to carry exactly the quantity that was called off');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CalledOffOrderLineLinksBackToTheBlanketLine()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        CreatedOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        OrderNo: Code[20];
    begin
        // [SCENARIO] The created order line points back at the blanket order line it was called off from
        Initialize();
        // [GIVEN] a blanket order line for a generated quantity
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, LibraryRandom.RandIntInRange(60, 120));

        // [WHEN] calling off part of it
        OrderNo := BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", LibraryRandom.RandIntInRange(5, 25));

        // [THEN] the order line carries the blanket order number and line number
        FindCreatedOrderLine(CreatedOrderLine, OrderNo);
        Assert.AreEqual(BlanketOrderHeader."No.", CreatedOrderLine."Blanket Order No.",
            'Expected the created order line''s "Blanket Order No." to hold the blanket order it was called off from — without that link, posting never reports back to the agreement');
        Assert.AreEqual(BlanketOrderLine."Line No.", CreatedOrderLine."Blanket Order Line No.",
            'Expected the created order line''s "Blanket Order Line No." to hold the blanket line it was called off from');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CallOffLeavesTheBlanketOrderStanding()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        StoredBlanketOrder: Record "Sales Header";
        StoredBlanketLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        BlanketQty: Decimal;
    begin
        // [SCENARIO] The blanket order survives a call-off as an open agreement
        Initialize();
        // [GIVEN] a blanket order line for a generated quantity
        BlanketQty := LibraryRandom.RandIntInRange(60, 120);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, BlanketQty);

        // [WHEN] calling off part of it
        BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", LibraryRandom.RandIntInRange(5, 25));

        // [THEN] the blanket order is still there, unchanged and unposted
        Assert.IsTrue(StoredBlanketOrder.Get(StoredBlanketOrder."Document Type"::"Blanket Order", BlanketOrderHeader."No."),
            StrSubstNo('Expected blanket order %1 to survive the call-off as an open agreement', BlanketOrderHeader."No."));
        StoredBlanketLine.Get(StoredBlanketLine."Document Type"::"Blanket Order", BlanketOrderHeader."No.", BlanketOrderLine."Line No.");
        Assert.AreEqual(BlanketQty, StoredBlanketLine.Quantity,
            'Expected the blanket line''s agreed Quantity to be untouched by a call-off');
        Assert.AreEqual(0, StoredBlanketLine."Quantity Shipped",
            'Expected the blanket line''s "Quantity Shipped" to stay 0 until the called-off order is actually posted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CallOffTakesOnlyTheRequestedLine()
    var
        BlanketOrderHeader: Record "Sales Header";
        FirstBlanketLine: Record "Sales Line";
        SecondBlanketLine: Record "Sales Line";
        CreatedOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        TrancheQty: Decimal;
        OrderNo: Code[20];
    begin
        // [SCENARIO] Only the blanket line that was named in the call is called off
        Initialize();
        // [GIVEN] a blanket order whose second line is the one to call off
        CreateBlanketOrder(BlanketOrderHeader, FirstBlanketLine, LibraryRandom.RandIntInRange(60, 120));
        AddBlanketLine(BlanketOrderHeader, SecondBlanketLine, LibraryRandom.RandIntInRange(60, 120));
        TrancheQty := LibraryRandom.RandIntInRange(5, 25);

        // [WHEN] calling off a tranche of the second line only
        OrderNo := BlanketCallOff.CallOff(BlanketOrderHeader."No.", SecondBlanketLine."Line No.", TrancheQty);

        // [THEN] the created order holds that tranche and nothing from the first line
        CreatedOrderLine.SetRange("Document Type", CreatedOrderLine."Document Type"::Order);
        CreatedOrderLine.SetRange("Document No.", OrderNo);
        Assert.AreEqual(1, CreatedOrderLine.Count(),
            StrSubstNo('Expected the called-off order %1 to hold one line only — the other blanket line must not be called off with it', OrderNo));
        CreatedOrderLine.FindFirst();
        Assert.AreEqual(SecondBlanketLine."No.", CreatedOrderLine."No.",
            'Expected the single order line to be for the item of the blanket line that was named in the call, not for whichever line comes first on the document');
        Assert.AreEqual(TrancheQty, CreatedOrderLine.Quantity,
            'Expected the single order line to carry the called-off quantity');
        Assert.AreEqual(SecondBlanketLine."Line No.", CreatedOrderLine."Blanket Order Line No.",
            'Expected the created order line to point back at the blanket line that was named in the call — the "Blanket Order Line No." argument decides which line is called off');
        Assert.AreEqual(0, CountCallOffLines(BlanketOrderHeader."No.", FirstBlanketLine."Line No."),
            'Expected no sales order line at all to be called off against the blanket line that was not asked for');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RemainingIsTheFullQuantityOnAnUntouchedLine()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        BlanketQty: Decimal;
    begin
        // [SCENARIO] Nothing called off yet means the whole agreed quantity is still available
        Initialize();
        // [GIVEN] a blanket order line for a generated quantity, never called off
        BlanketQty := LibraryRandom.RandIntInRange(60, 120);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, BlanketQty);

        // [WHEN] asking what remains
        // [THEN] the full agreed quantity is reported
        Assert.AreEqual(BlanketQty, BlanketCallOff.RemainingOnBlanket(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected an untouched blanket line to report its whole agreed Quantity as remaining');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RemainingCountsAnOpenCallOffOrder()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        BlanketQty: Decimal;
        TrancheQty: Decimal;
    begin
        // [SCENARIO] A called-off but unposted order already reduces what remains
        Initialize();
        // [GIVEN] a blanket order line for a generated quantity
        BlanketQty := LibraryRandom.RandIntInRange(60, 120);
        TrancheQty := LibraryRandom.RandIntInRange(5, 25);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, BlanketQty);

        // [WHEN] calling off a tranche and leaving the created order unposted
        BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", TrancheQty);

        // [THEN] the outstanding quantity of that open order counts against the line
        Assert.AreEqual(BlanketQty - TrancheQty, BlanketCallOff.RemainingOnBlanket(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected an open, unposted call-off order to count against the blanket line — nothing has shipped yet, but the quantity is committed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RemainingIsTrackedPerBlanketLine()
    var
        BlanketOrderHeader: Record "Sales Header";
        FirstBlanketLine: Record "Sales Line";
        SecondBlanketLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        FirstBlanketQty: Decimal;
        SecondBlanketQty: Decimal;
        TrancheQty: Decimal;
    begin
        // [SCENARIO] Calling off one line of a two-line blanket order leaves the sibling line's remainder alone
        Initialize();
        // [GIVEN] a blanket order with two lines of different agreed quantities
        FirstBlanketQty := LibraryRandom.RandIntInRange(60, 90);
        SecondBlanketQty := LibraryRandom.RandIntInRange(91, 120);
        TrancheQty := LibraryRandom.RandIntInRange(5, 25);
        CreateBlanketOrder(BlanketOrderHeader, FirstBlanketLine, FirstBlanketQty);
        AddBlanketLine(BlanketOrderHeader, SecondBlanketLine, SecondBlanketQty);

        // [WHEN] calling off a tranche of the second line
        BlanketCallOff.CallOff(BlanketOrderHeader."No.", SecondBlanketLine."Line No.", TrancheQty);

        // [THEN] only that line's remainder moves
        Assert.AreEqual(SecondBlanketQty - TrancheQty, BlanketCallOff.RemainingOnBlanket(BlanketOrderHeader."No.", SecondBlanketLine."Line No."),
            'Expected the called-off blanket line to report its own agreed Quantity minus the tranche committed against it');
        Assert.AreEqual(FirstBlanketQty, BlanketCallOff.RemainingOnBlanket(BlanketOrderHeader."No.", FirstBlanketLine."Line No."),
            'Expected the untouched blanket line to still report its whole agreed Quantity — what remains is tracked per line, not per document');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure PostingTheCallOffOrderReportsBackToTheBlanketLine()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        StoredBlanketLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        TrancheQty: Decimal;
        OrderNo: Code[20];
    begin
        // [SCENARIO] Posting a called-off order updates the blanket line's shipped and invoiced quantities
        Initialize();
        // [GIVEN] a blanket order line with a tranche called off
        TrancheQty := LibraryRandom.RandIntInRange(5, 25);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, LibraryRandom.RandIntInRange(60, 120));
        OrderNo := BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", TrancheQty);

        // [WHEN] posting that order as shipped and invoiced
        PostCallOffOrder(OrderNo);

        // [THEN] the blanket line records the delivery
        StoredBlanketLine.Get(StoredBlanketLine."Document Type"::"Blanket Order", BlanketOrderHeader."No.", BlanketOrderLine."Line No.");
        Assert.AreEqual(TrancheQty, StoredBlanketLine."Quantity Shipped",
            'Expected posting the called-off order to add the tranche to the blanket line''s "Quantity Shipped" — that only happens when the order line is attached to the blanket line');
        Assert.AreEqual(TrancheQty, StoredBlanketLine."Quantity Invoiced",
            'Expected posting the called-off order to add the tranche to the blanket line''s "Quantity Invoiced"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RemainingIsUnchangedByPostingTheCallOffOrder()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        BlanketQty: Decimal;
        TrancheQty: Decimal;
        OrderNo: Code[20];
    begin
        // [SCENARIO] A tranche moving from open order to posted shipment does not change what remains
        Initialize();
        // [GIVEN] a blanket order line with a tranche called off
        BlanketQty := LibraryRandom.RandIntInRange(60, 120);
        TrancheQty := LibraryRandom.RandIntInRange(5, 25);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, BlanketQty);
        OrderNo := BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", TrancheQty);

        // [WHEN] posting that order as shipped and invoiced
        PostCallOffOrder(OrderNo);

        // [THEN] the remaining quantity is what it was before posting
        Assert.AreEqual(BlanketQty - TrancheQty, BlanketCallOff.RemainingOnBlanket(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected the remaining quantity to be the same before and after posting the tranche — it only moves from committed to shipped, and must not be subtracted twice');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RemainingCountsAShippedButUninvoicedTrancheOnlyOnce()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        BlanketQty: Decimal;
        TrancheQty: Decimal;
        OrderNo: Code[20];
    begin
        // [SCENARIO] A tranche that has shipped but not been invoiced is subtracted once, not twice
        Initialize();
        // [GIVEN] a blanket order line with a tranche called off
        BlanketQty := LibraryRandom.RandIntInRange(60, 120);
        TrancheQty := LibraryRandom.RandIntInRange(5, 25);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, BlanketQty);
        OrderNo := BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", TrancheQty);

        // [WHEN] posting that order as shipped only, so the call-off order survives with nothing left outstanding
        ShipCallOffOrder(OrderNo);

        // [THEN] the tranche is still subtracted exactly once
        Assert.AreEqual(BlanketQty - TrancheQty, BlanketCallOff.RemainingOnBlanket(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected a shipped but uninvoiced tranche to count once: the blanket line''s "Quantity Shipped" already holds it, and the call-off order line that is still open owes nothing more');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CallingOffTheWholeRemainderIsAllowed()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        CreatedOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        BlanketQty: Decimal;
        FirstTrancheQty: Decimal;
        OrderNo: Code[20];
    begin
        // [SCENARIO] The last call-off may take everything that is left
        Initialize();
        // [GIVEN] a blanket order line with one tranche already called off
        BlanketQty := LibraryRandom.RandIntInRange(60, 120);
        FirstTrancheQty := LibraryRandom.RandIntInRange(5, 25);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, BlanketQty);
        BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", FirstTrancheQty);

        // [WHEN] calling off exactly what is left
        OrderNo := BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", BlanketQty - FirstTrancheQty);

        // [THEN] a second order carries the remainder and the line is fully committed
        FindCreatedOrderLine(CreatedOrderLine, OrderNo);
        Assert.AreEqual(BlanketQty - FirstTrancheQty, CreatedOrderLine.Quantity,
            'Expected the final call-off to create an order line for the whole remaining quantity');
        Assert.AreEqual(0, BlanketCallOff.RemainingOnBlanket(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected nothing to remain once the whole agreed quantity has been called off');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CallingOffMoreThanTheLineQuantityFails()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        BlanketQty: Decimal;
    begin
        // [SCENARIO] A call-off above the agreed quantity is rejected and creates nothing
        Initialize();
        // [GIVEN] a blanket order line for a generated quantity
        BlanketQty := LibraryRandom.RandIntInRange(60, 120);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, BlanketQty);

        // [WHEN] calling off one unit more than the line agreed to
        AssertCallOffIsRefused(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", BlanketQty + 1, 'exceeds the remaining quantity');

        // [THEN] it is rejected and no order was left behind
        Assert.AreEqual(0, CountCallOffLines(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected a rejected call-off to leave no sales order line attached to the blanket line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CallingOffMoreThanTheOpenRemainderFails()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
        BlanketQty: Decimal;
        FirstTrancheQty: Decimal;
    begin
        // [SCENARIO] An earlier, still open call-off shrinks what the next one may take
        Initialize();
        // [GIVEN] a blanket order line with one tranche already called off and not yet posted
        BlanketQty := LibraryRandom.RandIntInRange(60, 120);
        FirstTrancheQty := LibraryRandom.RandIntInRange(5, 25);
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, BlanketQty);
        BlanketCallOff.CallOff(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", FirstTrancheQty);

        // [WHEN] calling off one unit more than what is left
        AssertCallOffIsRefused(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", BlanketQty - FirstTrancheQty + 1, 'exceeds the remaining quantity');

        // [THEN] it is rejected and the first call-off is still the only one
        Assert.AreEqual(1, CountCallOffLines(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected the rejected call-off to add nothing — the blanket line should still carry exactly the one order line from the first tranche');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CallingOffZeroFails()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
    begin
        // [SCENARIO] A call-off of zero is rejected
        Initialize();
        // [GIVEN] a blanket order line for a generated quantity
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, LibraryRandom.RandIntInRange(60, 120));

        // [WHEN] calling off nothing
        AssertCallOffIsRefused(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", 0, 'must be positive');

        // [THEN] it is rejected and no order was left behind
        Assert.AreEqual(0, CountCallOffLines(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected a call-off of zero to create no sales order at all');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CallingOffANegativeQuantityFails()
    var
        BlanketOrderHeader: Record "Sales Header";
        BlanketOrderLine: Record "Sales Line";
        BlanketCallOff: Codeunit "Blanket Call Off";
    begin
        // [SCENARIO] A negative call-off is rejected
        Initialize();
        // [GIVEN] a blanket order line for a generated quantity
        CreateBlanketOrder(BlanketOrderHeader, BlanketOrderLine, LibraryRandom.RandIntInRange(60, 120));

        // [WHEN] calling off a negative quantity
        AssertCallOffIsRefused(BlanketOrderHeader."No.", BlanketOrderLine."Line No.", -LibraryRandom.RandIntInRange(5, 25), 'must be positive');

        // [THEN] it is rejected and no order was left behind
        Assert.AreEqual(0, CountCallOffLines(BlanketOrderHeader."No.", BlanketOrderLine."Line No."),
            'Expected a negative call-off to create no sales order at all');
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        // Pin the ambient setup: blanket lines must arrive with "Qty. to Ship"
        // prefilled (Remainder is the standard default), the created order needs
        // a posting date, no warning dialog may interrupt a graded run, and
        // posting must happen in this session rather than on a job queue.
        SalesSetup.Get();
        SalesSetup."Default Quantity to Ship" := SalesSetup."Default Quantity to Ship"::Remainder;
        SalesSetup."Default Posting Date" := SalesSetup."Default Posting Date"::"Work Date";
        SalesSetup."Stockout Warning" := false;
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup."Post with Job Queue" := false;
        SalesSetup.Modify();
        // The tranches are shipped out of items that were never stocked.
        InventorySetup.Get();
        InventorySetup."Prevent Negative Inventory" := false;
        InventorySetup.Modify();
    end;

    local procedure CreateBlanketOrder(var BlanketOrderHeader: Record "Sales Header"; var BlanketOrderLine: Record "Sales Line"; BlanketQty: Decimal)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(BlanketOrderHeader, BlanketOrderHeader."Document Type"::"Blanket Order", Customer."No.");
        AddBlanketLine(BlanketOrderHeader, BlanketOrderLine, BlanketQty);
    end;

    local procedure AddBlanketLine(BlanketOrderHeader: Record "Sales Header"; var BlanketOrderLine: Record "Sales Line"; BlanketQty: Decimal)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(BlanketOrderLine, BlanketOrderHeader, BlanketOrderLine.Type::Item, Item."No.", BlanketQty);
        BlanketOrderLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        BlanketOrderLine.Modify(true);
    end;

    local procedure FindCreatedOrderLine(var CreatedOrderLine: Record "Sales Line"; OrderNo: Code[20])
    begin
        CreatedOrderLine.SetRange("Document Type", CreatedOrderLine."Document Type"::Order);
        CreatedOrderLine.SetRange("Document No.", OrderNo);
        Assert.IsTrue(CreatedOrderLine.FindFirst(),
            StrSubstNo('Expected the called-off sales order %1 to carry a line', OrderNo));
    end;

    local procedure PostCallOffOrder(OrderNo: Code[20])
    var
        SalesOrderHeader: Record "Sales Header";
    begin
        GetCallOffOrder(SalesOrderHeader, OrderNo);
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, true);
    end;

    local procedure ShipCallOffOrder(OrderNo: Code[20])
    var
        SalesOrderHeader: Record "Sales Header";
    begin
        GetCallOffOrder(SalesOrderHeader, OrderNo);
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);
    end;

    local procedure GetCallOffOrder(var SalesOrderHeader: Record "Sales Header"; OrderNo: Code[20])
    begin
        Assert.IsTrue(SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, OrderNo),
            StrSubstNo('Expected the called-off sales order %1 to exist so the test can post it', OrderNo));
    end;

    local procedure CountCallOffLines(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer): Integer
    var
        CallOffLine: Record "Sales Line";
    begin
        CallOffLine.SetRange("Document Type", CallOffLine."Document Type"::Order);
        CallOffLine.SetRange("Blanket Order No.", BlanketOrderNo);
        CallOffLine.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
        exit(CallOffLine.Count());
    end;

    // A refused call-off is caught through a try function, not asserterror: an
    // error caught by asserterror rolls the transaction back to the last commit
    // and would take the blanket order with it; a try function keeps every row.
    local procedure AssertCallOffIsRefused(BlanketNo: Code[20]; LineNo: Integer; Qty: Decimal; Fragment: Text)
    begin
        if TryCallOff(BlanketNo, LineNo, Qty) then
            Assert.Fail(StrSubstNo('Expected a call-off of %1 to be rejected with a message containing "%2", but it went through', Qty, Fragment));
        AssertErrorContains(Fragment);
    end;

    [TryFunction]
    local procedure TryCallOff(BlanketNo: Code[20]; LineNo: Integer; Qty: Decimal)
    var
        BlanketCallOff: Codeunit "Blanket Call Off";
    begin
        BlanketCallOff.CallOff(BlanketNo, LineNo, Qty);
    end;

    local procedure AssertErrorContains(Fragment: Text)
    var
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains(LowerCase(Fragment)),
            StrSubstNo('Expected the rejected call-off to fail with a message containing "%1", got: %2', Fragment, ActualError));
    end;
}
