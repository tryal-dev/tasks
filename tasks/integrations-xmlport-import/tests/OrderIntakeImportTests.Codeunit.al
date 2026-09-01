// Grading tests. Every test drives the user's XMLport through
// Xmlport.Import(Xmlport::"Order Intake Import", InStream) — the object itself,
// never a helper procedure — and then reads the two staging tables.
codeunit 50900 "Order Intake Import Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Order Intake] [XMLport]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StagesTheOrderHeaderFromTheDocument()
    var
        Customer: Record Customer;
        Item: Record Item;
        IntakeHeader: Record "Order Intake Header";
        Assert: Codeunit Assert;
        OrderNo: Code[20];
    begin
        // [SCENARIO] A document with one order stages one header row
        // [GIVEN] a customer, an item and a one-line order
        Initialize();
        CreateCustomerWithName(Customer);
        CreateItemWithPrice(Item, 25);
        OrderNo := UniqueCode('EDI-');

        // [WHEN] the document is imported through the XMLport
        ImportDocument(Document(UniqueCode('BATCH-'), OrderXml(OrderNo, Customer."No.", LineXml(Item."No.", 2))));

        // [THEN] the header is staged with the customer of the document
        Assert.IsTrue(IntakeHeader.Get(OrderNo),
            StrSubstNo('Expected an "Order Intake Header" row with "Order No." %1 after importing the document, but none was staged', OrderNo));
        Assert.AreEqual(Customer."No.", IntakeHeader."Customer No.",
            'Expected the staged header to carry the CustomerNo of the document');
        Assert.AreEqual(Customer.Name, IntakeHeader."Customer Name",
            'Expected "Customer Name" on the staged header — the staging table derives it in the OnValidate trigger of "Customer No.", so a write that skips validation leaves it empty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StampsTheDocumentBatchIdOnEveryHeader()
    var
        Customer: Record Customer;
        Item: Record Item;
        FirstHeader: Record "Order Intake Header";
        SecondHeader: Record "Order Intake Header";
        Assert: Codeunit Assert;
        BatchId: Code[20];
        FirstOrderNo: Code[20];
        SecondOrderNo: Code[20];
    begin
        // [SCENARIO] The batch id sits once at the top of the document and belongs on every order
        // [GIVEN] a document carrying two orders under one batch id
        Initialize();
        CreateCustomerWithName(Customer);
        CreateItemWithPrice(Item, 40);
        BatchId := UniqueCode('BATCH-');
        FirstOrderNo := UniqueCode('EDI-');
        SecondOrderNo := UniqueCode('EDI-');

        // [WHEN] the document is imported
        ImportDocument(Document(BatchId,
            OrderXml(FirstOrderNo, Customer."No.", LineXml(Item."No.", 1)) +
            OrderXml(SecondOrderNo, Customer."No.", LineXml(Item."No.", 3))));

        // [THEN] both staged headers carry it
        Assert.IsTrue(FirstHeader.Get(FirstOrderNo), StrSubstNo('Expected order %1 to be staged', FirstOrderNo));
        Assert.IsTrue(SecondHeader.Get(SecondOrderNo), StrSubstNo('Expected order %1 to be staged', SecondOrderNo));
        Assert.AreEqual(BatchId, FirstHeader."Batch Id",
            'Expected the BatchId from the top of the document on the first staged header — it is never repeated inside an Order element');
        Assert.AreEqual(BatchId, SecondHeader."Batch Id",
            'Expected the same BatchId on the second staged header too');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NumbersTheStagedLinesTenThousandApart()
    var
        Customer: Record Customer;
        FirstItem: Record Item;
        SecondItem: Record Item;
        ThirdItem: Record Item;
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OrderNo: Code[20];
        FirstQuantity: Integer;
    begin
        // [SCENARIO] Line numbers are generated 10000, 20000, 30000 in document order
        // [GIVEN] one order with three lines, none of which the document numbers
        Initialize();
        CreateCustomerWithName(Customer);
        CreateItemWithPrice(FirstItem, 10);
        CreateItemWithPrice(SecondItem, 20);
        CreateItemWithPrice(ThirdItem, 30);
        OrderNo := UniqueCode('EDI-');
        FirstQuantity := Any.IntegerInRange(2, 9);

        // [WHEN] the document is imported
        ImportDocument(Document(UniqueCode('BATCH-'), OrderXml(OrderNo, Customer."No.",
            LineXml(FirstItem."No.", FirstQuantity) +
            LineXml(SecondItem."No.", 4) +
            LineXml(ThirdItem."No.", 6))));

        // [THEN] the three lines are staged in document order, 10000 apart
        Assert.AreEqual(3, LineCount(OrderNo),
            StrSubstNo('Expected exactly three staged lines for order %1. Staged: %2', OrderNo, StagedLines(OrderNo)));
        AssertStagedLine(OrderNo, 10000, FirstItem."No.", FirstQuantity, 'The first line of the order must be staged as "Line No." 10000');
        AssertStagedLine(OrderNo, 20000, SecondItem."No.", 4, 'The second line of the order must be staged as "Line No." 20000');
        AssertStagedLine(OrderNo, 30000, ThirdItem."No.", 6, 'The third line of the order must be staged as "Line No." 30000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RestartsLineNumberingForEachOrder()
    var
        Customer: Record Customer;
        FirstItem: Record Item;
        SecondItem: Record Item;
        Assert: Codeunit Assert;
        FirstOrderNo: Code[20];
        SecondOrderNo: Code[20];
    begin
        // [SCENARIO] Every order owns its line numbers, and every line belongs to its own order
        // [GIVEN] a document with two orders of two lines each
        Initialize();
        CreateCustomerWithName(Customer);
        CreateItemWithPrice(FirstItem, 15);
        CreateItemWithPrice(SecondItem, 35);
        FirstOrderNo := UniqueCode('EDI-');
        SecondOrderNo := UniqueCode('EDI-');

        // [WHEN] the document is imported
        ImportDocument(Document(UniqueCode('BATCH-'),
            OrderXml(FirstOrderNo, Customer."No.", LineXml(FirstItem."No.", 2) + LineXml(SecondItem."No.", 3)) +
            OrderXml(SecondOrderNo, Customer."No.", LineXml(SecondItem."No.", 4) + LineXml(FirstItem."No.", 5))));

        // [THEN] both orders start at 10000 and keep only their own lines
        AssertStagedLine(FirstOrderNo, 10000, FirstItem."No.", 2, 'The first line of the first order');
        AssertStagedLine(FirstOrderNo, 20000, SecondItem."No.", 3, 'The second line of the first order');
        AssertStagedLine(SecondOrderNo, 10000, SecondItem."No.", 4, 'Line numbering must restart at 10000 for the second order');
        AssertStagedLine(SecondOrderNo, 20000, FirstItem."No.", 5, 'The second line of the second order');
        Assert.AreEqual(2, LineCount(FirstOrderNo),
            StrSubstNo('Expected exactly the two lines of order %1 to carry its "Order No.". Staged: %2', FirstOrderNo, StagedLines(FirstOrderNo)));
        Assert.AreEqual(2, LineCount(SecondOrderNo),
            StrSubstNo('Expected exactly the two lines of order %1 to carry its "Order No.". Staged: %2', SecondOrderNo, StagedLines(SecondOrderNo)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsLinesWithoutAPositiveQuantity()
    var
        Customer: Record Customer;
        OrderedItem: Record Item;
        ZeroItem: Record Item;
        NegativeItem: Record Item;
        IntakeLine: Record "Order Intake Line";
        Assert: Codeunit Assert;
        OrderNo: Code[20];
    begin
        // [SCENARIO] Lines quantified 0 or less are not staged at all
        // [GIVEN] an order whose second and third lines carry a zero and a negative quantity
        Initialize();
        CreateCustomerWithName(Customer);
        CreateItemWithPrice(OrderedItem, 12);
        CreateItemWithPrice(ZeroItem, 22);
        CreateItemWithPrice(NegativeItem, 32);
        OrderNo := UniqueCode('EDI-');

        // [WHEN] the document is imported
        ImportDocument(Document(UniqueCode('BATCH-'), OrderXml(OrderNo, Customer."No.",
            LineXml(OrderedItem."No.", 7) +
            LineXml(ZeroItem."No.", 0) +
            LineXml(NegativeItem."No.", -4))));

        // [THEN] only the positive line survives
        Assert.AreEqual(1, LineCount(OrderNo),
            StrSubstNo('Expected only the one line with a positive quantity to be staged for order %1. Staged: %2', OrderNo, StagedLines(OrderNo)));
        IntakeLine.SetRange("Item No.", ZeroItem."No.");
        Assert.AreEqual(0, IntakeLine.Count(),
            StrSubstNo('The document line for item %1 has Quantity 0 and must not be staged at all', ZeroItem."No."));
        IntakeLine.SetRange("Item No.", NegativeItem."No.");
        Assert.AreEqual(0, IntakeLine.Count(),
            StrSubstNo('The document line for item %1 has a negative quantity and must not be staged at all', NegativeItem."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkippedLinesDoNotConsumeALineNumber()
    var
        Customer: Record Customer;
        FirstItem: Record Item;
        SecondItem: Record Item;
        ThirdItem: Record Item;
        FourthItem: Record Item;
        Assert: Codeunit Assert;
        OrderNo: Code[20];
    begin
        // [SCENARIO] Numbering counts staged lines, not document lines
        // [GIVEN] an order whose first and third lines are skipped
        Initialize();
        CreateCustomerWithName(Customer);
        CreateItemWithPrice(FirstItem, 11);
        CreateItemWithPrice(SecondItem, 21);
        CreateItemWithPrice(ThirdItem, 31);
        CreateItemWithPrice(FourthItem, 41);
        OrderNo := UniqueCode('EDI-');

        // [WHEN] the document is imported
        ImportDocument(Document(UniqueCode('BATCH-'), OrderXml(OrderNo, Customer."No.",
            LineXml(FirstItem."No.", 0) +
            LineXml(SecondItem."No.", 5) +
            LineXml(ThirdItem."No.", 0) +
            LineXml(FourthItem."No.", 8))));

        // [THEN] the two surviving lines are numbered 10000 and 20000
        Assert.AreEqual(2, LineCount(OrderNo),
            StrSubstNo('Expected the two positive lines of order %1 to be staged. Staged: %2', OrderNo, StagedLines(OrderNo)));
        AssertStagedLine(OrderNo, 10000, SecondItem."No.", 5,
            'The first staged line must be "Line No." 10000 even though the document line before it was skipped');
        AssertStagedLine(OrderNo, 20000, FourthItem."No.", 8,
            'The second staged line must be "Line No." 20000 — a skipped line in between must not burn a number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FillsLineDetailsFromTheItem()
    var
        Customer: Record Customer;
        Item: Record Item;
        IntakeLine: Record "Order Intake Line";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OrderNo: Code[20];
        UnitPrice: Decimal;
        Quantity: Integer;
    begin
        // [SCENARIO] A staged line carries the values the staging table derives from the item
        // [GIVEN] an item with a generated price and an order line for it
        Initialize();
        CreateCustomerWithName(Customer);
        UnitPrice := Any.IntegerInRange(10, 90);
        Quantity := Any.IntegerInRange(2, 9);
        CreateItemWithPrice(Item, UnitPrice);
        OrderNo := UniqueCode('EDI-');

        // [WHEN] the document is imported
        ImportDocument(Document(UniqueCode('BATCH-'), OrderXml(OrderNo, Customer."No.", LineXml(Item."No.", Quantity))));

        // [THEN] description, price and amount are on the staged line
        Assert.IsTrue(IntakeLine.Get(OrderNo, 10000),
            StrSubstNo('Expected a staged line 10000 on order %1. Staged: %2', OrderNo, StagedLines(OrderNo)));
        Assert.AreEqual(Quantity, IntakeLine.Quantity, 'Expected the Quantity of the document on the staged line');
        Assert.AreEqual(Item.Description, IntakeLine.Description,
            'Expected Description to be derived from the item — the staging table fills it in the OnValidate trigger of "Item No.", so a write that skips validation leaves it empty');
        Assert.AreEqual(UnitPrice, IntakeLine."Unit Price",
            'Expected "Unit Price" to be derived from the item — the document never sends a price');
        Assert.AreEqual(Quantity * UnitPrice, IntakeLine.Amount,
            'Expected Amount = Quantity * "Unit Price", which the staging table computes while validating');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReimportingAnOrderUpdatesTheStagedRows()
    var
        FirstCustomer: Record Customer;
        SecondCustomer: Record Customer;
        Item: Record Item;
        IntakeHeader: Record "Order Intake Header";
        IntakeLine: Record "Order Intake Line";
        Assert: Codeunit Assert;
        OrderNo: Code[20];
        SecondBatchId: Code[20];
    begin
        // [SCENARIO] The partner re-sends a corrected order under the same order number
        // [GIVEN] the order already staged from an earlier document
        Initialize();
        CreateCustomerWithName(FirstCustomer);
        CreateCustomerWithName(SecondCustomer);
        CreateItemWithPrice(Item, 50);
        OrderNo := UniqueCode('EDI-');
        SecondBatchId := UniqueCode('BATCH-');
        ImportDocument(Document(UniqueCode('BATCH-'), OrderXml(OrderNo, FirstCustomer."No.", LineXml(Item."No.", 2))));

        // [WHEN] the corrected version of the same order is imported
        ImportDocument(Document(SecondBatchId, OrderXml(OrderNo, SecondCustomer."No.", LineXml(Item."No.", 6))));

        // [THEN] the staged order is updated in place — not duplicated, not rejected
        Assert.AreEqual(1, IntakeHeader.Count(),
            'Expected the re-sent order to update the staged header instead of adding a second one');
        Assert.IsTrue(IntakeHeader.Get(OrderNo), StrSubstNo('Expected order %1 to still be staged after the second import', OrderNo));
        Assert.AreEqual(SecondCustomer."No.", IntakeHeader."Customer No.",
            'Expected the staged header to carry the customer of the second document');
        Assert.AreEqual(SecondBatchId, IntakeHeader."Batch Id",
            'Expected the staged header to carry the batch id of the second document');
        Assert.AreEqual(1, LineCount(OrderNo),
            StrSubstNo('Expected the re-sent line to replace the staged one, not to be added next to it. Staged: %1', StagedLines(OrderNo)));
        Assert.IsTrue(IntakeLine.Get(OrderNo, 10000),
            StrSubstNo('Expected the re-sent line to be staged as line 10000 again. Staged: %1', StagedLines(OrderNo)));
        Assert.AreEqual(6, IntakeLine.Quantity, 'Expected the quantity of the second document on the staged line');
        Assert.AreEqual(300, IntakeLine.Amount, 'Expected Amount to be recomputed from the new quantity (6 x 50)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StagesEveryOrderInTheDocument()
    var
        FirstCustomer: Record Customer;
        SecondCustomer: Record Customer;
        Item: Record Item;
        IntakeHeader: Record "Order Intake Header";
        Assert: Codeunit Assert;
        OrderNos: array[3] of Code[20];
        Index: Integer;
    begin
        // [SCENARIO] Every Order element of the document becomes a staged header
        // [GIVEN] a document with three orders for two different customers
        Initialize();
        CreateCustomerWithName(FirstCustomer);
        CreateCustomerWithName(SecondCustomer);
        CreateItemWithPrice(Item, 18);
        for Index := 1 to 3 do
            OrderNos[Index] := UniqueCode('EDI-');

        // [WHEN] the document is imported
        ImportDocument(Document(UniqueCode('BATCH-'),
            OrderXml(OrderNos[1], FirstCustomer."No.", LineXml(Item."No.", 1)) +
            OrderXml(OrderNos[2], SecondCustomer."No.", LineXml(Item."No.", 2)) +
            OrderXml(OrderNos[3], FirstCustomer."No.", LineXml(Item."No.", 3))));

        // [THEN] all three orders are staged, each with its own customer
        Assert.AreEqual(3, IntakeHeader.Count(), 'Expected one staged header per Order element of the document');
        for Index := 1 to 3 do
            Assert.IsTrue(IntakeHeader.Get(OrderNos[Index]),
                StrSubstNo('Expected order no. %1 of the document (%2) to be staged', Index, OrderNos[Index]));
        IntakeHeader.Get(OrderNos[2]);
        Assert.AreEqual(SecondCustomer."No.", IntakeHeader."Customer No.",
            'Expected the middle order to keep its own customer — each Order element carries its own CustomerNo');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineTableDerivesOnlyThroughValidation()
    var
        Item: Record Item;
        IntakeLine: Record "Order Intake Line";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The given line table is unchanged: a raw write derives nothing
        // [GIVEN] an item with a price
        Initialize();
        CreateItemWithPrice(Item, 75);

        // [WHEN] a line is written field by field, without validating anything
        IntakeLine.Init();
        IntakeLine."Order No." := 'TRYAL-RAW';
        IntakeLine."Line No." := 10000;
        IntakeLine."Item No." := Item."No.";
        IntakeLine.Quantity := 4;
        IntakeLine.Insert(true);

        // [THEN] the derived fields stay empty — the derivation lives in the OnValidate triggers
        IntakeLine.Get('TRYAL-RAW', 10000);
        Assert.AreEqual('', IntakeLine.Description,
            'Expected Description to stay empty on an unvalidated write — leave "Order Intake Line" exactly as it ships, deriving values only in its OnValidate triggers');
        Assert.AreEqual(0, IntakeLine.Amount,
            'Expected Amount to stay 0 on an unvalidated write — leave "Order Intake Line" exactly as it ships, deriving values only in its OnValidate triggers');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HeaderTableDerivesOnlyThroughValidation()
    var
        Customer: Record Customer;
        IntakeHeader: Record "Order Intake Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The given header table is unchanged: a raw write derives nothing
        // [GIVEN] a customer with a name
        Initialize();
        CreateCustomerWithName(Customer);

        // [WHEN] a header is written field by field, without validating anything
        IntakeHeader.Init();
        IntakeHeader."Order No." := 'TRYAL-RAWH';
        IntakeHeader."Customer No." := Customer."No.";
        IntakeHeader.Insert(true);

        // [THEN] the derived field stays empty — the derivation lives in the OnValidate trigger
        IntakeHeader.Get('TRYAL-RAWH');
        Assert.AreEqual('', IntakeHeader."Customer Name",
            'Expected "Customer Name" to stay empty on an unvalidated write — leave "Order Intake Header" exactly as it ships, deriving the name only in the OnValidate trigger of "Customer No."');
    end;

    local procedure Initialize()
    var
        IntakeHeader: Record "Order Intake Header";
        IntakeLine: Record "Order Intake Line";
    begin
        IntakeHeader.DeleteAll();
        IntakeLine.DeleteAll();
    end;

    local procedure ImportDocument(DocumentXml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        DocumentOutStream: OutStream;
        DocumentInStream: InStream;
    begin
        TempBlob.CreateOutStream(DocumentOutStream, TextEncoding::UTF8);
        DocumentOutStream.WriteText(DocumentXml);
        TempBlob.CreateInStream(DocumentInStream, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"Order Intake Import", DocumentInStream);
    end;

    local procedure Document(BatchId: Code[20]; OrdersXml: Text): Text
    begin
        exit(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<OrderIntake>' +
            '<BatchId>' + BatchId + '</BatchId>' +
            OrdersXml +
            '</OrderIntake>');
    end;

    local procedure OrderXml(OrderNo: Code[20]; CustomerNo: Code[20]; LinesXml: Text): Text
    begin
        exit(
            '<Order>' +
            '<OrderNo>' + OrderNo + '</OrderNo>' +
            '<CustomerNo>' + CustomerNo + '</CustomerNo>' +
            LinesXml +
            '</Order>');
    end;

    local procedure LineXml(ItemNo: Code[20]; Quantity: Integer): Text
    begin
        exit(
            '<Line>' +
            '<ItemNo>' + ItemNo + '</ItemNo>' +
            '<Quantity>' + Format(Quantity, 0, 9) + '</Quantity>' +
            '</Line>');
    end;

    local procedure CreateCustomerWithName(var Customer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := CopyStr('TRYAL ' + UniqueText(), 1, MaxStrLen(Customer.Name));
        Customer.Modify(true);
    end;

    local procedure CreateItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Description := CopyStr('TRYAL ' + UniqueText(), 1, MaxStrLen(Item.Description));
        Item."Unit Price" := UnitPrice;
        Item.Modify(true);
    end;

    // Codes have to be unique across calls inside one test; Any restarts its
    // sequence for every codeunit instance, so uniqueness comes from a GUID.
    local procedure UniqueCode(Prefix: Text): Code[20]
    begin
        exit(CopyStr(Prefix + UniqueText(), 1, 20));
    end;

    local procedure UniqueText(): Text
    begin
        exit(UpperCase(DelChr(Format(CreateGuid()), '=', '{}-')));
    end;

    local procedure LineCount(OrderNo: Code[20]): Integer
    var
        IntakeLine: Record "Order Intake Line";
    begin
        IntakeLine.SetRange("Order No.", OrderNo);
        exit(IntakeLine.Count());
    end;

    local procedure AssertStagedLine(OrderNo: Code[20]; LineNo: Integer; ExpectedItemNo: Code[20]; ExpectedQuantity: Decimal; Context: Text)
    var
        IntakeLine: Record "Order Intake Line";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(IntakeLine.Get(OrderNo, LineNo),
            StrSubstNo('%1: no "Order Intake Line" with "Order No." %2 and "Line No." %3 exists. Staged for that order: %4',
                Context, OrderNo, LineNo, StagedLines(OrderNo)));
        Assert.AreEqual(ExpectedItemNo, IntakeLine."Item No.",
            StrSubstNo('%1: line %2 of order %3 carries the wrong item. Staged for that order: %4',
                Context, LineNo, OrderNo, StagedLines(OrderNo)));
        Assert.AreEqual(ExpectedQuantity, IntakeLine.Quantity,
            StrSubstNo('%1: line %2 of order %3 carries the wrong quantity', Context, LineNo, OrderNo));
    end;

    local procedure StagedLines(OrderNo: Code[20]): Text
    var
        IntakeLine: Record "Order Intake Line";
        Staged: Text;
    begin
        IntakeLine.SetRange("Order No.", OrderNo);
        if IntakeLine.FindSet() then
            repeat
                Staged += StrSubstNo('[%1 = %2 x %3] ', IntakeLine."Line No.", IntakeLine."Item No.", IntakeLine.Quantity);
            until IntakeLine.Next() = 0;
        if Staged = '' then
            exit('no lines at all');
        exit(Staged);
    end;
}
