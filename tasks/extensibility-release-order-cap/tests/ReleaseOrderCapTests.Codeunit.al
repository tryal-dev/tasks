codeunit 50900 "Release Order Cap Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        MaxOrderAmountFieldTok: Label 'Max Order Amount (LCY)', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverCapOrderIsBlockedAndStaysOpen()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Cap: Decimal;
    begin
        // [SCENARIO] Releasing an order whose amount exceeds the customer's cap fails and leaves the order Open
        // [GIVEN] a customer with a generated cap and an order strictly above it
        Cap := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateCustomerWithCap(Customer, Cap);
        CreateSalesDocumentWithAmount(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", Cap + LibraryRandom.RandDecInRange(1, 100, 2));

        // [WHEN] releasing the order
        if TryRelease(SalesHeader) then
            Assert.Fail(StrSubstNo('Expected the release of order %1 to be blocked by the customer''s cap, but it went through', SalesHeader."No."));

        // [THEN] the release fails mentioning the cap field, and the order is still Open
        Assert.ExpectedError('Max Order Amount (LCY)');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Open,
            StrSubstNo('Expected the blocked order to keep Status Open, got %1', SalesHeader.Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnderCapOrderReleases()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Cap: Decimal;
    begin
        // [SCENARIO] An order below the customer's cap releases normally
        // [GIVEN] a customer with a generated cap and an order strictly below it
        Cap := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateCustomerWithCap(Customer, Cap);
        CreateSalesDocumentWithAmount(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", Cap - LibraryRandom.RandDecInRange(1, 100, 2));

        // [WHEN] releasing the order
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] the order reaches Status Released
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Released,
            StrSubstNo('Expected an order below the cap to release, got Status %1', SalesHeader.Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderExactlyAtCapReleases()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Cap: Decimal;
    begin
        // [SCENARIO] An order whose amount equals the cap exactly is not over the cap
        // [GIVEN] a customer with a generated cap and an order of exactly that amount
        Cap := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateCustomerWithCap(Customer, Cap);
        CreateSalesDocumentWithAmount(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", Cap);

        // [WHEN] releasing the order
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] the order reaches Status Released — "over the cap" is strictly greater
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Released,
            StrSubstNo('Expected an order at exactly the cap (amount excluding VAT = "Max Order Amount (LCY)") to release, got Status %1', SalesHeader.Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroCapMeansNoLimit()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] A cap of 0 means the customer has no order cap at all
        // [GIVEN] a customer whose cap is 0 and a large order
        CreateCustomerWithCap(Customer, 0);
        CreateSalesDocumentWithAmount(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", LibraryRandom.RandDecInRange(10000, 20000, 2));

        // [WHEN] releasing the order
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] the order reaches Status Released
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Released,
            StrSubstNo('Expected a "Max Order Amount (LCY)" of 0 to mean no cap, but the order got Status %1', SalesHeader.Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverCapInvoiceStillReleases()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Cap: Decimal;
    begin
        // [SCENARIO] The cap governs orders only — an invoice document above the cap still releases
        // [GIVEN] a customer with a generated cap and a sales invoice document strictly above it
        Cap := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateCustomerWithCap(Customer, Cap);
        CreateSalesDocumentWithAmount(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", Cap + LibraryRandom.RandDecInRange(1, 100, 2));

        // [WHEN] releasing the invoice document
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] it reaches Status Released — the cap must not block non-order documents
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Released,
            StrSubstNo('Expected an over-cap sales invoice document to release (the cap applies to orders only), got Status %1', SalesHeader.Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverCapOrderIsBlockedBySellToCapWhenBillToCustomerDiffers()
    var
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        Cap: Decimal;
    begin
        // [SCENARIO] The cap comes from the sell-to customer, not the bill-to customer
        // [GIVEN] a sell-to customer with a generated cap, a different bill-to customer with no cap, and an order strictly above the sell-to cap
        Cap := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateCustomerWithCap(SellToCustomer, Cap);
        CreateCustomerWithCap(BillToCustomer, 0);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Modify(true);
        AddSalesLineWithAmount(SalesHeader, Cap + LibraryRandom.RandDecInRange(1, 100, 2));

        // [WHEN] releasing the order
        if TryRelease(SalesHeader) then
            Assert.Fail(StrSubstNo('Expected the release of order %1 to be blocked by the customer''s cap, but it went through', SalesHeader."No."));

        // [THEN] the release fails against the sell-to customer's cap, and the order is still Open
        Assert.ExpectedError('Max Order Amount (LCY)');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Open,
            StrSubstNo('Expected the order to be blocked by the sell-to customer''s cap even though the bill-to customer has none, got Status %1', SalesHeader.Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverCapQuoteStillReleases()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Cap: Decimal;
    begin
        // [SCENARIO] The cap governs orders only — a quote above the cap still releases
        // [GIVEN] a customer with a generated cap and a sales quote strictly above it
        Cap := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateCustomerWithCap(Customer, Cap);
        CreateSalesDocumentWithAmount(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.", Cap + LibraryRandom.RandDecInRange(1, 100, 2));

        // [WHEN] releasing the quote
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] it reaches Status Released — the cap must not block non-order documents
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Released,
            StrSubstNo('Expected an over-cap sales quote to release (the cap applies to orders only), got Status %1', SalesHeader.Status));
    end;

    // A refused release is caught through a try function, not asserterror: an
    // error caught by asserterror rolls the transaction back to the last commit
    // and would take the order with it; a try function keeps every row.
    [TryFunction]
    local procedure TryRelease(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateCustomerWithCap(var Customer: Record Customer; Cap: Decimal)
    var
        RecRef: RecordRef;
    begin
        LibrarySales.CreateCustomer(Customer);
        RecRef.GetTable(Customer);
        FieldByName(RecRef, MaxOrderAmountFieldTok).Validate(Cap);
        RecRef.Modify(true);
        RecRef.SetTable(Customer);
    end;

    // The tests must compile against the unchanged starter, which has no "Max Order Amount (LCY)" yet,
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

    local procedure CreateSalesDocumentWithAmount(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        AddSalesLineWithAmount(SalesHeader, LineAmount);
    end;

    local procedure AddSalesLineWithAmount(var SalesHeader: Record "Sales Header"; LineAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Quantity 1 at "Unit Price" = LineAmount makes the header's Amount
        // (excluding VAT) exactly LineAmount, so the boundary tests are exact.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", LineAmount);
        SalesLine.Modify(true);
    end;
}
