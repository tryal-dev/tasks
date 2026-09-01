codeunit 50900 "Document Lifecycle Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReleaseMovesAnOpenDocumentToReleased()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Release on an open document moves it to Released
        CreateDocument(LifecycleDocument, 'LIFE-T01', "Lifecycle Document Status"::Open, Any.DecimalInRange(1, 1000, 2));

        DocumentLifecycle.Release(LifecycleDocument);

        AssertParameterStatus(LifecycleDocument, "Lifecycle Document Status"::Released, 'Release');
        AssertStoredStatus('LIFE-T01', "Lifecycle Document Status"::Released, 'Release');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReopenMovesAReleasedDocumentBackToOpen()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Reopen on a released document moves it back to Open
        CreateDocument(LifecycleDocument, 'LIFE-T02', "Lifecycle Document Status"::Released, Any.DecimalInRange(1, 1000, 2));

        DocumentLifecycle.Reopen(LifecycleDocument);

        AssertParameterStatus(LifecycleDocument, "Lifecycle Document Status"::Open, 'Reopen');
        AssertStoredStatus('LIFE-T02', "Lifecycle Document Status"::Open, 'Reopen');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostMovesAReleasedDocumentToPosted()
    var
        LifecycleDocument: Record "Lifecycle Document";
        StoredDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OriginalWorkDate: Date;
        PinnedWorkDate: Date;
    begin
        // [SCENARIO] Post on a released document moves it to Posted and stamps the work date
        CreateDocument(LifecycleDocument, 'LIFE-T03', "Lifecycle Document Status"::Released, Any.DecimalInRange(1, 1000, 2));
        // Pin the work date away from today, so a solution stamping Today() cannot pass
        OriginalWorkDate := WorkDate();
        PinnedWorkDate := CalcDate('<-1M>', Today());
        WorkDate(PinnedWorkDate);

        DocumentLifecycle.Post(LifecycleDocument);

        WorkDate(OriginalWorkDate);
        AssertParameterStatus(LifecycleDocument, "Lifecycle Document Status"::Posted, 'Post');
        AssertStoredStatus('LIFE-T03', "Lifecycle Document Status"::Posted, 'Post');
        StoredDocument.Get('LIFE-T03');
        Assert.AreEqual(PinnedWorkDate, StoredDocument."Posted On",
            'Expected Post to stamp "Posted On" with the session''s work date (WorkDate), not today''s calendar date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReleasingAnAlreadyReleasedDocumentFails()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Release on a released document is rejected
        CreateDocument(LifecycleDocument, 'LIFE-T04', "Lifecycle Document Status"::Released, Any.DecimalInRange(1, 1000, 2));
        // The refused call rolls the database back to the last commit; without
        // this the document itself would vanish together with the rejected change.
        Commit();

        asserterror DocumentLifecycle.Release(LifecycleDocument);

        AssertErrorContains('Status must be equal to ''Open''');
        AssertStoredStatus('LIFE-T04', "Lifecycle Document Status"::Released, 'a failed Release');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReleasingAPostedDocumentFails()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Release on a posted document is rejected — posted is final
        CreateDocument(LifecycleDocument, 'LIFE-T05', "Lifecycle Document Status"::Posted, Any.DecimalInRange(1, 1000, 2));
        Commit();

        asserterror DocumentLifecycle.Release(LifecycleDocument);

        AssertErrorContains('Status must be equal to ''Open''');
        AssertStoredStatus('LIFE-T05', "Lifecycle Document Status"::Posted, 'a failed Release');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReopeningAnOpenDocumentFails()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Reopen on an open document is rejected
        CreateDocument(LifecycleDocument, 'LIFE-T06', "Lifecycle Document Status"::Open, Any.DecimalInRange(1, 1000, 2));
        Commit();

        asserterror DocumentLifecycle.Reopen(LifecycleDocument);

        AssertErrorContains('Status must be equal to ''Released''');
        AssertStoredStatus('LIFE-T06', "Lifecycle Document Status"::Open, 'a failed Reopen');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReopeningAPostedDocumentFails()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Reopen on a posted document is rejected — posted is final
        CreateDocument(LifecycleDocument, 'LIFE-T07', "Lifecycle Document Status"::Posted, Any.DecimalInRange(1, 1000, 2));
        Commit();

        asserterror DocumentLifecycle.Reopen(LifecycleDocument);

        AssertErrorContains('Status must be equal to ''Released''');
        AssertStoredStatus('LIFE-T07', "Lifecycle Document Status"::Posted, 'a failed Reopen');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PostingAnOpenDocumentFails()
    var
        LifecycleDocument: Record "Lifecycle Document";
        StoredDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] Post straight from Open is rejected — the document must be released first
        CreateDocument(LifecycleDocument, 'LIFE-T08', "Lifecycle Document Status"::Open, Any.DecimalInRange(1, 1000, 2));
        Commit();

        asserterror DocumentLifecycle.Post(LifecycleDocument);

        AssertErrorContains('Status must be equal to ''Released''');
        AssertStoredStatus('LIFE-T08', "Lifecycle Document Status"::Open, 'a failed Post');
        StoredDocument.Get('LIFE-T08');
        Assert.AreEqual(0D, StoredDocument."Posted On",
            'Expected a failed Post to leave "Posted On" empty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PostingAPostedDocumentFails()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Post on an already posted document is rejected — posted is final
        CreateDocument(LifecycleDocument, 'LIFE-T09', "Lifecycle Document Status"::Posted, Any.DecimalInRange(1, 1000, 2));
        Commit();

        asserterror DocumentLifecycle.Post(LifecycleDocument);

        AssertErrorContains('Status must be equal to ''Released''');
        AssertStoredStatus('LIFE-T09', "Lifecycle Document Status"::Posted, 'a failed Post');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReleasingAZeroAmountDocumentFails()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
    begin
        // [SCENARIO] An open document with Amount = 0 does not release
        CreateDocument(LifecycleDocument, 'LIFE-T10', "Lifecycle Document Status"::Open, 0);
        Commit();

        asserterror DocumentLifecycle.Release(LifecycleDocument);

        AssertErrorContains('Amount');
        AssertErrorContains('must have a value');
        AssertStoredStatus('LIFE-T10', "Lifecycle Document Status"::Open, 'a failed Release');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AReopenedDocumentCanStillBePosted()
    var
        LifecycleDocument: Record "Lifecycle Document";
        DocumentLifecycle: Codeunit "Document Lifecycle";
        Any: Codeunit Any;
    begin
        // [SCENARIO] The open/released cycle is repeatable and still ends in Posted
        // [GIVEN] a document that was released, reopened, and released again
        CreateDocument(LifecycleDocument, 'LIFE-T11', "Lifecycle Document Status"::Open, Any.DecimalInRange(1, 1000, 2));
        DocumentLifecycle.Release(LifecycleDocument);
        DocumentLifecycle.Reopen(LifecycleDocument);
        DocumentLifecycle.Release(LifecycleDocument);

        // [WHEN] posting it
        DocumentLifecycle.Post(LifecycleDocument);

        // [THEN] it is Posted
        AssertStoredStatus('LIFE-T11', "Lifecycle Document Status"::Posted, 'Post after a reopen cycle');
    end;

    local procedure CreateDocument(var LifecycleDocument: Record "Lifecycle Document"; DocumentNo: Code[20]; DocumentStatus: Enum "Lifecycle Document Status"; DocumentAmount: Decimal)
    begin
        LifecycleDocument.Init();
        LifecycleDocument."No." := DocumentNo;
        LifecycleDocument.Amount := DocumentAmount;
        LifecycleDocument.Status := DocumentStatus;
        LifecycleDocument.Insert();
    end;

    local procedure AssertParameterStatus(LifecycleDocument: Record "Lifecycle Document"; ExpectedStatus: Enum "Lifecycle Document Status"; ActionName: Text)
    var
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(Format(ExpectedStatus), Format(LifecycleDocument.Status),
            StrSubstNo('Expected %1 to leave the var parameter it was handed with status %2', ActionName, ExpectedStatus));
    end;

    local procedure AssertStoredStatus(DocumentNo: Code[20]; ExpectedStatus: Enum "Lifecycle Document Status"; ActionName: Text)
    var
        StoredDocument: Record "Lifecycle Document";
        Assert: Codeunit Assert;
    begin
        StoredDocument.Get(DocumentNo);
        Assert.AreEqual(Format(ExpectedStatus), Format(StoredDocument.Status),
            StrSubstNo('Expected document %1 to have status %2 in the database after %3', DocumentNo, ExpectedStatus, ActionName));
    end;

    local procedure AssertErrorContains(Fragment: Text)
    var
        Assert: Codeunit Assert;
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains(LowerCase(Fragment)),
            StrSubstNo('Expected the lifecycle error to contain "%1", got: %2', Fragment, ActualError));
    end;
}
