codeunit 50900 "Sales Order Xml Export Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RootElementCarriesTheOrderIdentity()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        // [SCENARIO] The root element is SalesOrder and identifies the exported order
        CreateOrder(SalesHeader, Customer);
        AddItemLine(SalesLine, SalesHeader, 2, 100);

        ExportOrderToXml(SalesHeader, Doc);

        Assert.IsTrue(Doc.GetRoot(Root), 'Expected the exported document to have a root element');
        Assert.AreEqual('SalesOrder', Root.LocalName(), 'Expected the root element to be named SalesOrder');
        Assert.AreEqual(SalesHeader."No.", AttributeValue(Doc, '/SalesOrder/@no'),
            'Expected the root''s no attribute to carry the order''s No.');
        Assert.AreEqual(Customer."No.", AttributeValue(Doc, '/SalesOrder/@customerNo'),
            'Expected the root''s customerNo attribute to carry the order''s Sell-to Customer No.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderDateIsRenderedInXmlFormat()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Doc: XmlDocument;
        DayNo: Integer;
        MonthNo: Integer;
        YearNo: Integer;
    begin
        // [SCENARIO] The orderDate attribute uses zero-padded yyyy-mm-dd whatever the server locale
        // Single-digit day and month so an unpadded rendering (2026-3-5) fails deterministically.
        DayNo := Any.IntegerInRange(1, 9);
        MonthNo := Any.IntegerInRange(1, 9);
        YearNo := 2020 + Any.IntegerInRange(1, 20);
        CreateOrder(SalesHeader, Customer);
        SalesHeader.Validate("Order Date", DMY2Date(DayNo, MonthNo, YearNo));
        SalesHeader.Modify(true);

        ExportOrderToXml(SalesHeader, Doc);

        Assert.AreEqual(StrSubstNo('%1-0%2-0%3', YearNo, MonthNo, DayNo), AttributeValue(Doc, '/SalesOrder/@orderDate'),
            'Expected the orderDate attribute as yyyy-mm-dd with zero-padded month and day — it must not depend on the server''s regional settings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerNameSurvivesHostileCharacters()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Assert: Codeunit Assert;
        Doc: XmlDocument;
    begin
        // [SCENARIO] Apostrophes, ampersands and angle brackets in the customer name round-trip intact
        CreateCustomerNamed(Customer, 'TRYAL O''Brien & Sons <Import/Export>');
        CreateOrderFor(SalesHeader, Customer."No.");

        ExportOrderToXml(SalesHeader, Doc);

        Assert.AreEqual('TRYAL O''Brien & Sons <Import/Export>', ElementText(Doc, '/SalesOrder/Customer/Name'),
            'Expected the Customer/Name element to reproduce the customer name exactly — & < > and apostrophes must survive the write/read round trip');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportsEveryItemLineInLineNoOrder()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: array[3] of Record "Sales Line";
        Assert: Codeunit Assert;
        Doc: XmlDocument;
        LineList: XmlNodeList;
        i: Integer;
    begin
        // [SCENARIO] One Line element per sales line, ascending by Line No., carrying lineNo, no and description
        CreateOrder(SalesHeader, Customer);
        for i := 1 to 3 do
            AddItemLine(SalesLine[i], SalesHeader, i, 10 * i);

        ExportOrderToXml(SalesHeader, Doc);

        Assert.IsTrue(Doc.SelectNodes('/SalesOrder/Lines/Line', LineList),
            'Expected the exported document to contain /SalesOrder/Lines/Line elements');
        Assert.AreEqual(3, LineList.Count(), 'Expected exactly one Line element per sales line of the order');
        for i := 1 to 3 do begin
            Assert.AreEqual(Format(SalesLine[i]."Line No.", 0, 9),
                AttributeValue(Doc, StrSubstNo('/SalesOrder/Lines/Line[%1]/@lineNo', i)),
                StrSubstNo('Expected Line element %1 to carry the Line No. of the order''s line %1 — Line elements must come in ascending Line No. order', i));
            Assert.AreEqual(SalesLine[i]."No.",
                AttributeValue(Doc, StrSubstNo('/SalesOrder/Lines/Line[%1]/@no', i)),
                StrSubstNo('Expected Line element %1 to carry the No. of the order''s line %1 in its no attribute', i));
            Assert.AreEqual(SalesLine[i].Description,
                AttributeValue(Doc, StrSubstNo('/SalesOrder/Lines/Line[%1]/@description', i)),
                StrSubstNo('Expected Line element %1 to carry the Description of the order''s line %1 in its description attribute', i));
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmountsAreRenderedInXmlFormat()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Doc: XmlDocument;
        QuantityWhole: Integer;
        QuantityTenths: Integer;
        PriceWhole: Integer;
        PriceTenths: Integer;
        PriceHundredths: Integer;
    begin
        // [SCENARIO] quantity and unitPrice use a dot and no digit grouping whatever the server locale
        // Amounts above 1000 with a non-zero last decimal, so the expected text is known digit by digit.
        QuantityWhole := Any.IntegerInRange(1001, 9999);
        QuantityTenths := Any.IntegerInRange(1, 9);
        PriceWhole := Any.IntegerInRange(1001, 9999);
        PriceTenths := Any.IntegerInRange(0, 9);
        PriceHundredths := Any.IntegerInRange(1, 9);
        CreateOrder(SalesHeader, Customer);
        AddItemLine(SalesLine, SalesHeader, QuantityWhole + QuantityTenths / 10, PriceWhole + PriceTenths / 10 + PriceHundredths / 100);

        ExportOrderToXml(SalesHeader, Doc);

        Assert.AreEqual(StrSubstNo('%1.%2', Format(QuantityWhole, 0, 9), QuantityTenths),
            AttributeValue(Doc, '/SalesOrder/Lines/Line[1]/@quantity'),
            'Expected the quantity attribute in XML-invariant form — a dot as decimal separator and no digit grouping, whatever the server''s regional settings');
        Assert.AreEqual(StrSubstNo('%1.%2%3', Format(PriceWhole, 0, 9), PriceTenths, PriceHundredths),
            AttributeValue(Doc, '/SalesOrder/Lines/Line[1]/@unitPrice'),
            'Expected the unitPrice attribute in XML-invariant form — a dot as decimal separator and no digit grouping, whatever the server''s regional settings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmountsUseTheFewestDigitsNeeded()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        Doc: XmlDocument;
    begin
        // [SCENARIO] A whole quantity renders without a decimal point, a price without trailing zeros
        CreateOrder(SalesHeader, Customer);
        AddItemLine(SalesLine, SalesHeader, 7, 193.7);

        ExportOrderToXml(SalesHeader, Doc);

        Assert.AreEqual('7', AttributeValue(Doc, '/SalesOrder/Lines/Line[1]/@quantity'),
            'Expected the whole-number quantity 7 to render with no decimal point — 7, never 7.0 or 7.00');
        Assert.AreEqual('193.7', AttributeValue(Doc, '/SalesOrder/Lines/Line[1]/@unitPrice'),
            'Expected the unit price 193.7 to render with no trailing decimal zeros — 193.7, never 193.70');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DescriptionSurvivesHostileCharacters()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        Doc: XmlDocument;
    begin
        // [SCENARIO] Quotes, ampersands and angle brackets in a description round-trip intact as an attribute value
        CreateOrder(SalesHeader, Customer);
        AddItemLine(SalesLine, SalesHeader, 3, 50);
        SalesLine.Description := 'TRYAL 5" brass & <copper> fittings';
        SalesLine.Modify(true);

        ExportOrderToXml(SalesHeader, Doc);

        Assert.AreEqual('TRYAL 5" brass & <copper> fittings', AttributeValue(Doc, '/SalesOrder/Lines/Line[1]/@description'),
            'Expected the description attribute to reproduce the line description exactly — " & < > must survive the write/read round trip');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsCommentLinesWithoutANumber()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        Doc: XmlDocument;
        LineList: XmlNodeList;
    begin
        // [SCENARIO] A description-only line with an empty No. produces no Line element
        CreateOrder(SalesHeader, Customer);
        AddItemLine(SalesLine, SalesHeader, 1, 25);
        AddLineWithoutNo(SalesHeader, SalesLine."Line No." + 10000, SalesLine.Type::" ", 'TRYAL packing note, fragile');

        ExportOrderToXml(SalesHeader, Doc);

        Assert.IsTrue(Doc.SelectNodes('/SalesOrder/Lines/Line', LineList),
            'Expected the exported document to contain /SalesOrder/Lines/Line elements');
        Assert.AreEqual(1, LineList.Count(),
            'Expected exactly one Line element — the comment line with an empty No. must be skipped');
        Assert.AreEqual(SalesLine."No.", AttributeValue(Doc, '/SalesOrder/Lines/Line[1]/@no'),
            'Expected the single exported Line element to be the item line, not the comment line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportsNonItemLinesThatCarryANumber()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        GLSalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        Doc: XmlDocument;
        LineList: XmlNodeList;
        GLAccountNo: Code[20];
    begin
        // [SCENARIO] A G/L account line with a No. is exported — lines are never skipped by type
        CreateOrder(SalesHeader, Customer);
        AddItemLine(SalesLine, SalesHeader, 2, 40);
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        LibrarySales.CreateSalesLine(GLSalesLine, SalesHeader, GLSalesLine.Type::"G/L Account", GLAccountNo, 1);

        ExportOrderToXml(SalesHeader, Doc);

        Assert.IsTrue(Doc.SelectNodes('/SalesOrder/Lines/Line', LineList),
            'Expected the exported document to contain /SalesOrder/Lines/Line elements');
        Assert.AreEqual(2, LineList.Count(),
            'Expected two Line elements — a G/L account line carries a No. and must be exported like any other line');
        Assert.AreEqual(GLAccountNo, AttributeValue(Doc, '/SalesOrder/Lines/Line[2]/@no'),
            'Expected the second Line element to carry the G/L account line''s No. — lines are skipped by an empty No. only, never by their type');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsItemLinesWithoutANumber()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        Doc: XmlDocument;
        LineList: XmlNodeList;
    begin
        // [SCENARIO] An item-type line whose No. is still empty produces no Line element
        CreateOrder(SalesHeader, Customer);
        AddItemLine(SalesLine, SalesHeader, 2, 30);
        AddLineWithoutNo(SalesHeader, SalesLine."Line No." + 10000, SalesLine.Type::Item, 'TRYAL item not yet chosen');

        ExportOrderToXml(SalesHeader, Doc);

        Assert.IsTrue(Doc.SelectNodes('/SalesOrder/Lines/Line', LineList),
            'Expected the exported document to contain /SalesOrder/Lines/Line elements');
        Assert.AreEqual(1, LineList.Count(),
            'Expected exactly one Line element — an item-type line with an empty No. must be skipped just like a comment line');
        Assert.AreEqual(SalesLine."No.", AttributeValue(Doc, '/SalesOrder/Lines/Line[1]/@no'),
            'Expected the single exported Line element to be the finished item line, not the one with an empty No.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DocumentStartsWithAnXmlDeclaration()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        Doc: XmlDocument;
        Declaration: XmlDeclaration;
    begin
        // [SCENARIO] The exported document opens with an XML declaration stating version 1.0 and UTF-8
        CreateOrder(SalesHeader, Customer);
        AddItemLine(SalesLine, SalesHeader, 1, 10);

        ExportOrderToXml(SalesHeader, Doc);

        Assert.IsTrue(Doc.GetDeclaration(Declaration),
            'Expected the exported document to start with an XML declaration — the re-parsed document carries none');
        Assert.AreEqual('1.0', Declaration.Version(),
            'Expected the XML declaration to state version 1.0');
        Assert.AreEqual('utf-8', LowerCase(Declaration.Encoding()),
            'Expected the XML declaration to state UTF-8 encoding (any casing is accepted)');
    end;

    local procedure CreateOrder(var SalesHeader: Record "Sales Header"; var Customer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateOrderFor(SalesHeader, Customer."No.");
    end;

    local procedure CreateOrderFor(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
    end;

    local procedure CreateCustomerNamed(var Customer: Record Customer; NewName: Text[100])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, NewName);
        Customer.Modify(true);
    end;

    local procedure AddItemLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Quantity: Decimal; UnitPrice: Decimal)
    var
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure AddLineWithoutNo(SalesHeader: Record "Sales Header"; LineNo: Integer; LineType: Enum "Sales Line Type"; LineDescription: Text[100])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Type := LineType;
        SalesLine.Description := LineDescription;
        SalesLine.Insert(true);
    end;

    local procedure ExportOrderToXml(SalesHeader: Record "Sales Header"; var Doc: XmlDocument)
    var
        TempBlob: Codeunit "Temp Blob";
        SalesOrderXmlExport: Codeunit "Sales Order Xml Export";
        Assert: Codeunit Assert;
        ExportStream: OutStream;
        ResultStream: InStream;
    begin
        TempBlob.CreateOutStream(ExportStream);
        SalesOrderXmlExport.ExportOrder(SalesHeader."No.", ExportStream);
        TempBlob.CreateInStream(ResultStream);
        Assert.IsTrue(XmlDocument.ReadFrom(ResultStream, Doc),
            'Expected ExportOrder to write well-formed XML — the exported stream could not be parsed; check that special characters are escaped and the whole document reaches the OutStream');
    end;

    local procedure AttributeValue(Doc: XmlDocument; XPath: Text): Text
    var
        Assert: Codeunit Assert;
        Node: XmlNode;
    begin
        Assert.IsTrue(Doc.SelectSingleNode(XPath, Node),
            StrSubstNo('Expected the exported document to contain %1', XPath));
        exit(Node.AsXmlAttribute().Value());
    end;

    local procedure ElementText(Doc: XmlDocument; XPath: Text): Text
    var
        Assert: Codeunit Assert;
        Node: XmlNode;
    begin
        Assert.IsTrue(Doc.SelectSingleNode(XPath, Node),
            StrSubstNo('Expected the exported document to contain %1', XPath));
        exit(Node.AsXmlElement().InnerText());
    end;
}
