codeunit 50900 "Order Fulfilment Trace Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Standard posting commits on its own; CommitBehavior::Ignore on every test
    // silences those commits so the run stays rollback-safe and can grade in the
    // shared warm company.

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShippedMapListsEachPartialShipmentSeparately()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        QtyByDocument: Dictionary of [Code[20], Decimal];
        FirstShipmentNo: Code[20];
        SecondShipmentNo: Code[20];
        FirstShipQty: Decimal;
        SecondShipQty: Decimal;
    begin
        // [SCENARIO] Two partial shipments of one order line appear as two separate map entries
        FirstShipQty := LibraryRandom.RandIntInRange(2, 4);
        SecondShipQty := LibraryRandom.RandIntInRange(2, 4);
        CreateOrderWithLine(SalesHeader, SalesLine, FirstShipQty + SecondShipQty + LibraryRandom.RandIntInRange(1, 3));
        FirstShipmentNo := ShipQuantity(SalesHeader, SalesLine, FirstShipQty);
        SecondShipmentNo := ShipQuantity(SalesHeader, SalesLine, SecondShipQty);

        OrderFulfilmentTrace.ShippedQuantityByDocument(SalesHeader."No.", SalesLine."Line No.", QtyByDocument);

        Assert.AreEqual(2, QtyByDocument.Count(),
            StrSubstNo('Expected one entry per posted shipment — two partial shipments must not collapse into a single total. Keys found: %1', KeysAsText(QtyByDocument)));
        AssertMapEntry(QtyByDocument, FirstShipmentNo, FirstShipQty, 'shipped');
        AssertMapEntry(QtyByDocument, SecondShipmentNo, SecondShipQty, 'shipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShippedMapKeepsTwoLinesOfTheSameItemApart()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        QtyByDocument: Dictionary of [Code[20], Decimal];
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] Two order lines of the same item keep separate traces
        CreateOrderWithLine(SalesHeader, FirstLine, 6);
        AddItemLine(SecondLine, SalesHeader, FirstLine."No.", 5);
        FirstLine.Validate("Qty. to Ship", 2);
        FirstLine.Modify(true);
        SecondLine.Validate("Qty. to Ship", 3);
        SecondLine.Modify(true);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        OrderFulfilmentTrace.ShippedQuantityByDocument(SalesHeader."No.", FirstLine."Line No.", QtyByDocument);

        Assert.AreEqual(1, QtyByDocument.Count(),
            StrSubstNo('Expected exactly one shipment entry for the first order line. Keys found: %1', KeysAsText(QtyByDocument)));
        AssertMapEntry(QtyByDocument, ShipmentNo, 2, 'shipped');
        OrderFulfilmentTrace.ShippedQuantityByDocument(SalesHeader."No.", SecondLine."Line No.", QtyByDocument);
        AssertMapEntry(QtyByDocument, ShipmentNo, 3, 'shipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShippedMapDiscardsStaleContentWhenNothingIsShipped()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        QtyByDocument: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] An unshipped order line yields an empty map, discarding caller leftovers
        CreateOrderWithLine(SalesHeader, SalesLine, 10);
        QtyByDocument.Add('TRYAL-STALE', 99);

        OrderFulfilmentTrace.ShippedQuantityByDocument(SalesHeader."No.", SalesLine."Line No.", QtyByDocument);

        Assert.AreEqual(0, QtyByDocument.Count(),
            StrSubstNo('Expected an empty map for an order line that has never been shipped — whatever the caller left in the dictionary must be discarded. Keys found: %1', KeysAsText(QtyByDocument)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicedMapListsEachInvoiceSeparately()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        QtyByDocument: Dictionary of [Code[20], Decimal];
        FirstInvoiceNo: Code[20];
        SecondInvoiceNo: Code[20];
    begin
        // [SCENARIO] Two partial invoices posted from the order appear as two separate map entries
        CreateOrderWithLine(SalesHeader, SalesLine, 10);
        ShipQuantity(SalesHeader, SalesLine, 3);
        ShipQuantity(SalesHeader, SalesLine, 4);
        FirstInvoiceNo := InvoiceQuantityFromOrder(SalesHeader, SalesLine, 5);
        SecondInvoiceNo := InvoiceQuantityFromOrder(SalesHeader, SalesLine, 2);

        OrderFulfilmentTrace.InvoicedQuantityByDocument(SalesHeader."No.", SalesLine."Line No.", QtyByDocument);

        Assert.AreEqual(2, QtyByDocument.Count(),
            StrSubstNo('Expected one entry per posted invoice — two partial invoices must not collapse into a single total. Keys found: %1', KeysAsText(QtyByDocument)));
        AssertMapEntry(QtyByDocument, FirstInvoiceNo, 5, 'invoiced');
        AssertMapEntry(QtyByDocument, SecondInvoiceNo, 2, 'invoiced');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicedMapSumsAMultiShipmentInvoiceIntoOneEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        QtyByDocument: Dictionary of [Code[20], Decimal];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An invoice pulled from two shipments carries two lines for the order line; they sum into one entry
        CreateOrderWithLine(SalesHeader, SalesLine, 10);
        ShipQuantity(SalesHeader, SalesLine, 3);
        ShipQuantity(SalesHeader, SalesLine, 4);
        InvoiceNo := InvoiceShippedViaGetShipment(SalesHeader."No.", SalesHeader."Sell-to Customer No.");

        OrderFulfilmentTrace.InvoicedQuantityByDocument(SalesHeader."No.", SalesLine."Line No.", QtyByDocument);

        Assert.AreEqual(1, QtyByDocument.Count(),
            StrSubstNo('Expected a single entry for the one posted invoice, even though it carries one line per shipment. Keys found: %1', KeysAsText(QtyByDocument)));
        AssertMapEntry(QtyByDocument, InvoiceNo, 7, 'invoiced');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicedMapKeepsTwoLinesOfTheSameItemApart()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        QtyByDocument: Dictionary of [Code[20], Decimal];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] One invoice billing two order lines of the same item keeps separate invoiced traces
        CreateOrderWithLine(SalesHeader, FirstLine, 2);
        AddItemLine(SecondLine, SalesHeader, FirstLine."No.", 3);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        InvoiceNo := InvoiceShippedViaGetShipment(SalesHeader."No.", SalesHeader."Sell-to Customer No.");

        OrderFulfilmentTrace.InvoicedQuantityByDocument(SalesHeader."No.", FirstLine."Line No.", QtyByDocument);

        Assert.AreEqual(1, QtyByDocument.Count(),
            StrSubstNo('Expected exactly one invoice entry for the first order line. Keys found: %1', KeysAsText(QtyByDocument)));
        AssertMapEntry(QtyByDocument, InvoiceNo, 2, 'invoiced');
        OrderFulfilmentTrace.InvoicedQuantityByDocument(SalesHeader."No.", SecondLine."Line No.", QtyByDocument);
        AssertMapEntry(QtyByDocument, InvoiceNo, 3, 'invoiced');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicedMapDiscardsStaleContentWhenNothingIsInvoiced()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        QtyByDocument: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] A shipped-but-uninvoiced order line yields an empty invoiced map, discarding caller leftovers
        CreateOrderWithLine(SalesHeader, SalesLine, 10);
        ShipQuantity(SalesHeader, SalesLine, 3);
        QtyByDocument.Add('TRYAL-STALE', 99);

        OrderFulfilmentTrace.InvoicedQuantityByDocument(SalesHeader."No.", SalesLine."Line No.", QtyByDocument);

        Assert.AreEqual(0, QtyByDocument.Count(),
            StrSubstNo('Expected an empty invoiced map for a shipped but never invoiced order line — the shipment must not leak into it, and caller leftovers must be discarded. Keys found: %1', KeysAsText(QtyByDocument)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicedForShipmentLineFollowsTheShipmentPointers()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        FirstShipmentNo: Code[20];
        SecondShipmentNo: Code[20];
    begin
        // [SCENARIO] Each posted shipment line reports the quantity the invoice lines billed against it
        CreateOrderWithLine(SalesHeader, SalesLine, 10);
        FirstShipmentNo := ShipQuantity(SalesHeader, SalesLine, 3);
        SecondShipmentNo := ShipQuantity(SalesHeader, SalesLine, 4);
        InvoiceShippedViaGetShipment(SalesHeader."No.", SalesHeader."Sell-to Customer No.");

        Assert.AreEqual(3, OrderFulfilmentTrace.InvoicedQuantityForShipmentLine(FirstShipmentNo, FindShipmentLineNo(FirstShipmentNo, SalesLine."Line No.")),
            'Expected the 3 units of the first shipment line to be reported as invoiced against it');
        Assert.AreEqual(4, OrderFulfilmentTrace.InvoicedQuantityForShipmentLine(SecondShipmentNo, FindShipmentLineNo(SecondShipmentNo, SalesLine."Line No.")),
            'Expected the 4 units of the second shipment line to be reported as invoiced against it — not the first shipment''s quantity, and not the order total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicedForShipmentLineKeepsTwoShipmentLinesApart()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] Two item lines shipped together on one posted shipment each report their own invoiced total
        CreateOrderWithLine(SalesHeader, FirstLine, 2);
        AddItemLine(SecondLine, SalesHeader, FirstLine."No.", 3);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        InvoiceShippedViaGetShipment(SalesHeader."No.", SalesHeader."Sell-to Customer No.");

        Assert.AreEqual(2, OrderFulfilmentTrace.InvoicedQuantityForShipmentLine(ShipmentNo, FindShipmentLineNo(ShipmentNo, FirstLine."Line No.")),
            'Expected only the first shipment line''s 2 invoiced units — not the whole shipment''s total');
        Assert.AreEqual(3, OrderFulfilmentTrace.InvoicedQuantityForShipmentLine(ShipmentNo, FindShipmentLineNo(ShipmentNo, SecondLine."Line No.")),
            'Expected only the second shipment line''s 3 invoiced units — not the whole shipment''s total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure InvoicedForShipmentLineIsZeroWhenTheShipmentIsUninvoiced()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] A shipment line with no invoice lines pointing at it reports 0
        CreateOrderWithLine(SalesHeader, SalesLine, 10);
        ShipmentNo := ShipQuantity(SalesHeader, SalesLine, 3);

        Assert.AreEqual(0, OrderFulfilmentTrace.InvoicedQuantityForShipmentLine(ShipmentNo, FindShipmentLineNo(ShipmentNo, SalesLine."Line No.")),
            'Expected 0 for a posted shipment line that no invoice line points at');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure OutstandingQuantityIsTheUnshippedRemainder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        OrderQty: Decimal;
        FirstShipQty: Decimal;
        SecondShipQty: Decimal;
        Outstanding: Decimal;
    begin
        // [SCENARIO] After two partial shipments the outstanding quantity is what has not shipped yet
        FirstShipQty := LibraryRandom.RandIntInRange(2, 4);
        SecondShipQty := LibraryRandom.RandIntInRange(2, 4);
        OrderQty := FirstShipQty + SecondShipQty + LibraryRandom.RandIntInRange(1, 3);
        CreateOrderWithLine(SalesHeader, SalesLine, OrderQty);
        ShipQuantity(SalesHeader, SalesLine, FirstShipQty);
        ShipQuantity(SalesHeader, SalesLine, SecondShipQty);

        Outstanding := OrderFulfilmentTrace.OutstandingQuantity(SalesHeader."No.", SalesLine."Line No.");

        Assert.AreEqual(OrderQty - FirstShipQty - SecondShipQty, Outstanding,
            'Expected the outstanding quantity to be the order line quantity minus everything shipped so far');
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(SalesLine.Quantity - SalesLine."Quantity Shipped", Outstanding,
            'Expected the outstanding quantity to agree with the order line''s own Quantity and "Quantity Shipped"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure OutstandingQuantityIsZeroOnceEverythingHasShipped()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderFulfilmentTrace: Codeunit "Order Fulfilment Trace";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        OrderQty: Decimal;
    begin
        // [SCENARIO] A fully shipped order line has nothing outstanding
        OrderQty := LibraryRandom.RandIntInRange(5, 8);
        CreateOrderWithLine(SalesHeader, SalesLine, OrderQty);
        ShipQuantity(SalesHeader, SalesLine, OrderQty);

        Assert.AreEqual(0, OrderFulfilmentTrace.OutstandingQuantity(SalesHeader."No.", SalesLine."Line No."),
            'Expected 0 outstanding once the whole order line quantity has been shipped');
    end;

    local procedure CreateOrderWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineQuantity: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        AddItemLine(SalesLine, SalesHeader, Item."No.", LineQuantity);
    end;

    local procedure AddItemLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LineQuantity: Decimal)
    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LineQuantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);
    end;

    local procedure ShipQuantity(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; QtyToShip: Decimal): Code[20]
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure InvoiceQuantityFromOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; QtyToInvoice: Decimal): Code[20]
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure InvoiceShippedViaGetShipment(OrderNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        InvoiceHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, CustomerNo);
        SalesGetShipment.SetSalesHeader(InvoiceHeader);
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        exit(LibrarySales.PostSalesDocument(InvoiceHeader, false, true));
    end;

    local procedure FindShipmentLineNo(ShipmentNo: Code[20]; OrderLineNo: Integer): Integer
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesShipmentLine.SetRange("Order Line No.", OrderLineNo);
        SalesShipmentLine.FindFirst();
        exit(SalesShipmentLine."Line No.");
    end;

    local procedure AssertMapEntry(QtyByDocument: Dictionary of [Code[20], Decimal]; DocumentNo: Code[20]; ExpectedQty: Decimal; MapName: Text)
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(QtyByDocument.ContainsKey(DocumentNo),
            StrSubstNo('Expected the %1 map to have an entry for posted document %2. Keys found: %3', MapName, DocumentNo, KeysAsText(QtyByDocument)));
        Assert.AreEqual(ExpectedQty, QtyByDocument.Get(DocumentNo),
            StrSubstNo('Expected the %1 map entry for posted document %2 to carry the quantity posted on that document', MapName, DocumentNo));
    end;

    local procedure KeysAsText(QtyByDocument: Dictionary of [Code[20], Decimal]): Text
    var
        DocumentNo: Code[20];
        Result: Text;
    begin
        foreach DocumentNo in QtyByDocument.Keys() do begin
            if Result <> '' then
                Result += ', ';
            Result += DocumentNo;
        end;
        if Result = '' then
            exit('(none)');
        exit(Result);
    end;
}
