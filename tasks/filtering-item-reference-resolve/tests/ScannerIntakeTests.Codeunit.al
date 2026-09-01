codeunit 50900 "Scanner Intake Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerReferenceBeatsBarCodeAndBlankForItsOwnCustomer()
    var
        CustomerA: Record Customer;
        CustomerB: Record Customer;
        ItemA: Record Item;
        ItemB: Record Item;
        ItemBar: Record Item;
        ItemBlank: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        Any: Codeunit Any;
        VariantA: Code[10];
        UnitA: Code[10];
        RefNo: Code[50];
        DescriptionA: Text[100];
    begin
        // [SCENARIO] Four references share one number; the caller's own customer reference wins
        // [GIVEN] the same reference number for customer A, customer B, a bar code and a blank type — each pointing at a different item
        CreateCustomers(CustomerA, CustomerB);
        CreateItemWithVariantAndUnit(ItemA, VariantA, UnitA);
        CreateItem(ItemB);
        CreateItem(ItemBar);
        CreateItem(ItemBlank);
        RefNo := MakeRefNo('IR1');
        DescriptionA := CopyStr(Any.AlphabeticText(20), 1, 100);
        CreateReference(ItemA."No.", VariantA, UnitA, "Item Reference Type"::Customer, CustomerA."No.", RefNo, DescriptionA, 0D, 0D);
        CreateReference(ItemB."No.", '', '', "Item Reference Type"::Customer, CustomerB."No.", RefNo, CopyStr(Any.AlphabeticText(20), 1, 100), 0D, 0D);
        CreateReference(ItemBar."No.", '', '', "Item Reference Type"::"Bar Code", '', RefNo, CopyStr(Any.AlphabeticText(20), 1, 100), 0D, 0D);
        CreateReference(ItemBlank."No.", '', '', "Item Reference Type"::" ", '', RefNo, '', 0D, 0D);
        CreateIntakeLine(SalesLine, CustomerA."No.");

        // [WHEN] resolving the shared code for customer A's line
        ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the line carries customer A's item, variant, unit, description and the reference number
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.IsTrue(SalesLine.Type = SalesLine.Type::Item, StrSubstNo('Expected the resolved line type to be Item, got %1', SalesLine.Type));
        Assert.AreEqual(ItemA."No.", SalesLine."No.", 'Expected the caller''s own customer reference to win over the other customer''s row, the bar code and the blank type');
        Assert.AreEqual(VariantA, SalesLine."Variant Code", 'Expected the winning reference''s variant to be carried onto the line');
        Assert.AreEqual(UnitA, SalesLine."Unit of Measure Code", 'Expected the winning reference''s unit of measure to be carried onto the line');
        Assert.AreEqual(DescriptionA, SalesLine.Description, 'Expected the winning reference''s description to be carried onto the line');
        Assert.AreEqual(RefNo, SalesLine."Item Reference No.", 'Expected the line to record the scanned code in "Item Reference No."');
        Assert.IsTrue(SalesLine."Item Reference Type" = SalesLine."Item Reference Type"::Customer, StrSubstNo('Expected the line''s "Item Reference Type" to record the winning row''s type Customer, got %1', SalesLine."Item Reference Type"));
        Assert.AreEqual(CustomerA."No.", SalesLine."Item Reference Type No.", 'Expected the line''s "Item Reference Type No." to record the winning row''s customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondCustomerResolvesTheSharedCodeToTheirOwnItem()
    var
        CustomerA: Record Customer;
        CustomerB: Record Customer;
        ItemA: Record Item;
        ItemB: Record Item;
        ItemBar: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        RefNo: Code[50];
        DescriptionB: Text[100];
    begin
        // [SCENARIO] The same shared number resolves differently per caller
        // [GIVEN] the shared reference number seeded for customers A and B and as a bar code
        CreateCustomers(CustomerA, CustomerB);
        CreateItem(ItemA);
        CreateItem(ItemB);
        CreateItem(ItemBar);
        RefNo := MakeRefNo('IR2');
        DescriptionB := CopyStr(Any.AlphabeticText(20), 1, 100);
        CreateReference(ItemA."No.", '', '', "Item Reference Type"::Customer, CustomerA."No.", RefNo, CopyStr(Any.AlphabeticText(20), 1, 100), 0D, 0D);
        CreateReference(ItemB."No.", '', '', "Item Reference Type"::Customer, CustomerB."No.", RefNo, DescriptionB, 0D, 0D);
        CreateReference(ItemBar."No.", '', '', "Item Reference Type"::"Bar Code", '', RefNo, CopyStr(Any.AlphabeticText(20), 1, 100), 0D, 0D);
        CreateIntakeLine(SalesLine, CustomerB."No.");

        // [WHEN] resolving the shared code for customer B's line
        ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] customer B gets customer B's item and description
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(ItemB."No.", SalesLine."No.", 'Expected customer B''s line to resolve to customer B''s own reference, not customer A''s or the bar code''s');
        Assert.AreEqual(DescriptionB, SalesLine.Description, 'Expected customer B''s reference description on the line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BarCodeReferenceBeatsBlankTypeWhenCustomerHasNoReference()
    var
        Caller: Record Customer;
        OtherCustomer: Record Customer;
        ItemBar: Record Item;
        ItemBlank: Record Item;
        ItemOther: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        BarVariant: Code[10];
        BarUnit: Code[10];
        RefNo: Code[50];
    begin
        // [SCENARIO] With no customer row for the caller, the bar code outranks the blank type
        // [GIVEN] a code seeded as another customer's reference, a bar code and a blank type
        CreateCustomers(Caller, OtherCustomer);
        // the blank-type item gets the lower number, so a resolver that just takes the
        // first row in sort order lands on it instead of on the bar code
        CreateItem(ItemBlank);
        CreateItemWithVariantAndUnit(ItemBar, BarVariant, BarUnit);
        CreateItem(ItemOther);
        RefNo := MakeRefNo('IR3');
        CreateReference(ItemOther."No.", '', '', "Item Reference Type"::Customer, OtherCustomer."No.", RefNo, '', 0D, 0D);
        CreateReference(ItemBar."No.", BarVariant, BarUnit, "Item Reference Type"::"Bar Code", '', RefNo, '', 0D, 0D);
        CreateReference(ItemBlank."No.", '', '', "Item Reference Type"::" ", '', RefNo, '', 0D, 0D);
        CreateIntakeLine(SalesLine, Caller."No.");

        // [WHEN] resolving for a caller who owns no reference for the code
        ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the bar-code row wins — never the other customer's row, and not the blank one
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(ItemBar."No.", SalesLine."No.", 'Expected the bar-code reference to win when the caller has no customer reference — another customer''s row must never be used');
        Assert.AreEqual(BarVariant, SalesLine."Variant Code", 'Expected the bar-code reference''s variant on the line');
        Assert.AreEqual(BarUnit, SalesLine."Unit of Measure Code", 'Expected the bar-code reference''s unit of measure on the line');
        Assert.AreEqual(RefNo, SalesLine."Item Reference No.", 'Expected the line to record the scanned code in "Item Reference No."');
        Assert.IsTrue(SalesLine."Item Reference Type" = SalesLine."Item Reference Type"::"Bar Code", StrSubstNo('Expected the line''s "Item Reference Type" to record the winning row''s type Bar Code, got %1', SalesLine."Item Reference Type"));
        Assert.AreEqual('', SalesLine."Item Reference Type No.", 'Expected the line''s "Item Reference Type No." to be blank when a bar-code row wins');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankTypeReferenceIsTheLastResort()
    var
        Caller: Record Customer;
        OtherCustomer: Record Customer;
        ItemBlank: Record Item;
        ItemOther: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        RefNo: Code[50];
    begin
        // [SCENARIO] Only a blank-type row (and a foreign customer row) carry the code
        // [GIVEN] a blank-type reference and another customer's reference for the code
        CreateCustomers(Caller, OtherCustomer);
        CreateItem(ItemBlank);
        CreateItem(ItemOther);
        RefNo := MakeRefNo('IR4');
        CreateReference(ItemOther."No.", '', '', "Item Reference Type"::Customer, OtherCustomer."No.", RefNo, '', 0D, 0D);
        CreateReference(ItemBlank."No.", '', '', "Item Reference Type"::" ", '', RefNo, '', 0D, 0D);
        CreateIntakeLine(SalesLine, Caller."No.");

        // [WHEN] resolving for a caller with neither a customer row nor a bar code available
        ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the blank-type row resolves the line
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(ItemBlank."No.", SalesLine."No.", 'Expected the blank-type reference to be used as the last resort');
        Assert.AreEqual(RefNo, SalesLine."Item Reference No.", 'Expected the line to record the scanned code even when the blank-type row wins');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExpiredCustomerReferenceFallsBackToBarCode()
    var
        Caller: Record Customer;
        Unused: Record Customer;
        ItemCust: Record Item;
        ItemBar: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        RefNo: Code[50];
    begin
        // [SCENARIO] A customer reference that ended yesterday no longer wins
        // [GIVEN] the caller's customer reference expired the day before the intake date, next to an open bar code
        CreateCustomers(Caller, Unused);
        CreateItem(ItemCust);
        CreateItem(ItemBar);
        RefNo := MakeRefNo('IR5');
        CreateReference(ItemCust."No.", '', '', "Item Reference Type"::Customer, Caller."No.", RefNo, '', 0D, CalcDate('<-1D>', IntakeDate()));
        CreateReference(ItemBar."No.", '', '', "Item Reference Type"::"Bar Code", '', RefNo, '', 0D, 0D);
        CreateIntakeLine(SalesLine, Caller."No.");

        // [WHEN] resolving on the intake date
        ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the expired customer row is skipped and the bar code wins
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(ItemBar."No.", SalesLine."No.", 'Expected the customer reference with an ending date before the intake date to be ignored in favor of the bar code');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotYetStartedBarCodeReferenceIsSkipped()
    var
        Caller: Record Customer;
        Unused: Record Customer;
        ItemBar: Record Item;
        ItemBlank: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        RefNo: Code[50];
    begin
        // [SCENARIO] A bar code that only starts tomorrow does not resolve today
        // [GIVEN] a bar code starting after the intake date and an open blank-type row
        CreateCustomers(Caller, Unused);
        CreateItem(ItemBar);
        CreateItem(ItemBlank);
        RefNo := MakeRefNo('IR6');
        CreateReference(ItemBar."No.", '', '', "Item Reference Type"::"Bar Code", '', RefNo, '', CalcDate('<+1D>', IntakeDate()), 0D);
        CreateReference(ItemBlank."No.", '', '', "Item Reference Type"::" ", '', RefNo, '', 0D, 0D);
        CreateIntakeLine(SalesLine, Caller."No.");

        // [WHEN] resolving on the intake date
        ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the future bar code is skipped and the blank-type row wins
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(ItemBlank."No.", SalesLine."No.", 'Expected the bar code with a starting date after the intake date to be ignored in favor of the blank-type row');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReferenceStartingAndEndingOnTheIntakeDateIsActive()
    var
        Caller: Record Customer;
        Unused: Record Customer;
        ItemCust: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        RefNo: Code[50];
    begin
        // [SCENARIO] The date window is inclusive on both ends
        // [GIVEN] a customer reference starting and ending exactly on the intake date
        CreateCustomers(Caller, Unused);
        CreateItem(ItemCust);
        RefNo := MakeRefNo('IR7');
        CreateReference(ItemCust."No.", '', '', "Item Reference Type"::Customer, Caller."No.", RefNo, '', IntakeDate(), IntakeDate());
        CreateIntakeLine(SalesLine, Caller."No.");

        // [WHEN] resolving on that exact date
        ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the boundary-dated reference is used
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(ItemCust."No.", SalesLine."No.", 'Expected a reference starting and ending exactly on the intake date to count as active');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownCodeRaisesAnErrorContainingTheCode()
    var
        Caller: Record Customer;
        Unused: Record Customer;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        RefNo: Code[50];
    begin
        // [SCENARIO] A code no reference carries fails loudly, naming the code
        // [GIVEN] a sales line and a code that was never seeded
        CreateCustomers(Caller, Unused);
        RefNo := MakeRefNo('IR8');
        CreateIntakeLine(SalesLine, Caller."No.");

        // [WHEN] resolving the unknown code
        asserterror ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the error message contains the scanned code
        Assert.ExpectedError(RefNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FullyExpiredCodeRaisesAnErrorContainingTheCode()
    var
        Caller: Record Customer;
        Unused: Record Customer;
        ItemBar: Record Item;
        ItemBlank: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        RefNo: Code[50];
    begin
        // [SCENARIO] Rows exist for the code, but none is active on the intake date
        // [GIVEN] a bar code that expired yesterday and a blank-type row that starts tomorrow
        CreateCustomers(Caller, Unused);
        CreateItem(ItemBar);
        CreateItem(ItemBlank);
        RefNo := MakeRefNo('IR9');
        CreateReference(ItemBar."No.", '', '', "Item Reference Type"::"Bar Code", '', RefNo, '', 0D, CalcDate('<-1D>', IntakeDate()));
        CreateReference(ItemBlank."No.", '', '', "Item Reference Type"::" ", '', RefNo, '', CalcDate('<+1D>', IntakeDate()), 0D);
        CreateIntakeLine(SalesLine, Caller."No.");

        // [WHEN] resolving on the intake date
        asserterror ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the error message contains the scanned code
        Assert.ExpectedError(RefNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankReferenceDescriptionAndUnitKeepTheItemDefaults()
    var
        Caller: Record Customer;
        Unused: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ScannerIntake: Codeunit "Scanner Intake";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        RefNo: Code[50];
        ExpectedUnit: Code[10];
    begin
        // [SCENARIO] A reference that specifies nothing extra leaves the item's own defaults alone
        // [GIVEN] an item with a description of its own and a bar code carrying blank description, variant and unit
        CreateCustomers(Caller, Unused);
        CreateItem(Item);
        Item.Validate(Description, CopyStr('TRYAL ' + Any.AlphabeticText(14), 1, 100));
        Item.Modify(true);
        RefNo := MakeRefNo('IR10');
        CreateReference(Item."No.", '', '', "Item Reference Type"::"Bar Code", '', RefNo, '', 0D, 0D);
        CreateIntakeLine(SalesLine, Caller."No.");

        // [WHEN] resolving the code
        ScannerIntake.ResolveScannedCode(SalesLine, RefNo, IntakeDate());

        // [THEN] the line keeps the item's description and default unit of measure
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(Item."No.", SalesLine."No.", 'Expected the bar-code reference to resolve to its item');
        Assert.AreEqual(Item.Description, SalesLine.Description, 'Expected the item''s own description to stay on the line when the reference description is blank');
        if Item."Sales Unit of Measure" <> '' then
            ExpectedUnit := Item."Sales Unit of Measure"
        else
            ExpectedUnit := Item."Base Unit of Measure";
        Assert.AreEqual(ExpectedUnit, SalesLine."Unit of Measure Code", 'Expected the item''s default unit of measure to stay on the line when the reference unit is blank');
    end;

    local procedure CreateCustomers(var FirstCustomer: Record Customer; var SecondCustomer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(FirstCustomer);
        LibrarySales.CreateCustomer(SecondCustomer);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreateItemWithVariantAndUnit(var Item: Record Item; var VariantCode: Code[10]; var UnitCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        VariantCode := ItemVariant.Code;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        UnitCode := ItemUnitOfMeasure.Code;
    end;

    local procedure CreateReference(ItemNo: Code[20]; VariantCode: Code[10]; UnitCode: Code[10]; RefType: Enum "Item Reference Type"; RefTypeNo: Code[30]; RefNo: Code[50]; RefDescription: Text[100]; StartingDate: Date; EndingDate: Date)
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReference.Init();
        ItemReference."Item No." := ItemNo;
        ItemReference."Variant Code" := VariantCode;
        ItemReference."Unit of Measure" := UnitCode;
        ItemReference."Reference Type" := RefType;
        ItemReference."Reference Type No." := RefTypeNo;
        ItemReference."Reference No." := RefNo;
        ItemReference.Description := RefDescription;
        ItemReference."Starting Date" := StartingDate;
        ItemReference."Ending Date" := EndingDate;
        ItemReference.Insert(true);
    end;

    local procedure CreateIntakeLine(var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine.Insert(true);
    end;

    local procedure IntakeDate(): Date
    begin
        // months away from the order's own dates, so a resolver that lets the document's
        // date decide the window instead of IntakeDate resolves the wrong rows
        exit(CalcDate('<+3M>', WorkDate()));
    end;

    local procedure MakeRefNo(Tag: Text): Code[50]
    var
        Any: Codeunit Any;
    begin
        exit(CopyStr('TRYAL-' + Tag + '-' + Any.AlphanumericText(10), 1, 50));
    end;
}
