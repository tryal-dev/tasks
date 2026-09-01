codeunit 50900 "Order JSON Export Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportIsWellFormedJson()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateOrder(SalesHeader);
        AddLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));

        ParseExport(SalesHeader);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportsHeaderFieldsAsTopLevelProperties()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderObject: JsonObject;
    begin
        CreateOrder(SalesHeader);
        AddLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));

        OrderObject := ParseExport(SalesHeader);

        AssertTextProperty(OrderObject, 'orderNo', SalesHeader."No.");
        AssertTextProperty(OrderObject, 'customerNo', SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportsOrderDateAsIso8601String()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderObject: JsonObject;
        DateToken: JsonToken;
    begin
        CreateOrder(SalesHeader);
        SalesHeader.Validate("Order Date", DMY2Date(27, 4, 2026));
        SalesHeader.Modify(true);
        AddLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));

        OrderObject := ParseExport(SalesHeader);

        DateToken := GetProperty(OrderObject, 'orderDate');
        Assert.AreEqual('2026-04-27', DateToken.AsValue().AsText(),
            'Expected the order date April 27, 2026 to serialize as the ISO 8601 string 2026-04-27, whatever the session''s regional settings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroPadsSingleDigitDayAndMonthInOrderDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderObject: JsonObject;
        DateToken: JsonToken;
        OrderDate: Date;
    begin
        OrderDate := DMY2Date(
            LibraryRandom.RandIntInRange(1, 9), LibraryRandom.RandIntInRange(1, 9), LibraryRandom.RandIntInRange(2020, 2035));
        CreateOrder(SalesHeader);
        SalesHeader.Validate("Order Date", OrderDate);
        SalesHeader.Modify(true);
        AddLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));

        OrderObject := ParseExport(SalesHeader);

        DateToken := GetProperty(OrderObject, 'orderDate');
        Assert.AreEqual(ExpectedIsoDate(OrderDate), DateToken.AsValue().AsText(),
            StrSubstNo('Expected the order date %1 to serialize as a zero-padded ISO 8601 yyyy-MM-dd string', OrderDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportsEachSalesLineAsAnArrayElementInLineOrder()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        ThirdLine: Record "Sales Line";
        OrderObject: JsonObject;
        LinesToken: JsonToken;
    begin
        CreateOrder(SalesHeader);
        AddLine(FirstLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));
        AddLine(SecondLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));
        AddLine(ThirdLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));

        OrderObject := ParseExport(SalesHeader);

        LinesToken := GetProperty(OrderObject, 'lines');
        Assert.IsTrue(LinesToken.IsArray(), 'Expected the "lines" property to be a JSON array');
        Assert.AreEqual(3, LinesToken.AsArray().Count(), 'Expected one "lines" array element per sales line of the order');
        AssertLineIdentity(OrderObject, 0, FirstLine);
        AssertLineIdentity(OrderObject, 1, SecondLine);
        AssertLineIdentity(OrderObject, 2, ThirdLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportsOnlyLinesBelongingToTheExportedOrder()
    var
        SalesHeader: Record "Sales Header";
        OtherOrder: Record "Sales Header";
        OrderLine: Record "Sales Line";
        OtherLine: Record "Sales Line";
        OrderObject: JsonObject;
        LinesToken: JsonToken;
    begin
        CreateOrder(SalesHeader);
        AddLine(OrderLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));
        CreateOrder(OtherOrder);
        AddLine(OtherLine, OtherOrder, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));
        AddDecoyQuoteSharingTheOrderNo(SalesHeader);

        OrderObject := ParseExport(SalesHeader);

        LinesToken := GetProperty(OrderObject, 'lines');
        Assert.IsTrue(LinesToken.IsArray(), 'Expected the "lines" property to be a JSON array');
        Assert.AreEqual(1, LinesToken.AsArray().Count(),
            'Expected the "lines" array to contain only the exported order''s own lines — not lines of another order, nor lines of a quote that shares the order''s number');
        AssertLineIdentity(OrderObject, 0, OrderLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritesDecimalsAsCultureInvariantJsonNumbers()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineObject: JsonObject;
    begin
        CreateOrder(SalesHeader);
        AddLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 9, 2), LibraryRandom.RandDecInRange(1000, 9999, 2));

        LineObject := GetLine(ParseExport(SalesHeader), 0);

        AssertNumberProperty(LineObject, 'quantity', SalesLine.Quantity);
        AssertNumberProperty(LineObject, 'unitPrice', SalesLine."Unit Price");
        AssertNumberProperty(LineObject, 'lineAmount', SalesLine."Line Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportsTheStoredLineAmountWithoutRecomputingIt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineObject: JsonObject;
    begin
        CreateOrder(SalesHeader);
        AddLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(100, 500, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(5, 50));
        SalesLine.Modify(true);
        Assert.AreNotEqual(SalesLine.Quantity * SalesLine."Unit Price", SalesLine."Line Amount",
            'Test data must carry a Line Amount different from Quantity * Unit Price to prove no recomputation happens');

        LineObject := GetLine(ParseExport(SalesHeader), 0);

        AssertNumberProperty(LineObject, 'lineAmount', SalesLine."Line Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EscapesHostileCharactersInDescriptions()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineObject: JsonObject;
        HostileDescription: Text[100];
    begin
        HostileDescription := 'TRYAL 24" x 2\ "Steel" bracket';
        CreateOrder(SalesHeader);
        AddLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(2, 500, 2));
        SalesLine.Description := HostileDescription;
        SalesLine.Modify(true);

        LineObject := GetLine(ParseExport(SalesHeader), 0);

        AssertTextProperty(LineObject, 'description', HostileDescription);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportsAnOrderWithoutLinesAsAnEmptyLinesArray()
    var
        SalesHeader: Record "Sales Header";
        OrderObject: JsonObject;
        LinesToken: JsonToken;
    begin
        CreateOrder(SalesHeader);

        OrderObject := ParseExport(SalesHeader);

        LinesToken := GetProperty(OrderObject, 'lines');
        Assert.IsTrue(LinesToken.IsArray(), 'Expected the "lines" property to be a JSON array even when the order has no lines');
        Assert.AreEqual(0, LinesToken.AsArray().Count(), 'Expected an empty "lines" array for an order without lines');
    end;

    local procedure CreateOrder(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
    end;

    local procedure AddLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Qty: Decimal; UnitPrice: Decimal)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure AddDecoyQuoteSharingTheOrderNo(SalesHeader: Record "Sales Header")
    var
        QuoteHeader: Record "Sales Header";
        QuoteLine: Record "Sales Line";
    begin
        QuoteHeader := SalesHeader;
        QuoteHeader."Document Type" := QuoteHeader."Document Type"::Quote;
        QuoteHeader.Insert();
        QuoteLine.Init();
        QuoteLine."Document Type" := QuoteLine."Document Type"::Quote;
        QuoteLine."Document No." := QuoteHeader."No.";
        QuoteLine."Line No." := 10000;
        QuoteLine.Description := 'TRYAL decoy quote line';
        QuoteLine.Insert();
    end;

    // Built from Date2DMY parts on purpose: independent of the Format() path a submission is likely to use.
    local procedure ExpectedIsoDate(D: Date): Text
    begin
        exit(StrSubstNo('%1-%2-%3', ZeroPad(Date2DMY(D, 3), 4), ZeroPad(Date2DMY(D, 2), 2), ZeroPad(Date2DMY(D, 1), 2)));
    end;

    local procedure ZeroPad(Value: Integer; Width: Integer) Padded: Text
    begin
        Padded := Format(Value, 0, 9);
        while StrLen(Padded) < Width do
            Padded := '0' + Padded;
    end;

    local procedure ParseExport(SalesHeader: Record "Sales Header") OrderObject: JsonObject
    var
        OrderJsonExport: Codeunit "Order JSON Export";
        Payload: Text;
    begin
        Payload := OrderJsonExport.ExportOrder(SalesHeader);
        Assert.IsTrue(OrderObject.ReadFrom(Payload),
            StrSubstNo('Expected ExportOrder to return well-formed JSON, but a parser rejected: %1', Payload));
    end;

    local procedure GetProperty(JsonObj: JsonObject; PropertyName: Text) Token: JsonToken
    begin
        Assert.IsTrue(JsonObj.Get(PropertyName, Token),
            StrSubstNo('Expected the JSON object to contain a "%1" property — names are camelCase and case matters', PropertyName));
    end;

    local procedure GetLine(OrderObject: JsonObject; Index: Integer) LineObject: JsonObject
    var
        LinesToken: JsonToken;
        LineToken: JsonToken;
    begin
        LinesToken := GetProperty(OrderObject, 'lines');
        Assert.IsTrue(LinesToken.IsArray(), 'Expected the "lines" property to be a JSON array');
        Assert.IsTrue(LinesToken.AsArray().Get(Index, LineToken),
            StrSubstNo('Expected the "lines" array to have an element at index %1', Index));
        Assert.IsTrue(LineToken.IsObject(), StrSubstNo('Expected element %1 of the "lines" array to be a JSON object', Index));
        LineObject := LineToken.AsObject();
    end;

    local procedure AssertLineIdentity(OrderObject: JsonObject; Index: Integer; SalesLine: Record "Sales Line")
    var
        LineObject: JsonObject;
    begin
        LineObject := GetLine(OrderObject, Index);
        AssertNumberProperty(LineObject, 'lineNo', SalesLine."Line No.");
        AssertTextProperty(LineObject, 'itemNo', SalesLine."No.");
        AssertTextProperty(LineObject, 'description', SalesLine.Description);
    end;

    local procedure AssertTextProperty(JsonObj: JsonObject; PropertyName: Text; Expected: Text)
    var
        Token: JsonToken;
    begin
        Token := GetProperty(JsonObj, PropertyName);
        Assert.AreEqual(Expected, Token.AsValue().AsText(),
            StrSubstNo('Expected the "%1" property to carry the exact value from the sales order', PropertyName));
    end;

    local procedure AssertNumberProperty(JsonObj: JsonObject; PropertyName: Text; Expected: Decimal)
    var
        Token: JsonToken;
        RawValue: Text;
    begin
        Token := GetProperty(JsonObj, PropertyName);
        Assert.IsTrue(Token.IsValue(), StrSubstNo('Expected the "%1" property to be a plain JSON value, not an object or array', PropertyName));
        Token.WriteTo(RawValue);
        Assert.IsFalse(RawValue.StartsWith('"'),
            StrSubstNo('Expected the "%1" property to be an unquoted JSON number, but it serializes as %2', PropertyName, RawValue));
        Assert.AreEqual(Expected, Token.AsValue().AsDecimal(),
            StrSubstNo('Expected the "%1" property to carry the value from the sales line', PropertyName));
    end;
}
