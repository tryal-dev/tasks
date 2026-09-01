codeunit 50900 "Dimension Injection Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        ProjectDimensionCodeTok: Label 'PROJECT', Locked = true;
        ProjectCodeFieldTok: Label 'Project Code', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedRevenueEntryCarriesTheProjectDimension()
    var
        Customer: Record Customer;
        ProjectValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] Posting an order whose header carries a Project Code puts the PROJECT pair on the revenue G/L entry
        // [GIVEN] a PROJECT dimension value and a sales order carrying it in "Project Code"
        CreateProjectDimensionValue(ProjectValue);
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithProjectCode(SalesHeader, Customer."No.", ProjectValue.Code);
        GLAccountNo := AddGLAccountLine(SalesHeader, SalesLine);

        // [WHEN] posting the order (ship and invoice)
        PostedInvoiceNo := PostOrder(SalesHeader);

        // [THEN] the revenue G/L entry points at a real dimension set that contains PROJECT = the header's Project Code
        FindRevenueEntry(GLEntry, PostedInvoiceNo, GLAccountNo);
        Assert.AreNotEqual(0, GLEntry."Dimension Set ID",
            'Expected the revenue G/L entry to point at a real dimension set (a non-zero "Dimension Set ID") once the PROJECT pair is injected');
        Assert.AreEqual(ProjectValue.Code, DimensionValueInSet(GLEntry."Dimension Set ID", ProjectDimensionCodeTok),
            'Expected the revenue G/L entry''s dimension set to contain the PROJECT dimension with the header''s "Project Code" value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerDefaultDimensionsSurviveTheInjection()
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DefaultDimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        ProjectValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] Injecting the PROJECT pair extends the line's dimension set, keeping the customer's default dimensions
        // [GIVEN] a customer with a default dimension and a sales order carrying a Project Code
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DefaultDimValue, Dimension.Code);
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DefaultDimValue.Code);
        CreateProjectDimensionValue(ProjectValue);
        CreateOrderWithProjectCode(SalesHeader, Customer."No.", ProjectValue.Code);
        GLAccountNo := AddGLAccountLine(SalesHeader, SalesLine);

        // [WHEN] posting the order (ship and invoice)
        PostedInvoiceNo := PostOrder(SalesHeader);

        // [THEN] the posted dimension set holds the customer's default dimension AND the PROJECT pair
        FindRevenueEntry(GLEntry, PostedInvoiceNo, GLAccountNo);
        Assert.AreEqual(DefaultDimValue.Code, DimensionValueInSet(GLEntry."Dimension Set ID", Dimension.Code),
            'Expected the customer''s default dimension to survive the injection — extend the line''s dimension set, never replace it');
        Assert.AreEqual(ProjectValue.Code, DimensionValueInSet(GLEntry."Dimension Set ID", ProjectDimensionCodeTok),
            'Expected the posted dimension set to also contain the PROJECT pair next to the customer''s default dimensions');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GlobalDimensionShortcutsMatchTheDimensionSet()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        Dimension: Record Dimension;
        GlobalDimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        ProjectValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] The posted entry's global-dimension shortcut fields agree with its dimension set
        // [GIVEN] PROJECT configured as global dimension 2, and a customer defaulting a value on global dimension 1
        CreateProjectDimensionValue(ProjectValue);
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Global Dimension 1 Code" = '' then begin
            LibraryDimension.CreateDimension(Dimension);
            GeneralLedgerSetup."Global Dimension 1 Code" := Dimension.Code;
        end;
        // Direct assignment on purpose: Validate would launch the Change Global Dimensions
        // machinery, which rewrites existing entries and commits — this stays rollback-safe.
        GeneralLedgerSetup."Global Dimension 2 Code" := ProjectDimensionCodeTok;
        GeneralLedgerSetup.Modify();
        LibraryDimension.CreateDimensionValue(GlobalDimValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", GlobalDimValue."Dimension Code", GlobalDimValue.Code);
        CreateOrderWithProjectCode(SalesHeader, Customer."No.", ProjectValue.Code);
        GLAccountNo := AddGLAccountLine(SalesHeader, SalesLine);

        // [WHEN] posting the order (ship and invoice)
        PostedInvoiceNo := PostOrder(SalesHeader);

        // [THEN] the shortcut fields on the revenue entry mirror what its dimension set holds for both global dimensions
        FindRevenueEntry(GLEntry, PostedInvoiceNo, GLAccountNo);
        Assert.AreEqual(ProjectValue.Code, DimensionValueInSet(GLEntry."Dimension Set ID", ProjectDimensionCodeTok),
            'Expected the revenue G/L entry''s dimension set to contain the PROJECT pair');
        Assert.AreEqual(GlobalDimValue.Code, GLEntry."Global Dimension 1 Code",
            'Expected "Global Dimension 1 Code" on the revenue G/L entry to carry the customer''s default value for global dimension 1');
        Assert.AreEqual(ProjectValue.Code, GLEntry."Global Dimension 2 Code",
            'Expected "Global Dimension 2 Code" on the revenue G/L entry to carry the injected PROJECT value — the shortcut fields must stay consistent with what the entry''s dimension set holds');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IdenticalLinesShareOneDimensionSetId()
    var
        Customer: Record Customer;
        ProjectValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        FirstSalesLine: Record "Sales Line";
        SecondSalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        GLAccountNo: Code[20];
        PostedInvoiceNo: Code[20];
        FirstSetID: Integer;
    begin
        // [SCENARIO] Two lines with identical dimensions end up pointing at one shared dimension set
        // [GIVEN] a sales order carrying a Project Code with two lines on the same G/L account
        CreateProjectDimensionValue(ProjectValue);
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithProjectCode(SalesHeader, Customer."No.", ProjectValue.Code);
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        AddLineForAccount(SalesHeader, FirstSalesLine, GLAccountNo);
        AddLineForAccount(SalesHeader, SecondSalesLine, GLAccountNo);

        // [WHEN] posting the order (ship and invoice)
        PostedInvoiceNo := PostOrder(SalesHeader);

        // [THEN] both posted invoice lines carry the PROJECT pair through one and the same set ID
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        Assert.RecordCount(SalesInvoiceLine, 2);
        SalesInvoiceLine.FindFirst();
        FirstSetID := SalesInvoiceLine."Dimension Set ID";
        Assert.AreEqual(ProjectValue.Code, DimensionValueInSet(FirstSetID, ProjectDimensionCodeTok),
            'Expected each posted line''s dimension set to contain the PROJECT pair');
        SalesInvoiceLine.FindLast();
        Assert.AreEqual(FirstSetID, SalesInvoiceLine."Dimension Set ID",
            'Expected both posted lines with identical dimensions to point at one shared "Dimension Set ID" — dimension sets are shared, never duplicated per line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankProjectCodeLeavesDimensionsUntouched()
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DefaultDimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] An order whose Project Code was never filled in posts exactly as standard BC would
        // [GIVEN] a customer with a default dimension and an order with a blank "Project Code"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DefaultDimValue, Dimension.Code);
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DefaultDimValue.Code);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        GLAccountNo := AddGLAccountLine(SalesHeader, SalesLine);

        // [WHEN] posting the order (ship and invoice)
        PostedInvoiceNo := PostOrder(SalesHeader);

        // [THEN] the posted dimension set has no PROJECT pair and still holds the customer's default dimension
        FindRevenueEntry(GLEntry, PostedInvoiceNo, GLAccountNo);
        Assert.AreEqual('', DimensionValueInSet(GLEntry."Dimension Set ID", ProjectDimensionCodeTok),
            'Expected no PROJECT pair in the posted dimension set when the header''s "Project Code" is blank');
        Assert.AreEqual(DefaultDimValue.Code, DimensionValueInSet(GLEntry."Dimension Set ID", Dimension.Code),
            'Expected the customer''s default dimension to be untouched when the header''s "Project Code" is blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankOrderAfterProjectOrderKeepsItsOwnSet()
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DefaultDimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        ProjectValue: Record "Dimension Value";
        ProjectSalesHeader: Record "Sales Header";
        BlankSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProjectGLEntry: Record "G/L Entry";
        BlankGLEntry: Record "G/L Entry";
        ProjectGLAccountNo: Code[20];
        BlankGLAccountNo: Code[20];
        ProjectInvoiceNo: Code[20];
        BlankInvoiceNo: Code[20];
    begin
        // [SCENARIO] Dimension sets are immutable: a project order must not leak its PROJECT pair into a later blank order for the same customer
        // [GIVEN] a customer with a default dimension and an already-posted order carrying a Project Code
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DefaultDimValue, Dimension.Code);
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DefaultDimValue.Code);
        CreateProjectDimensionValue(ProjectValue);
        CreateOrderWithProjectCode(ProjectSalesHeader, Customer."No.", ProjectValue.Code);
        ProjectGLAccountNo := AddGLAccountLine(ProjectSalesHeader, SalesLine);
        ProjectInvoiceNo := PostOrder(ProjectSalesHeader);

        // [WHEN] posting a second order for the same customer whose "Project Code" is blank
        LibrarySales.CreateSalesHeader(BlankSalesHeader, BlankSalesHeader."Document Type"::Order, Customer."No.");
        BlankGLAccountNo := AddGLAccountLine(BlankSalesHeader, SalesLine);
        BlankInvoiceNo := PostOrder(BlankSalesHeader);

        // [THEN] the blank order's revenue entry has no PROJECT pair and points at a different set than the project order's entry
        FindRevenueEntry(ProjectGLEntry, ProjectInvoiceNo, ProjectGLAccountNo);
        FindRevenueEntry(BlankGLEntry, BlankInvoiceNo, BlankGLAccountNo);
        Assert.AreEqual('', DimensionValueInSet(BlankGLEntry."Dimension Set ID", ProjectDimensionCodeTok),
            'Expected no PROJECT pair on the blank order''s revenue entry — injecting the pair must never mutate the shared dimension set the customer''s default dimensions live in');
        Assert.AreNotEqual(ProjectGLEntry."Dimension Set ID", BlankGLEntry."Dimension Set ID",
            'Expected the project order''s entry and the blank order''s entry to point at different dimension sets — adding a pair means finding or creating a new set, never editing the existing one in place');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ProjectCodeIsCodeTwenty()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        // [SCENARIO] The Sales Header field is declared as Code[20]
        RecRef.Open(Database::"Sales Header");
        FldRef := FieldByName(RecRef, ProjectCodeFieldTok);

        Assert.IsTrue(FldRef.Type() = FieldType::Code,
            StrSubstNo('Expected "Project Code" on Sales Header to be declared as Code[20], got a field of type %1', FldRef.Type()));
        Assert.AreEqual(20, FldRef.Length(),
            'Expected "Project Code" on Sales Header to be declared as Code[20] — its maximum length must be exactly 20');
    end;

    local procedure CreateProjectDimensionValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        if not Dimension.Get(ProjectDimensionCodeTok) then begin
            Dimension.Init();
            Dimension.Validate(Code, ProjectDimensionCodeTok);
            Dimension.Insert(true);
        end;
        LibraryDimension.CreateDimensionValue(DimensionValue, ProjectDimensionCodeTok);
    end;

    local procedure CreateOrderWithProjectCode(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ProjectCode: Code[20])
    var
        RecRef: RecordRef;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        RecRef.GetTable(SalesHeader);
        FieldByName(RecRef, ProjectCodeFieldTok).Value := ProjectCode;
        RecRef.Modify();
        RecRef.SetTable(SalesHeader);
    end;

    // The tests must compile against the unchanged starter, which has no "Project Code" yet,
    // so the field is looked up by name at run time instead of being referenced in code.
    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if FldRef.Name() = FieldName then
                exit(FldRef);
        end;
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;

    local procedure AddGLAccountLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Code[20]
    var
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        AddLineForAccount(SalesHeader, SalesLine, GLAccountNo);
        exit(GLAccountNo);
    end;

    local procedure AddLineForAccount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GLAccountNo: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 1000, 2));
        SalesLine.Modify(true);
    end;

    local procedure PostOrder(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Validate(Ship, true);
        SalesHeader.Validate(Invoice, true);
        SalesPost.SetPostingFlags(SalesHeader);
        // Suppress Sales-Post's internal commits so posting can run under AutoRollback —
        // the same switch posting preview relies on, so the whole flow stays commit-free.
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(),
            StrSubstNo('Expected posting order %1 to produce a posted sales invoice', SalesHeader."No."));
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindRevenueEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.IsTrue(GLEntry.FindFirst(),
            StrSubstNo('Expected posting to produce a G/L entry on revenue account %1 for document %2', GLAccountNo, DocumentNo));
    end;

    local procedure DimensionValueInSet(DimSetID: Integer; DimensionCode: Code[20]): Code[20]
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if DimSetEntry.Get(DimSetID, DimensionCode) then
            exit(DimSetEntry."Dimension Value Code");
        exit('');
    end;
}
