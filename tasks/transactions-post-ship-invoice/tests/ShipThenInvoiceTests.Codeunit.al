codeunit 50900 "Ship Then Invoice Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Standard posting commits on its own; CommitBehavior::Ignore on every test
    // silences those commits so the run stays rollback-safe and can grade in the
    // shared warm company.

    // [FEATURE] [Sales] [Posting] [Ship] [Invoice]

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShipPassReturnsTheNumberOfThePostedShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] The ship pass returns the number of the shipment it posted
        // [GIVEN] a sales order for a generated quantity
        CreateOrder(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(2, 10));
        OrderNo := SalesHeader."No.";

        // [WHEN] posting the shipment
        ShipmentNo := ShipThenInvoice.PostShipment(OrderNo);

        // [THEN] exactly one shipment was posted for the order, and its "No." is the returned value
        Assert.AreNotEqual('', ShipmentNo,
            'Expected PostShipment to return the number of the shipment it posted, not an empty code');
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(1, SalesShipmentHeader.Count(),
            StrSubstNo('Expected posting order %1 with PostShipment to leave exactly one posted sales shipment for that order', OrderNo));
        SalesShipmentHeader.FindFirst();
        Assert.AreEqual(SalesShipmentHeader."No.", ShipmentNo,
            StrSubstNo('Expected PostShipment to return the "No." of the posted sales shipment of order %1', OrderNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShipPassPostsNoInvoiceAndLeavesTheOrderOpen()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        LineNo: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO] The ship pass ships only — no invoice is posted and the order survives
        // [GIVEN] a sales order for a generated quantity
        Quantity := LibraryRandom.RandIntInRange(2, 10);
        CreateOrder(SalesHeader, SalesLine, Quantity);
        OrderNo := SalesHeader."No.";
        LineNo := SalesLine."Line No.";

        // [WHEN] posting the shipment
        ShipThenInvoice.PostShipment(OrderNo);

        // [THEN] no invoice was posted, and the order is still there, shipped but not invoiced
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(0, SalesInvoiceHeader.Count(),
            StrSubstNo('Expected PostShipment to post a shipment only — no posted sales invoice may exist for order %1 yet', OrderNo));
        Assert.IsTrue(SalesHeader.Get(SalesHeader."Document Type"::Order, OrderNo),
            StrSubstNo('Expected order %1 to still exist after the ship pass — an order that is not invoiced yet is never deleted', OrderNo));
        SalesLine.Get(SalesLine."Document Type"::Order, OrderNo, LineNo);
        Assert.AreEqual(Quantity, SalesLine."Quantity Shipped",
            StrSubstNo('Expected the whole ordered quantity of order %1 to be recorded as shipped on the order line', OrderNo));
        Assert.AreEqual(0, SalesLine."Quantity Invoiced",
            StrSubstNo('Expected nothing to be invoiced on order %1 after the ship pass', OrderNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicePassReturnsTheNumberOfThePostedInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] The invoice pass returns the number of the invoice it posted, although posting deletes the order
        // [GIVEN] a sales order that has been fully shipped
        CreateOrder(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(2, 10));
        OrderNo := SalesHeader."No.";
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] posting the invoice
        InvoiceNo := ShipThenInvoice.PostInvoice(OrderNo);

        // [THEN] exactly one invoice was posted for the order, and its "No." is the returned value
        Assert.AreNotEqual('', InvoiceNo,
            'Expected PostInvoice to return the number of the invoice it posted, not an empty code');
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(1, SalesInvoiceHeader.Count(),
            StrSubstNo('Expected posting order %1 with PostInvoice to leave exactly one posted sales invoice for that order', OrderNo));
        SalesInvoiceHeader.FindFirst();
        Assert.AreEqual(SalesInvoiceHeader."No.", InvoiceNo,
            StrSubstNo('Expected PostInvoice to return the "No." of the posted sales invoice of order %1 — the order itself is deleted once it is fully invoiced, so the number cannot be read back from it', OrderNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicePassCoversOnlyTheShippedQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        InvoiceNo: Code[20];
        LineNo: Integer;
        Quantity: Decimal;
        QtyToShip: Decimal;
    begin
        // [SCENARIO] After a partial shipment the invoice pass invoices the shipped quantity and leaves the rest open
        // [GIVEN] a sales order of a generated quantity of which only a part has been shipped
        Quantity := LibraryRandom.RandIntInRange(6, 12);
        QtyToShip := LibraryRandom.RandIntInRange(2, 5);
        CreateOrder(SalesHeader, SalesLine, Quantity);
        OrderNo := SalesHeader."No.";
        LineNo := SalesLine."Line No.";
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] posting the invoice
        InvoiceNo := ShipThenInvoice.PostInvoice(OrderNo);

        // [THEN] the invoice carries the shipped quantity only, and the order stays open for the remainder
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        Assert.IsTrue(SalesInvoiceLine.FindFirst(),
            StrSubstNo('Expected PostInvoice to return the number of a posted invoice with an item line; got "%1" for order %2', InvoiceNo, OrderNo));
        Assert.AreEqual(QtyToShip, SalesInvoiceLine.Quantity,
            StrSubstNo('Expected the invoice of order %1 to cover only the %2 units that were shipped, not the whole ordered quantity %3', OrderNo, QtyToShip, Quantity));
        Assert.IsTrue(SalesHeader.Get(SalesHeader."Document Type"::Order, OrderNo),
            StrSubstNo('Expected order %1 to stay open after invoicing a partial shipment — only the shipped part may be posted', OrderNo));
        SalesLine.Get(SalesLine."Document Type"::Order, OrderNo, LineNo);
        Assert.AreEqual(QtyToShip, SalesLine."Quantity Shipped",
            StrSubstNo('Expected the invoice pass of order %1 to ship nothing more — the shipped quantity must still be %2', OrderNo, QtyToShip));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure SecondShipPassReturnsTheNewShipmentNumber()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        FirstShipmentNo: Code[20];
        SecondShipmentNo: Code[20];
    begin
        // [SCENARIO] Each ship pass returns the shipment that call posted, not the one before it
        // [GIVEN] a sales order that has already been shipped in part
        CreateOrder(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(6, 12));
        OrderNo := SalesHeader."No.";
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);
        FirstShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] posting the rest of the order as a second shipment
        SecondShipmentNo := ShipThenInvoice.PostShipment(OrderNo);

        // [THEN] the number returned is the second shipment, not the first
        Assert.AreNotEqual(FirstShipmentNo, SecondShipmentNo,
            StrSubstNo('Expected the second PostShipment call on order %1 to return the shipment it posted, not the earlier shipment %2', OrderNo, FirstShipmentNo));
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(2, SalesShipmentHeader.Count(),
            StrSubstNo('Expected order %1 to have two posted shipments after two ship passes', OrderNo));
        Assert.IsTrue(SalesShipmentHeader.Get(SecondShipmentNo),
            StrSubstNo('Expected "%1" — the value PostShipment returned for order %2 — to be the "No." of a posted sales shipment', SecondShipmentNo, OrderNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure SecondInvoicePassReturnsTheNewInvoiceNumber()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        FirstInvoiceNo: Code[20];
        SecondInvoiceNo: Code[20];
    begin
        // [SCENARIO] Each invoice pass returns the invoice that call posted, not the one before it
        // [GIVEN] a sales order whose first partial shipment has already been shipped and invoiced
        CreateOrder(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(6, 12));
        OrderNo := SalesHeader."No.";
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderNo);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
        FirstInvoiceNo := SalesInvoiceHeader."No.";
        // [GIVEN] the rest of the order shipped as a second shipment
        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] invoicing that second shipment
        SecondInvoiceNo := ShipThenInvoice.PostInvoice(OrderNo);

        // [THEN] the number returned is the second invoice, not the first
        Assert.AreNotEqual(FirstInvoiceNo, SecondInvoiceNo,
            StrSubstNo('Expected the second PostInvoice call on order %1 to return the invoice it posted, not the earlier invoice %2', OrderNo, FirstInvoiceNo));
        SalesInvoiceHeader.Reset();
        Assert.IsTrue(SalesInvoiceHeader.Get(SecondInvoiceNo),
            StrSubstNo('Expected "%1" — the value PostInvoice returned for order %2 — to be the "No." of a posted sales invoice', SecondInvoiceNo, OrderNo));
        Assert.AreEqual(OrderNo, SalesInvoiceHeader."Order No.",
            StrSubstNo('Expected the posted invoice %1 that PostInvoice returned to belong to order %2', SecondInvoiceNo, OrderNo));
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(2, SalesInvoiceHeader.Count(),
            StrSubstNo('Expected order %1 to have two posted invoices after two invoice passes', OrderNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShipPassAfterAnInvoicePassPostsNoInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] The ship pass ships only on an order the invoice pass left its posting flags on
        // [GIVEN] a sales order whose first partial shipment has already been shipped and invoiced
        CreateOrder(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(6, 12));
        OrderNo := SalesHeader."No.";
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderNo);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] shipping the rest of the order
        ShipmentNo := ShipThenInvoice.PostShipment(OrderNo);

        // [THEN] no second invoice was posted — the invoice flag of the earlier pass is not inherited
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(1, SalesInvoiceHeader.Count(),
            StrSubstNo('Expected PostShipment to post a shipment only on order %1 — the invoice flag the earlier invoice pass left on the order header must not be inherited, so the single posted invoice stays the only one', OrderNo));

        // [THEN] the shipment it posted is a second one, and its "No." is the returned value
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(2, SalesShipmentHeader.Count(),
            StrSubstNo('Expected order %1 to have two posted shipments after shipping the rest of the order', OrderNo));
        Assert.IsTrue(SalesShipmentHeader.Get(ShipmentNo),
            StrSubstNo('Expected "%1" — the value PostShipment returned for order %2 — to be the "No." of a posted sales shipment', ShipmentNo, OrderNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicingAFullyPostedOrderReturnsNothing()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Invoicing an order that was already shipped and invoiced answers "nothing to post"
        // [GIVEN] a sales order that has been shipped and invoiced, so posting deleted it
        CreateOrder(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(2, 10));
        OrderNo := SalesHeader."No.";
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] posting the invoice once more
        InvoiceNo := ShipThenInvoice.PostInvoice(OrderNo);

        // [THEN] an empty code comes back, with no error and no second invoice
        Assert.AreEqual('', InvoiceNo,
            StrSubstNo('Expected PostInvoice to return an empty code for order %1, which no longer exists', OrderNo));
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(1, SalesInvoiceHeader.Count(),
            StrSubstNo('Expected the nothing-to-post call on order %1 to post nothing — its single posted invoice must stay the only one', OrderNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShippingAFullyPostedOrderReturnsNothing()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        OrderNo: Code[20];
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] Shipping an order that was already shipped and invoiced answers "nothing to post"
        // [GIVEN] a sales order that has been shipped and invoiced, so posting deleted it
        CreateOrder(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(2, 10));
        OrderNo := SalesHeader."No.";
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] posting a shipment once more
        ShipmentNo := ShipThenInvoice.PostShipment(OrderNo);

        // [THEN] an empty code comes back, with no error and no second shipment
        Assert.AreEqual('', ShipmentNo,
            StrSubstNo('Expected PostShipment to return an empty code for order %1, which no longer exists', OrderNo));
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        Assert.AreEqual(1, SalesShipmentHeader.Count(),
            StrSubstNo('Expected the nothing-to-post call on order %1 to post nothing — its single posted shipment must stay the only one', OrderNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UnknownOrderNumberReturnsNothing()
    var
        ShipThenInvoice: Codeunit "Ship Then Invoice";
        UnknownOrderNo: Code[20];
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] An order number that never existed is a nothing-to-post case, not an error
        // [GIVEN] an order number no sales order carries
        UnknownOrderNo := 'TRYAL-T108';

        // [WHEN] posting a shipment for it
        ShipmentNo := ShipThenInvoice.PostShipment(UnknownOrderNo);

        // [THEN] an empty code comes back instead of a platform "does not exist" error
        Assert.AreEqual('', ShipmentNo,
            StrSubstNo('Expected PostShipment to return an empty code for order %1, which does not exist', UnknownOrderNo));
    end;

    local procedure CreateOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', Quantity, '', 0D);
    end;
}
