codeunit 50900 "Confirm When Needed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        QuestionTxt: Label 'Order %1 has no external document number. Release it anyway?', Locked = true;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AsksTheQuestionAndReleasesWhenTheUserAnswersYes()
    var
        SalesHeader: Record "Sales Header";
        OrderReleaseManager: Codeunit "Order Release Manager";
        Assert: Codeunit Assert;
        WasReleased: Boolean;
    begin
        // [SCENARIO] An order without an external document number is released after the user answers Yes to the exact question
        // [GIVEN] a sales order whose External Document No. is empty
        CreateOrder(SalesHeader, '');
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(StrSubstNo(QuestionTxt, SalesHeader."No."));
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] releasing the order and answering Yes
        WasReleased := OrderReleaseManager.ReleaseOrder(SalesHeader);
        LibraryVariableStorage.AssertEmpty();

        // [THEN] the routine returns true and the order is Released
        Assert.IsTrue(WasReleased, 'Expected ReleaseOrder to return true when the user confirms releasing an order without an external document number');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Released,
            StrSubstNo('Expected the order to be Released after the user answered Yes, got status %1', SalesHeader.Status));
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesTheOrderOpenWhenTheUserAnswersNo()
    var
        SalesHeader: Record "Sales Header";
        OrderReleaseManager: Codeunit "Order Release Manager";
        Assert: Codeunit Assert;
        WasReleased: Boolean;
    begin
        // [SCENARIO] Declining the warning question leaves the order untouched
        // [GIVEN] a sales order whose External Document No. is empty
        CreateOrder(SalesHeader, '');
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(StrSubstNo(QuestionTxt, SalesHeader."No."));
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] releasing the order and answering No
        WasReleased := OrderReleaseManager.ReleaseOrder(SalesHeader);
        LibraryVariableStorage.AssertEmpty();

        // [THEN] the routine returns false and the order is still Open
        Assert.IsFalse(WasReleased, 'Expected ReleaseOrder to return false when the user declines the question');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Open,
            StrSubstNo('Expected the order to stay Open after the user answered No, got status %1', SalesHeader.Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReleasesWithoutAskingWhenTheExternalDocumentNoIsFilled()
    var
        SalesHeader: Record "Sales Header";
        OrderReleaseManager: Codeunit "Order Release Manager";
        Assert: Codeunit Assert;
        WasReleased: Boolean;
    begin
        // [SCENARIO] The clean path releases silently — no ConfirmHandler is declared, so any dialog fails this test
        // [GIVEN] a sales order that has an external document number
        CreateOrder(SalesHeader, 'TRYAL-PO-77');

        // [WHEN] releasing the order
        WasReleased := OrderReleaseManager.ReleaseOrder(SalesHeader);

        // [THEN] the routine returns true and the order is Released, without any dialog
        Assert.IsTrue(WasReleased, 'Expected ReleaseOrder to return true for an order that already has an external document number');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.Status = SalesHeader.Status::Released,
            StrSubstNo('Expected the order with an external document number to be Released without any question, got status %1', SalesHeader.Status));
    end;

    [ConfirmHandler]
    procedure HandleConfirm(Question: Text[1024]; var Reply: Boolean)
    var
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question,
            'Expected the confirmation dialog to show exactly the question promised in the task statement, with the order number substituted');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    local procedure CreateOrder(var SalesHeader: Record "Sales Header"; ExtDocNo: Code[35])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader."External Document No." := ExtDocNo;
        SalesHeader.Modify();
    end;
}
