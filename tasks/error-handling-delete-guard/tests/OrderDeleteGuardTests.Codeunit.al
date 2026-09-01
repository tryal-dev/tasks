codeunit 50900 "Order Delete Guard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingAReleasedOrderFailsWithTheGuardError()
    var
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        ErrorText: Text;
    begin
        // [SCENARIO] Deleting a released sales order fails with the guard's message
        // [GIVEN] a released sales order with a line
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] deleting the order
        asserterror SalesHeader.Delete(true);

        // [THEN] the deletion errors, naming the order and the release
        ErrorText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrorText, 'is released and cannot be deleted') > 0,
            StrSubstNo('Expected the delete error to contain the phrase "is released and cannot be deleted", got: %1', ErrorText));
        Assert.IsTrue(StrPos(ErrorText, SalesHeader."No.") > 0,
            StrSubstNo('Expected the delete error to contain the order''s "No." (%1), got: %2', SalesHeader."No.", ErrorText));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BlockedDeleteLeavesTheOrderAndItsLinesIntact()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blocked deletion leaves the order and its lines untouched
        // [GIVEN] a released sales order with a line
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        // The refused delete rolls the database back to the last commit; without
        // this the order would vanish together with the rejected deletion.
        Commit();

        // [WHEN] deleting the order
        asserterror SalesHeader.Delete(true);

        // [THEN] the deletion errored and the order and its lines still exist
        Assert.ExpectedError('is released and cannot be deleted');
        Assert.IsTrue(SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No."),
            StrSubstNo('Expected released order %1 to still exist after the blocked deletion', SalesHeader."No."));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.IsFalse(SalesLine.IsEmpty(),
            StrSubstNo('Expected the sales lines of released order %1 to still exist after the blocked deletion', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnOpenOrderDeletesNormally()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] An order that was never released deletes as standard BC would
        // [GIVEN] an open sales order with a line
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] deleting the order
        SalesHeader.Delete(true);

        // [THEN] the order and its lines are gone
        Assert.IsFalse(SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No."),
            StrSubstNo('Expected open order %1 to be deleted — the guard must only block released orders', SalesHeader."No."));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.IsTrue(SalesLine.IsEmpty(),
            StrSubstNo('Expected the sales lines of open order %1 to be deleted along with the header', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AReopenedOrderDeletesNormally()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Reopening a released order lifts the guard again
        // [GIVEN] a sales order that was released and then reopened
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] deleting the order
        SalesHeader.Delete(true);

        // [THEN] the order and its lines are gone
        Assert.IsFalse(SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No."),
            StrSubstNo('Expected reopened order %1 to be deleted — a reopened order is Open again and must not be blocked', SalesHeader."No."));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.IsTrue(SalesLine.IsEmpty(),
            StrSubstNo('Expected the sales lines of reopened order %1 to be deleted along with the header', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AReleasedInvoiceIsNotBlocked()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Only orders are guarded — a released sales invoice stays deletable
        // [GIVEN] a released sales invoice with a line
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] deleting the invoice
        SalesHeader.Delete(true);

        // [THEN] the invoice is gone
        Assert.IsFalse(SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No."),
            StrSubstNo('Expected released sales invoice %1 to be deleted — the guard must only block sales orders', SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AReleasedCreditMemoIsNotBlocked()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Only orders are guarded — a released sales credit memo stays deletable
        // [GIVEN] a released sales credit memo with a line
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] deleting the credit memo
        SalesHeader.Delete(true);

        // [THEN] the credit memo is gone
        Assert.IsFalse(SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No."),
            StrSubstNo('Expected released sales credit memo %1 to be deleted — the guard must only block sales orders', SalesHeader."No."));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, Customer."No.", Item."No.", LibraryRandom.RandInt(10), '', 0D);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);
    end;
}
