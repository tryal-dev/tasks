codeunit 50900 "Invoice Hold Gate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceHoldFlagStoresAndReturnsItsValue()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        CustomerRef: RecordRef;
        InvoiceHold: FieldRef;
        StoredHold: Boolean;
    begin
        // [SCENARIO] "Invoice Hold" is a real Boolean customer field that persists its value
        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);
        CustomerRef.GetTable(Customer);
        InvoiceHold := FieldByName(CustomerRef, 'Invoice Hold');
        Assert.AreEqual(Format(FieldType::Boolean), Format(InvoiceHold.Type()),
            'Expected the customer field "Invoice Hold" to be of type Boolean');

        // [WHEN] setting "Invoice Hold" and reading the customer back
        InvoiceHold.Validate(true);
        CustomerRef.Modify(true);
        Customer.Get(Customer."No.");
        CustomerRef.GetTable(Customer);
        StoredHold := FieldByName(CustomerRef, 'Invoice Hold').Value();

        // [THEN] the flag is stored on the record
        Assert.IsTrue(StoredHold, 'Expected "Invoice Hold" to store and return true after being set on the customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingAnInvoiceForAHeldCustomerFailsWithTheHoldError()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Assert: Codeunit Assert;
        ErrorText: Text;
    begin
        // [SCENARIO] Posting a sales invoice for a held customer fails with the hold message
        // [GIVEN] a customer on invoice hold with a sales invoice
        CreateHeldCustomer(Customer);
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] posting the invoice
        asserterror PostDocument(SalesHeader);

        // [THEN] posting errors, naming the customer and the hold
        ErrorText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrorText, 'is on invoice hold') > 0,
            StrSubstNo('Expected the posting error to contain the phrase "is on invoice hold", got: %1', ErrorText));
        Assert.IsTrue(StrPos(ErrorText, Customer."No.") > 0,
            StrSubstNo('Expected the posting error to contain the held customer''s "No." (%1), got: %2', Customer."No.", ErrorText));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingAnOrderForAHeldCustomerIsAlsoBlocked()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The hold blocks every sales document type, not just invoices
        // [GIVEN] a customer on invoice hold with a sales order
        CreateHeldCustomer(Customer);
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] posting the order (ship + invoice)
        asserterror PostDocument(SalesHeader);

        // [THEN] posting errors with the hold message
        Assert.ExpectedError('is on invoice hold');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingACreditMemoForAHeldCustomerIsAlsoBlocked()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The hold blocks credit memos too — a gate that filters by document type must fail
        // [GIVEN] a customer on invoice hold with a sales credit memo
        CreateHeldCustomer(Customer);
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] posting the credit memo
        asserterror PostDocument(SalesHeader);

        // [THEN] posting errors with the hold message
        Assert.ExpectedError('is on invoice hold');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlockedPostingLeavesNoPostedInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blocked posting leaves no posted sales invoice behind
        // [GIVEN] a customer on invoice hold with a sales invoice
        CreateHeldCustomer(Customer);
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] posting the invoice
        asserterror PostDocument(SalesHeader);

        // [THEN] posting errored and no posted sales invoice exists for the customer
        Assert.ExpectedError('is on invoice hold');
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        Assert.IsTrue(SalesInvoiceHeader.IsEmpty(),
            StrSubstNo('Expected no posted sales invoice for held customer %1 — a blocked posting must leave no trace', Customer."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlockedPostingLeavesNoCustomerLedgerEntries()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blocked posting writes nothing to the customer ledger
        // [GIVEN] a customer on invoice hold with a sales invoice
        CreateHeldCustomer(Customer);
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] posting the invoice
        asserterror PostDocument(SalesHeader);

        // [THEN] posting errored and the customer has no ledger entries
        Assert.ExpectedError('is on invoice hold');
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        Assert.IsTrue(CustLedgerEntry.IsEmpty(),
            StrSubstNo('Expected no customer ledger entries for held customer %1 — a blocked posting must leave no trace', Customer."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClearingTheHoldLetsTheInvoicePost()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Once the hold is cleared, posting runs as standard BC would
        // [GIVEN] a customer whose hold was set and then cleared, with a sales invoice
        CreateHeldCustomer(Customer);
        SetInvoiceHold(Customer, false);
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] posting the invoice
        PostDocument(SalesHeader);

        // [THEN] the posted invoice and the customer ledger entry exist
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(),
            StrSubstNo('Expected a posted sales invoice for sales invoice %1 after the hold was cleared — a cleared flag must not block posting', SalesHeader."No."));
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        Assert.IsFalse(CustLedgerEntry.IsEmpty(),
            StrSubstNo('Expected customer ledger entries for customer %1 after posting with the hold cleared', Customer."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerWithoutHoldPostsNormally()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The gate must not touch customers that were never put on hold
        // [GIVEN] a customer whose "Invoice Hold" was never set, with a sales invoice
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] posting the invoice
        PostDocument(SalesHeader);

        // [THEN] the posted invoice exists
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(),
            StrSubstNo('Expected a posted sales invoice for sales invoice %1 for a customer that is not on hold — the gate must only block held customers', SalesHeader."No."));
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

    local procedure CreateHeldCustomer(var Customer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        SetInvoiceHold(Customer, true);
    end;

    local procedure SetInvoiceHold(var Customer: Record Customer; Hold: Boolean)
    var
        CustomerRef: RecordRef;
    begin
        CustomerRef.GetTable(Customer);
        FieldByName(CustomerRef, 'Invoice Hold').Validate(Hold);
        CustomerRef.Modify(true);
        CustomerRef.SetTable(Customer);
    end;

    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        Assert: Codeunit Assert;
        Index: Integer;
    begin
        // Looked up by name at run time so the tests compile against a starter that
        // has not added the field yet, and fail with a message that names it.
        for Index := 1 to RecRef.FieldCount() do
            if RecRef.FieldIndex(Index).Name() = FieldName then
                exit(RecRef.FieldIndex(Index));
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;

    local procedure CreateSalesDocumentForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, CustomerNo, Item."No.", LibraryRandom.RandInt(10), '', 0D);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);
    end;
}
