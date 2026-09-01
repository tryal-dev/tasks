codeunit 50900 "Posted Invoice Stamp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        DealReferenceFieldTok: Label 'Deal Reference', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedOrderCarriesTheDealReference()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Any: Codeunit Any;
        DealReference: Text[30];
    begin
        // [SCENARIO] Posting a sales order stamps its Deal Reference onto the posted invoice
        // [GIVEN] a sales order carrying a generated 30-character deal reference
        DealReference := CopyStr(Any.AlphanumericText(30), 1, 30);
        CreateSalesDocumentWithDealReference(SalesHeader, SalesHeader."Document Type"::Order, DealReference);

        // [WHEN] posting the order (ship and invoice)
        PostDocument(SalesHeader);
        FindPostedInvoice(SalesInvoiceHeader, SalesHeader);

        // [THEN] the posted Sales Invoice Header carries the same reference
        Assert.AreEqual(DealReference, GetPostedDealReference(SalesInvoiceHeader),
            'Expected the posted Sales Invoice Header to carry the "Deal Reference" the sales order had at posting time');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectlyPostedInvoiceCarriesTheDealReference()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Any: Codeunit Any;
        DealReference: Text[30];
    begin
        // [SCENARIO] Posting a sales invoice document directly also stamps the posted invoice
        // [GIVEN] a sales invoice document carrying a generated deal reference
        DealReference := CopyStr(Any.AlphanumericText(20), 1, 30);
        CreateSalesDocumentWithDealReference(SalesHeader, SalesHeader."Document Type"::Invoice, DealReference);

        // [WHEN] posting the invoice
        PostDocument(SalesHeader);
        FindPostedInvoice(SalesInvoiceHeader, SalesHeader);

        // [THEN] the posted Sales Invoice Header carries the same reference
        Assert.AreEqual(DealReference, GetPostedDealReference(SalesInvoiceHeader),
            'Expected the posted Sales Invoice Header to carry the "Deal Reference" of a directly-posted sales invoice, not only of a sales order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankDealReferenceStaysBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO] A sales order without a Deal Reference posts into an invoice without one
        // [GIVEN] a sales order whose Deal Reference was never filled in
        CreateSalesDocumentWithDealReference(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] posting the order (ship and invoice)
        PostDocument(SalesHeader);
        FindPostedInvoice(SalesInvoiceHeader, SalesHeader);

        // [THEN] the posted field is blank
        Assert.AreEqual('', GetPostedDealReference(SalesInvoiceHeader),
            'Expected the posted "Deal Reference" to stay blank when the sales document''s reference was blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SalesHeaderDealReferenceIsTextThirty()
    var
        RecRef: RecordRef;
    begin
        // [SCENARIO] The Sales Header field is declared as Text[30]
        RecRef.Open(Database::"Sales Header");
        AssertTextThirty(FieldByName(RecRef, DealReferenceFieldTok), 'Sales Header');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedDealReferenceIsTextThirty()
    var
        RecRef: RecordRef;
    begin
        // [SCENARIO] The Sales Invoice Header field is declared as Text[30]
        RecRef.Open(Database::"Sales Invoice Header");
        AssertTextThirty(FieldByName(RecRef, DealReferenceFieldTok), 'Sales Invoice Header');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DealReferenceFieldsUseDifferentFieldIds()
    var
        SalesHeaderRef: RecordRef;
        SalesInvoiceHeaderRef: RecordRef;
        SalesHeaderFieldNo: Integer;
        SalesInvoiceFieldNo: Integer;
    begin
        // [SCENARIO] The two "Deal Reference" fields are declared with different field IDs,
        // so the value can only travel through the submission's posting logic — never through
        // Sales-Post copying same-numbered extension fields between the two tables.
        SalesHeaderRef.Open(Database::"Sales Header");
        SalesInvoiceHeaderRef.Open(Database::"Sales Invoice Header");
        SalesHeaderFieldNo := FieldByName(SalesHeaderRef, DealReferenceFieldTok).Number();
        SalesInvoiceFieldNo := FieldByName(SalesInvoiceHeaderRef, DealReferenceFieldTok).Number();

        Assert.AreNotEqual(SalesHeaderFieldNo, SalesInvoiceFieldNo,
            StrSubstNo('Expected the "Deal Reference" fields on Sales Header and Sales Invoice Header to have different field IDs so the value travels through your posting logic, not through accidental ID matching; both are %1', SalesHeaderFieldNo));
    end;

    local procedure AssertTextThirty(FldRef: FieldRef; TableName: Text)
    begin
        Assert.IsTrue(FldRef.Type() = FieldType::Text,
            StrSubstNo('Expected "Deal Reference" on %1 to be declared as Text[30], got a field of type %2', TableName, FldRef.Type()));
        Assert.AreEqual(30, FldRef.Length(),
            StrSubstNo('Expected "Deal Reference" on %1 to be declared as Text[30] — its maximum length must be exactly 30', TableName));
    end;

    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        Index: Integer;
    begin
        // Looked up by name at run time so the tests compile against a starter that
        // has not added the field yet, and fail with a message that names it.
        for Index := 1 to RecRef.FieldCount() do
            if RecRef.FieldIndex(Index).Name() = FieldName then
                exit(RecRef.FieldIndex(Index));
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;

    local procedure GetPostedDealReference(SalesInvoiceHeader: Record "Sales Invoice Header") DealReference: Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesInvoiceHeader);
        DealReference := FieldByName(RecRef, DealReferenceFieldTok).Value();
    end;

    local procedure PostDocument(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Validate(Ship, true);
        SalesHeader.Validate(Receive, true);
        SalesHeader.Validate(Invoice, true);
        SalesPost.SetPostingFlags(SalesHeader);
        // Suppress Sales-Post's internal commits so posting can run under AutoRollback —
        // the same switch posting preview relies on, so the whole flow stays commit-free.
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);
    end;

    local procedure FindPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.")
        else
            SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(),
            StrSubstNo('Expected posting %1 %2 to produce a posted sales invoice', SalesHeader."Document Type", SalesHeader."No."));
    end;

    local procedure CreateSalesDocumentWithDealReference(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DealReference: Text[30])
    var
        SalesLine: Record "Sales Line";
        LibraryRandom: Codeunit "Library - Random";
        RecRef: RecordRef;
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, '', '', LibraryRandom.RandIntInRange(1, 10), '', 0D);
        RecRef.GetTable(SalesHeader);
        FieldByName(RecRef, DealReferenceFieldTok).Value := DealReference;
        RecRef.Modify();
        RecRef.SetTable(SalesHeader);
    end;
}
