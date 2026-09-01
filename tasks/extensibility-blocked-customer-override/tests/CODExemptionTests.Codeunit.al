codeunit 50900 "COD Exemption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CodApprovedFlagStoresItsValueOnTheCustomer()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        CustomerRef: RecordRef;
        CodApproved: FieldRef;
        StoredFlag: Boolean;
    begin
        // [SCENARIO] "Cash-on-Delivery Approved" is a real Boolean customer field that persists its value
        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);
        CustomerRef.GetTable(Customer);
        CodApproved := FieldByName(CustomerRef, 'Cash-on-Delivery Approved');
        Assert.AreEqual(Format(FieldType::Boolean), Format(CodApproved.Type()),
            'Expected the customer field "Cash-on-Delivery Approved" to be of type Boolean');

        // [WHEN] setting "Cash-on-Delivery Approved" and reading the customer back
        CodApproved.Validate(true);
        CustomerRef.Modify(true);
        Customer.Get(Customer."No.");
        CustomerRef.GetTable(Customer);
        StoredFlag := FieldByName(CustomerRef, 'Cash-on-Delivery Approved').Value();

        // [THEN] the flag is stored on the record
        Assert.IsTrue(StoredFlag, 'Expected "Cash-on-Delivery Approved" to store and return true after being set on the customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShipBlockedCustomerWithoutTheFlagCannotPostAShipment()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Without the flag, shipping for a Blocked::Ship customer still fails with the standard error
        // [GIVEN] a sales order, whose customer is then blocked with Ship and not COD-approved
        CreateOrderForNewCustomer(SalesHeader, Customer);
        BlockCustomer(Customer, Customer.Blocked::Ship);

        // [WHEN] posting the shipment
        asserterror ShipOrder(SalesHeader);

        // [THEN] posting errors with the standard blocked-customer message
        Assert.ExpectedError('is blocked with type');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ABlockedShipmentLeavesNoPostedShipment()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blocked shipment posting leaves no posted sales shipment behind
        // [GIVEN] a sales order, whose customer is then blocked with Ship and not COD-approved
        CreateOrderForNewCustomer(SalesHeader, Customer);
        BlockCustomer(Customer, Customer.Blocked::Ship);

        // [WHEN] posting the shipment
        asserterror ShipOrder(SalesHeader);

        // [THEN] posting errored and no posted sales shipment exists for the order
        Assert.ExpectedError('is blocked with type');
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesShipmentHeader.IsEmpty(),
            StrSubstNo('Expected no posted sales shipment for order %1 — a blocked shipment posting must leave no trace', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CodApprovedShipBlockedCustomerPostsTheShipment()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] With the flag, shipment posting succeeds for a Blocked::Ship customer
        // [GIVEN] a sales order for a COD-approved customer who is then blocked with Ship
        CreateOrderForNewCustomer(SalesHeader, Customer);
        ApproveCod(Customer);
        BlockCustomer(Customer, Customer.Blocked::Ship);

        // [WHEN] posting the shipment
        ShipOrder(SalesHeader);

        // [THEN] a posted sales shipment exists for the order
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesShipmentHeader.FindFirst(),
            StrSubstNo('Expected a posted sales shipment for order %1 — a COD-approved Blocked::Ship customer must be allowed to ship', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CodApprovedShipmentWritesItemLedgerEntries()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The exempted shipment really moves inventory, not just paperwork
        // [GIVEN] a sales order for a COD-approved customer who is then blocked with Ship
        CreateOrderForNewCustomer(SalesHeader, Customer);
        ApproveCod(Customer);
        BlockCustomer(Customer, Customer.Blocked::Ship);
        FindItemLine(SalesLine, SalesHeader);

        // [WHEN] posting the shipment
        ShipOrder(SalesHeader);

        // [THEN] a sale item ledger entry exists for the shipped item and the customer
        ItemLedgerEntry.SetRange("Item No.", SalesLine."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Source Type", ItemLedgerEntry."Source Type"::Customer);
        ItemLedgerEntry.SetRange("Source No.", Customer."No.");
        Assert.IsFalse(ItemLedgerEntry.IsEmpty(),
            StrSubstNo('Expected a sale item ledger entry for item %1 and customer %2 after the COD-approved shipment posted', SalesLine."No.", Customer."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheFlagDoesNotUnblockAnAllBlockedCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The exemption is for Blocked::Ship only — Blocked::All still stops the shipment
        // [GIVEN] a sales order for a COD-approved customer who is then blocked with All
        CreateOrderForNewCustomer(SalesHeader, Customer);
        ApproveCod(Customer);
        BlockCustomer(Customer, Customer.Blocked::All);

        // [WHEN] posting the shipment
        asserterror ShipOrder(SalesHeader);

        // [THEN] posting errors with the standard blocked-customer message and leaves no shipment
        Assert.ExpectedError('is blocked with type');
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesShipmentHeader.IsEmpty(),
            StrSubstNo('Expected no posted sales shipment for order %1 — the COD flag must not unblock a Blocked::All customer', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheFlagDoesNotUnblockAnInvoiceBlockedCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The exemption is for Blocked::Ship only — Blocked::Invoice still stops the shipment
        // [GIVEN] a sales order for a COD-approved customer who is then blocked with Invoice
        CreateOrderForNewCustomer(SalesHeader, Customer);
        ApproveCod(Customer);
        BlockCustomer(Customer, Customer.Blocked::Invoice);

        // [WHEN] posting the shipment
        asserterror ShipOrder(SalesHeader);

        // [THEN] posting errors with the standard blocked-customer message and leaves no shipment
        Assert.ExpectedError('is blocked with type');
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesShipmentHeader.IsEmpty(),
            StrSubstNo('Expected no posted sales shipment for order %1 — the COD flag must not unblock a Blocked::Invoice customer', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheFlagDoesNotUnblockAPrivacyBlockedCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A privacy-blocked customer must never ship, even as Blocked::Ship with the flag on
        // [GIVEN] a sales order for a COD-approved customer, then blocked with Ship AND privacy-blocked
        CreateOrderForNewCustomer(SalesHeader, Customer);
        ApproveCod(Customer);
        BlockCustomer(Customer, Customer.Blocked::Ship);
        // Assigned without Validate: validating "Privacy Blocked" forces Blocked to All,
        // and this test needs the hostile Ship + privacy-blocked combination.
        Customer."Privacy Blocked" := true;
        Customer.Modify(true);

        // [WHEN] posting the shipment
        asserterror ShipOrder(SalesHeader);

        // [THEN] posting errors with the standard privacy message and leaves no shipment
        Assert.ExpectedError('blocked for privacy');
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesShipmentHeader.IsEmpty(),
            StrSubstNo('Expected no posted sales shipment for order %1 — the COD flag must never ship to a privacy-blocked customer', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheFlagDoesNotAllowNewOrdersForAShipBlockedCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Document entry stays blocked — the exemption is for shipment posting only
        // [GIVEN] a COD-approved customer blocked with Ship, and an empty sales order header
        LibrarySales.CreateCustomer(Customer);
        ApproveCod(Customer);
        BlockCustomer(Customer, Customer.Blocked::Ship);
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader.Insert(true);

        // [WHEN] validating "Sell-to Customer No." with the blocked customer
        asserterror SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] the standard document-entry check still errors
        Assert.ExpectedError('is blocked with type');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheFlagDoesNotLeakIntoJournalPosting()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The journal-side blocked check is untouched by the exemption
        // [GIVEN] a general journal invoice line for a COD-approved customer who is then blocked with All
        LibrarySales.CreateCustomer(Customer);
        ApproveCod(Customer);
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
            Customer."No.", LibraryRandom.RandDecInRange(100, 1000, 2));
        BlockCustomer(Customer, Customer.Blocked::All);

        // [WHEN] posting the journal line through the standard journal posting routine
        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] the standard journal blocked check still errors
        Assert.ExpectedError('is blocked with type');
    end;

    local procedure CreateOrderForNewCustomer(var SalesHeader: Record "Sales Header"; var Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine,
            SalesHeader."Document Type"::Order, Customer."No.", Item."No.", LibraryRandom.RandInt(10), '', 0D);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);
    end;

    local procedure ShipOrder(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        SalesPost.SetPostingFlags(SalesHeader);
        // Suppress Sales-Post's internal commits so posting can run under AutoRollback —
        // the same switch posting preview relies on, so the whole flow stays commit-free.
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);
    end;

    local procedure FindItemLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure BlockCustomer(var Customer: Record Customer; BlockedType: Enum "Customer Blocked")
    begin
        Customer.Validate(Blocked, BlockedType);
        Customer.Modify(true);
    end;

    local procedure ApproveCod(var Customer: Record Customer)
    var
        CustomerRef: RecordRef;
    begin
        CustomerRef.GetTable(Customer);
        FieldByName(CustomerRef, 'Cash-on-Delivery Approved').Validate(true);
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
}
