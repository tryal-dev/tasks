codeunit 50900 "Order Json Import Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportsTheOrderHeaderFields()
    var
        WebOrderHeader: Record "Web Order Header";
        OrderJsonImport: Codeunit "Order Json Import";
        Assert: Codeunit Assert;
        ReturnedNo: Code[20];
    begin
        // [SCENARIO] A valid document fills every header field, including values from the nested customer object
        ReturnedNo := OrderJsonImport.ImportOrder(
            '{ "orderNo": "TRYAL-J1", "orderDate": "2026-05-20", "currencyCode": "EUR", ' +
            '"customer": { "name": "O''Brien & \"Sons\"", "email": "orders@obrien.example" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "CHAIR", "description": "Oak chair", "quantity": 1, "unitPrice": 100 } ] }');

        Assert.AreEqual('TRYAL-J1', Format(ReturnedNo), 'Expected ImportOrder to return the imported order no.');
        Assert.IsTrue(WebOrderHeader.Get('TRYAL-J1'), 'Expected a Web Order Header keyed TRYAL-J1 after importing a valid document');
        Assert.AreEqual('O''Brien & "Sons"', WebOrderHeader."Customer Name", 'Expected the nested customer.name, with its JSON escapes decoded, in "Customer Name"');
        Assert.AreEqual('orders@obrien.example', WebOrderHeader."Customer E-Mail", 'Expected the nested customer.email in "Customer E-Mail"');
        Assert.AreEqual('EUR', Format(WebOrderHeader."Currency Code"), 'Expected currencyCode in "Currency Code"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoresTheIsoOrderDateWithDayAndMonthIntact()
    var
        WebOrderHeader: Record "Web Order Header";
        OrderJsonImport: Codeunit "Order Json Import";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The ISO date 2026-03-04 lands as 4 March 2026 regardless of the server region
        OrderJsonImport.ImportOrder(
            '{ "orderNo": "TRYAL-J2", "orderDate": "2026-03-04", "customer": { "name": "Date Probe" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "A", "quantity": 1, "unitPrice": 1 } ] }');

        Assert.IsTrue(WebOrderHeader.Get('TRYAL-J2'), 'Expected a Web Order Header keyed TRYAL-J2 after importing a valid document');
        Assert.AreEqual(DMY2Date(4, 3, 2026), WebOrderHeader."Order Date",
            'Expected orderDate 2026-03-04 to be stored as 4 March 2026 — day and month must not swap with the server region');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportsEveryLineOfTheDocument()
    var
        WebOrderLine: Record "Web Order Line";
        OrderJsonImport: Codeunit "Order Json Import";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A three-line document produces exactly three lines carrying the document's values
        OrderJsonImport.ImportOrder(
            '{ "orderNo": "TRYAL-J3", "orderDate": "2026-01-15", "customer": { "name": "Line Probe" }, "lines": [' +
            '{ "lineNo": 10000, "itemNo": "DESK", "description": "Athens desk", "quantity": 2.5, "unitPrice": 149.9 },' +
            '{ "lineNo": 20000, "itemNo": "CHAIR", "description": "Oak chair", "quantity": 0.05, "unitPrice": 1234.56 },' +
            '{ "lineNo": 30000, "itemNo": "LAMP", "description": "Desk lamp", "quantity": 12, "unitPrice": 0.01 } ] }');

        WebOrderLine.SetRange("Order No.", 'TRYAL-J3');
        Assert.AreEqual(3, WebOrderLine.Count(), 'Expected exactly one Web Order Line per element of the lines array');
        VerifyLine('TRYAL-J3', 10000, 'DESK', 'Athens desk', 2.5, 149.9);
        VerifyLine('TRYAL-J3', 20000, 'CHAIR', 'Oak chair', 0.05, 1234.56);
        VerifyLine('TRYAL-J3', 30000, 'LAMP', 'Desk lamp', 12, 0.01);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportsARandomlyGeneratedDocument()
    var
        WebOrderHeader: Record "Web Order Header";
        WebOrderLine: Record "Web Order Line";
        OrderJsonImport: Codeunit "Order Json Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OrderNo: Text;
        OrderDate: Date;
        Quantity: Decimal;
        UnitPrice: Decimal;
        ReturnedNo: Code[20];
    begin
        // [SCENARIO] A document built from random values is imported faithfully — constants cannot pass
        OrderNo := 'TRYAL-J4-' + UpperCase(Any.AlphabeticText(8));
        OrderDate := Any.DateInRange(DMY2Date(1, 1, 2026), 1, 700);
        Quantity := Any.DecimalInRange(1, 500, 2);
        UnitPrice := Any.DecimalInRange(1, 2000, 2);

        ReturnedNo := OrderJsonImport.ImportOrder(StrSubstNo(
            '{ "orderNo": "%1", "orderDate": "%2", "customer": { "name": "Random Probe" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "GEN", "quantity": %3, "unitPrice": %4 } ] }',
            OrderNo, Format(OrderDate, 0, 9), Format(Quantity, 0, 9), Format(UnitPrice, 0, 9)));

        Assert.AreEqual(OrderNo, Format(ReturnedNo), 'Expected ImportOrder to return the (randomly generated) order no. from the document');
        Assert.IsTrue(WebOrderHeader.Get(OrderNo), StrSubstNo('Expected a Web Order Header keyed %1 after importing a valid document', OrderNo));
        Assert.AreEqual(OrderDate, WebOrderHeader."Order Date", 'Expected the randomly generated orderDate in "Order Date"');
        Assert.IsTrue(WebOrderLine.Get(OrderNo, 10000), StrSubstNo('Expected a Web Order Line 10000 for order %1', OrderNo));
        Assert.AreEqual(Quantity, WebOrderLine.Quantity, 'Expected the randomly generated quantity in Quantity');
        Assert.AreEqual(UnitPrice, WebOrderLine."Unit Price", 'Expected the randomly generated unitPrice in "Unit Price"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingOptionalPropertiesDefaultToBlank()
    var
        WebOrderHeader: Record "Web Order Header";
        WebOrderLine: Record "Web Order Line";
        OrderJsonImport: Codeunit "Order Json Import";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] currencyCode, customer.email and description are optional — absent means blank, not an error
        OrderJsonImport.ImportOrder(
            '{ "orderNo": "TRYAL-J5", "orderDate": "2026-02-01", "customer": { "name": "Minimal Co" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": 1, "unitPrice": 2 } ] }');

        Assert.IsTrue(WebOrderHeader.Get('TRYAL-J5'), 'Expected the import to succeed when only optional properties are missing');
        Assert.AreEqual('', Format(WebOrderHeader."Currency Code"), 'Expected a blank "Currency Code" when the document has no currencyCode');
        Assert.AreEqual('', WebOrderHeader."Customer E-Mail", 'Expected a blank "Customer E-Mail" when the customer object has no email');
        Assert.IsTrue(WebOrderLine.Get('TRYAL-J5', 10000), 'Expected the line to be imported when only optional properties are missing');
        Assert.AreEqual('', WebOrderLine.Description, 'Expected a blank Description when the line has no description');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsWhenTheTextIsNotJson()
    var
        OrderJsonImport: Codeunit "Order Json Import";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Text that is not JSON at all is rejected with a message containing "invalid JSON"
        asserterror OrderJsonImport.ImportOrder('this is definitely not a json document');

        Assert.ExpectedError('invalid JSON');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingOrderNoWhenItIsMissing()
    begin
        // [SCENARIO] A document without orderNo fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderDate": "2026-02-01", "customer": { "name": "No Order No" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": 1, "unitPrice": 1 } ] }',
            'orderNo');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingOrderDateWhenItIsMissing()
    begin
        // [SCENARIO] A document without orderDate fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J7", "customer": { "name": "No Date" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": 1, "unitPrice": 1 } ] }',
            'orderDate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingOrderDateWhenItIsNotADate()
    begin
        // [SCENARIO] An unparseable date fails with a message naming the property, not a raw conversion error
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J8", "orderDate": "sometime in spring", "customer": { "name": "Bad Date" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": 1, "unitPrice": 1 } ] }',
            'orderDate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingCustomerWhenTheObjectIsMissing()
    begin
        // [SCENARIO] A document without the customer object fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J14", "orderDate": "2026-02-01", ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": 1, "unitPrice": 1 } ] }',
            'customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingNameWhenTheCustomerHasNoName()
    begin
        // [SCENARIO] A customer object without name fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J15", "orderDate": "2026-02-01", "customer": { "email": "no.name@example.test" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": 1, "unitPrice": 1 } ] }',
            'name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingLineNoWhenALineLacksIt()
    begin
        // [SCENARIO] A line without lineNo fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J16", "orderDate": "2026-02-01", "customer": { "name": "No Line No" }, ' +
            '"lines": [ { "itemNo": "X", "quantity": 1, "unitPrice": 1 } ] }',
            'lineNo');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingLineNoWhenItIsNotAnInteger()
    begin
        // [SCENARIO] A lineNo that is not an integer fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J17", "orderDate": "2026-02-01", "customer": { "name": "Bad Line No" }, ' +
            '"lines": [ { "lineNo": "first", "itemNo": "X", "quantity": 1, "unitPrice": 1 } ] }',
            'lineNo');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingItemNoWhenALineLacksIt()
    begin
        // [SCENARIO] A line without itemNo fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J10", "orderDate": "2026-02-01", "customer": { "name": "No Item" }, ' +
            '"lines": [ { "lineNo": 10000, "quantity": 1, "unitPrice": 1 } ] }',
            'itemNo');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingQuantityWhenALineLacksIt()
    begin
        // [SCENARIO] A line without quantity fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J18", "orderDate": "2026-02-01", "customer": { "name": "No Qty" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "unitPrice": 1 } ] }',
            'quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingQuantityWhenItIsNotANumber()
    begin
        // [SCENARIO] A quantity that is not a number fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J9", "orderDate": "2026-02-01", "customer": { "name": "Bad Qty" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": "plenty", "unitPrice": 1 } ] }',
            'quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingUnitPriceWhenALineLacksIt()
    begin
        // [SCENARIO] A line without unitPrice fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J19", "orderDate": "2026-02-01", "customer": { "name": "No Price" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": 1 } ] }',
            'unitPrice');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingUnitPriceWhenItIsNotANumber()
    begin
        // [SCENARIO] A unitPrice that is not a number fails with a message naming that property and no other
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J20", "orderDate": "2026-02-01", "customer": { "name": "Bad Price" }, ' +
            '"lines": [ { "lineNo": 10000, "itemNo": "X", "quantity": 1, "unitPrice": "cheap" } ] }',
            'unitPrice');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingLinesWhenTheDocumentHasNone()
    begin
        // [SCENARIO] A document without a lines array fails with a message naming lines
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J11", "orderDate": "2026-02-01", "customer": { "name": "No Lines" } }',
            'lines');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingLinesWhenItIsNotAnArray()
    begin
        // [SCENARIO] A lines value that is not an array fails naming lines, not with a raw cast error
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J21", "orderDate": "2026-02-01", "customer": { "name": "String Lines" }, "lines": "none" }',
            'lines');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingLinesWhenTheArrayIsEmpty()
    begin
        // [SCENARIO] An order with an empty lines array is not an order — it fails naming lines
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J12", "orderDate": "2026-02-01", "customer": { "name": "Empty Lines" }, "lines": [] }',
            'lines');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsNamingQuantityWhenTheSecondLineIsBroken()
    begin
        // [SCENARIO] The broken value sits in the second line — the import must still find it and name the property
        AssertImportFailsNaming(
            '{ "orderNo": "TRYAL-J13", "orderDate": "2026-06-01", "customer": { "name": "Atomic Co" }, "lines": [' +
            '{ "lineNo": 10000, "itemNo": "GOOD", "quantity": 1, "unitPrice": 9.5 },' +
            '{ "lineNo": 20000, "itemNo": "BAD", "quantity": "plenty", "unitPrice": 1 } ] }',
            'quantity');
    end;

    local procedure AssertImportFailsNaming(OrderJson: Text; PropertyName: Text)
    var
        OrderJsonImport: Codeunit "Order Json Import";
        Assert: Codeunit Assert;
        OtherProperties: List of [Text];
        OtherProperty: Text;
    begin
        asserterror OrderJsonImport.ImportOrder(OrderJson);

        Assert.ExpectedError(PropertyName);
        OtherProperties.AddRange('orderNo', 'orderDate', 'quantity', 'itemNo', 'unitPrice');
        foreach OtherProperty in OtherProperties do
            if OtherProperty <> PropertyName then
                Assert.IsTrue(StrPos(GetLastErrorText(), OtherProperty) = 0,
                    StrSubstNo('Expected the error to name only the offending property %1, but the message also contains %2: %3',
                        PropertyName, OtherProperty, GetLastErrorText()));
    end;

    local procedure VerifyLine(OrderNo: Code[20]; LineNo: Integer; ExpectedItemNo: Text; ExpectedDescription: Text; ExpectedQuantity: Decimal; ExpectedUnitPrice: Decimal)
    var
        WebOrderLine: Record "Web Order Line";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(WebOrderLine.Get(OrderNo, LineNo),
            StrSubstNo('Expected a Web Order Line %1 for order %2 keyed by the document''s lineNo', LineNo, OrderNo));
        Assert.AreEqual(ExpectedItemNo, Format(WebOrderLine."Item No."), StrSubstNo('Expected itemNo of line %1 in "Item No."', LineNo));
        Assert.AreEqual(ExpectedDescription, WebOrderLine.Description, StrSubstNo('Expected description of line %1 in Description', LineNo));
        Assert.AreEqual(ExpectedQuantity, WebOrderLine.Quantity, StrSubstNo('Expected quantity of line %1 in Quantity', LineNo));
        Assert.AreEqual(ExpectedUnitPrice, WebOrderLine."Unit Price", StrSubstNo('Expected unitPrice of line %1 in "Unit Price"', LineNo));
    end;
}
