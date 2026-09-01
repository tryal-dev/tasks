codeunit 50900 "Quote To Order Carry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        CampaignTagFieldTok: Label 'Campaign Tag', Locked = true;
        ConvertedFromQuoteFieldTok: Label 'Converted From Quote', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConvertedOrderCarriesTheCampaignTag()
    var
        SalesQuoteHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        Item: Record Item;
        Any: Codeunit Any;
        CampaignTag: Text[30];
    begin
        // [SCENARIO] Converting a quote carries its Campaign Tag onto the created order
        Initialize();
        // [GIVEN] a sales quote carrying a generated 30-character campaign tag
        CampaignTag := CopyStr(Any.AlphanumericText(30), 1, 30);
        CreateQuote(SalesQuoteHeader);
        SetCampaignTag(SalesQuoteHeader, CampaignTag);
        AddItemLine(SalesQuoteHeader, Item, LibraryRandom.RandIntInRange(1, 10));

        // [WHEN] converting the quote to an order
        ConvertQuote(SalesQuoteHeader, SalesOrderHeader);

        // [THEN] the created order carries the same tag
        Assert.AreEqual(CampaignTag, GetCampaignTag(SalesOrderHeader),
            'Expected the created sales order to carry the "Campaign Tag" the quote had at conversion time');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConvertedOrderIsMarkedAsConvertedFromQuote()
    var
        SalesQuoteHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO] The order created by the conversion is marked as won from a quote
        Initialize();
        // [GIVEN] a sales quote with one item line
        CreateQuote(SalesQuoteHeader);
        AddItemLine(SalesQuoteHeader, Item, LibraryRandom.RandIntInRange(1, 10));

        // [WHEN] converting the quote to an order
        ConvertQuote(SalesQuoteHeader, SalesOrderHeader);

        // [THEN] the created order's "Converted From Quote" is true
        Assert.IsTrue(GetConvertedFromQuote(SalesOrderHeader),
            'Expected "Converted From Quote" to be true on the sales order created by converting a quote, got false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectlyCreatedOrderIsNotMarkedAsConverted()
    var
        Customer: Record Customer;
        SalesOrderHeader: Record "Sales Header";
    begin
        // [SCENARIO] A sales order created directly is not marked as won from a quote
        Initialize();
        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] creating a sales order directly, without any quote
        LibrarySales.CreateSalesHeader(SalesOrderHeader, SalesOrderHeader."Document Type"::Order, Customer."No.");
        SalesOrderHeader.Get(SalesOrderHeader."Document Type", SalesOrderHeader."No.");

        // [THEN] "Converted From Quote" stays false
        Assert.IsFalse(GetConvertedFromQuote(SalesOrderHeader),
            'Expected "Converted From Quote" to stay false on a sales order created directly, not by converting a quote, got true');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankCampaignTagStaysBlankOnTheOrder()
    var
        SalesQuoteHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO] Converting a quote whose tag was never filled in leaves the order's tag blank
        Initialize();
        // [GIVEN] a sales quote whose Campaign Tag was never filled in
        CreateQuote(SalesQuoteHeader);
        AddItemLine(SalesQuoteHeader, Item, LibraryRandom.RandIntInRange(1, 10));

        // [WHEN] converting the quote to an order
        ConvertQuote(SalesQuoteHeader, SalesOrderHeader);

        // [THEN] the created order's tag is blank
        Assert.AreEqual('', GetCampaignTag(SalesOrderHeader),
            'Expected the created order''s "Campaign Tag" to stay blank when the quote''s tag was blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConvertedOrderCarriesTheLineQuantities()
    var
        SalesQuoteHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemA: Record Item;
        ItemB: Record Item;
        QuantityA: Decimal;
        QuantityB: Decimal;
    begin
        // [SCENARIO] The conversion still moves every quote line onto the order unchanged
        Initialize();
        // [GIVEN] a sales quote with two item lines carrying generated quantities
        CreateQuote(SalesQuoteHeader);
        QuantityA := LibraryRandom.RandIntInRange(2, 10);
        QuantityB := LibraryRandom.RandIntInRange(11, 20);
        AddItemLine(SalesQuoteHeader, ItemA, QuantityA);
        AddItemLine(SalesQuoteHeader, ItemB, QuantityB);

        // [WHEN] converting the quote to an order
        ConvertQuote(SalesQuoteHeader, SalesOrderHeader);

        // [THEN] the order has exactly those two lines with the quote's items and quantities
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderHeader."No.");
        Assert.RecordCount(SalesLine, 2);
        AssertOrderLineQuantity(SalesOrderHeader, ItemA."No.", QuantityA);
        AssertOrderLineQuantity(SalesOrderHeader, ItemB."No.", QuantityB);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CampaignTagIsTextThirty()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        // [SCENARIO] The Campaign Tag field is declared as Text[30]
        RecRef.Open(Database::"Sales Header");
        FldRef := FieldByName(RecRef, CampaignTagFieldTok);
        Assert.IsTrue(FldRef.Type() = FieldType::Text,
            StrSubstNo('Expected "Campaign Tag" on Sales Header to be declared as Text[30], got a field of type %1', FldRef.Type()));
        Assert.AreEqual(30, FldRef.Length(),
            'Expected "Campaign Tag" on Sales Header to be declared as Text[30] — its maximum length must be exactly 30');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConvertedFromQuoteIsBoolean()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        // [SCENARIO] The Converted From Quote field is declared as Boolean
        RecRef.Open(Database::"Sales Header");
        FldRef := FieldByName(RecRef, ConvertedFromQuoteFieldTok);
        Assert.IsTrue(FldRef.Type() = FieldType::Boolean,
            StrSubstNo('Expected "Converted From Quote" on Sales Header to be declared as Boolean, got a field of type %1', FldRef.Type()));
    end;

    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        Index: Integer;
    begin
        // Looked up by name at run time so the tests compile against a starter that
        // has not added the fields yet, and fail with a message that names them.
        for Index := 1 to RecRef.FieldCount() do
            if RecRef.FieldIndex(Index).Name() = FieldName then
                exit(RecRef.FieldIndex(Index));
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;

    local procedure GetCampaignTag(SalesHeader: Record "Sales Header") CampaignTag: Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesHeader);
        CampaignTag := FieldByName(RecRef, CampaignTagFieldTok).Value();
    end;

    local procedure GetConvertedFromQuote(SalesHeader: Record "Sales Header") ConvertedFromQuote: Boolean
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(SalesHeader);
        FldRef := FieldByName(RecRef, ConvertedFromQuoteFieldTok);
        Assert.IsTrue(FldRef.Type() = FieldType::Boolean,
            StrSubstNo('Expected "Converted From Quote" on Sales Header to be declared as Boolean, got a field of type %1', FldRef.Type()));
        ConvertedFromQuote := FldRef.Value();
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // "Archive Quotes" = Question would raise a Confirm during the
        // conversion — pin it to Never so grading never hits UI.
        SalesSetup.Get();
        SalesSetup."Archive Quotes" := SalesSetup."Archive Quotes"::Never;
        SalesSetup.Modify();
    end;

    local procedure CreateQuote(var SalesQuoteHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesQuoteHeader, SalesQuoteHeader."Document Type"::Quote, Customer."No.");
    end;

    local procedure SetCampaignTag(var SalesHeader: Record "Sales Header"; CampaignTag: Text[30])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesHeader);
        FieldByName(RecRef, CampaignTagFieldTok).Value := CampaignTag;
        RecRef.Modify();
        RecRef.SetTable(SalesHeader);
    end;

    local procedure AddItemLine(SalesHeader: Record "Sales Header"; var Item: Record Item; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
    end;

    local procedure ConvertQuote(var SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    var
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
        QuoteNo: Code[20];
    begin
        QuoteNo := SalesQuoteHeader."No.";
        SalesQuoteToOrder.Run(SalesQuoteHeader);
        // Located through the database, not the codeunit's buffer, so the
        // asserts grade what was actually persisted.
        SalesOrderHeader.SetRange("Document Type", SalesOrderHeader."Document Type"::Order);
        SalesOrderHeader.SetRange("Quote No.", QuoteNo);
        Assert.IsTrue(SalesOrderHeader.FindFirst(),
            StrSubstNo('Expected converting quote %1 to create a sales order', QuoteNo));
    end;

    local procedure AssertOrderLineQuantity(SalesOrderHeader: Record "Sales Header"; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        Assert.IsTrue(SalesLine.FindFirst(),
            StrSubstNo('Expected the created order to carry a line for item %1 from the quote', ItemNo));
        Assert.AreEqual(ExpectedQuantity, SalesLine.Quantity,
            StrSubstNo('Expected the order line for item %1 to keep the quote line''s quantity', ItemNo));
    end;
}
