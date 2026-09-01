codeunit 50900 "Vault Delete Audit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Vault] [Delete Audit]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogsEveryDocumentDeletedOneByOneWithTriggersRunning()
    var
        VaultDocument: Record "Vault Document";
    begin
        // [SCENARIO] Deleting documents one by one with Delete(true) audits each one
        // [GIVEN] a folder holding three documents
        SeedFolderWithThreeDocuments('TRYAL-A1');

        // [WHEN] deleting each document with Delete(true)
        VaultDocument.SetRange("Folder Code", 'TRYAL-A1');
        VaultDocument.FindSet();
        repeat
            VaultDocument.Delete(true);
        until VaultDocument.Next() = 0;

        // [THEN] the log holds exactly one row per document
        VerifyExactlyOneLogRowPerDocument('TRYAL-A1', 'deleting each document with Delete(true)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogsEveryDocumentDeletedOneByOneWithTriggersSuppressed()
    var
        VaultDocument: Record "Vault Document";
    begin
        // [SCENARIO] Deleting documents one by one with Delete(false) audits each one
        // [GIVEN] a folder holding three documents
        SeedFolderWithThreeDocuments('TRYAL-A2');

        // [WHEN] deleting each document with Delete(false)
        VaultDocument.SetRange("Folder Code", 'TRYAL-A2');
        VaultDocument.FindSet();
        repeat
            VaultDocument.Delete(false);
        until VaultDocument.Next() = 0;

        // [THEN] the log holds exactly one row per document
        VerifyExactlyOneLogRowPerDocument('TRYAL-A2', 'deleting each document with Delete(false)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogsEveryDocumentRemovedByABulkDelete()
    var
        VaultDocument: Record "Vault Document";
    begin
        // [SCENARIO] Deleting a whole filtered set with DeleteAll audits every row in it
        // [GIVEN] a folder holding three documents
        SeedFolderWithThreeDocuments('TRYAL-A3');

        // [WHEN] deleting the whole folder's documents with DeleteAll(false)
        VaultDocument.SetRange("Folder Code", 'TRYAL-A3');
        VaultDocument.DeleteAll(false);

        // [THEN] the log holds exactly one row per document
        VerifyExactlyOneLogRowPerDocument('TRYAL-A3', 'removing the whole filtered set with DeleteAll(false)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogsEveryDocumentRemovedByTheParentFoldersCascade()
    var
        VaultFolder: Record "Vault Folder";
        VaultDocument: Record "Vault Document";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Documents swept away by the parent folder's OnDelete cascade are audited
        // [GIVEN] a folder holding three documents
        SeedFolderWithThreeDocuments('TRYAL-A4');

        // [WHEN] deleting the parent folder
        VaultFolder.Get('TRYAL-A4');
        VaultFolder.Delete(true);

        // [THEN] the documents are gone and the log holds exactly one row per document
        VaultDocument.SetRange("Folder Code", 'TRYAL-A4');
        Assert.AreEqual(0, VaultDocument.Count(),
            'Expected deleting a "Vault Folder" to cascade into its "Vault Document" rows, leaving none behind');
        VerifyExactlyOneLogRowPerDocument('TRYAL-A4', 'deleting the parent folder so its OnDelete cascade removes them');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditRowCarriesTheVanishedDocumentsTableCodeAndTitle()
    var
        VaultDocument: Record "Vault Document";
        VaultDeleteLog: Record "Vault Delete Log";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DocumentCode: Code[20];
        DocumentTitle: Text[100];
    begin
        // [SCENARIO] The audit row repeats the deleted document's own field values
        // [GIVEN] a document with a generated code and title
        DocumentCode := CopyStr('TRYAL-A5-' + UpperCase(Any.AlphabeticText(8)), 1, MaxStrLen(DocumentCode));
        DocumentTitle := CopyStr(Any.AlphabeticText(40), 1, MaxStrLen(DocumentTitle));
        CreateFolder('TRYAL-A5');
        CreateDocument('TRYAL-A5', DocumentCode, DocumentTitle);

        // [WHEN] deleting that document
        VaultDocument.Get(DocumentCode);
        VaultDocument.Delete(false);

        // [THEN] a single log row repeats its table number, code and title
        VaultDeleteLog.SetRange("Document Code", DocumentCode);
        Assert.AreEqual(1, VaultDeleteLog.Count(),
            StrSubstNo('Expected exactly one "Vault Delete Log" row for the deleted document %1', DocumentCode));
        VaultDeleteLog.FindFirst();
        Assert.AreEqual(Database::"Vault Document", VaultDeleteLog."Table No.",
            'Expected "Table No." on the audit row to be the table number of "Vault Document"');
        Assert.AreEqual(DocumentTitle, VaultDeleteLog.Title,
            StrSubstNo('Expected Title on the audit row to be copied from the deleted document %1', DocumentCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritesNoAuditRowWhenADocumentIsModified()
    var
        VaultDocument: Record "Vault Document";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Only deletions are audited — an insert followed by a modify writes nothing
        // [GIVEN] a document that was just inserted
        CreateFolder('TRYAL-A6');
        CreateDocument('TRYAL-A6', 'TRYAL-A6-01', 'Original title');

        // [WHEN] modifying it
        VaultDocument.Get('TRYAL-A6-01');
        VaultDocument.Title := 'Renamed title';
        VaultDocument.Modify(true);

        // [THEN] the log is still empty for that document
        Assert.AreEqual(0, LogRowsFor('TRYAL-A6-01'),
            'Expected no "Vault Delete Log" row for a document that was only inserted and modified — the audit records deletions');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritesNoAuditRowWhenAFolderIsDeleted()
    var
        VaultFolder: Record "Vault Folder";
        VaultDeleteLog: Record "Vault Delete Log";
        Assert: Codeunit Assert;
        LogRowsBefore: Integer;
    begin
        // [SCENARIO] Only "Vault Document" is audited — deleting another table writes nothing
        // [GIVEN] a folder with no documents in it
        CreateFolder('TRYAL-A7');
        LogRowsBefore := VaultDeleteLog.Count();

        // [WHEN] deleting the folder
        VaultFolder.Get('TRYAL-A7');
        VaultFolder.Delete(true);

        // [THEN] no audit row was added
        Assert.AreEqual(LogRowsBefore, VaultDeleteLog.Count(),
            'Expected deleting an empty "Vault Folder" to add no "Vault Delete Log" row — only "Vault Document" is audited');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditAnswersThePlatformsDatabaseTriggerSetupQuestion()
    var
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] "Vault Delete Audit" opts into the platform's database triggers where the platform asks for them
        // The grading environment's test toolkit switches the database triggers on for every
        // table, so the opt-in cannot be observed by deleting rows — the platform's registry
        // of event subscriptions is checked instead.
        // [WHEN] looking up the audit codeunit's subscriptions to the platform's database trigger setup question
        // [THEN] one exists
        Assert.IsTrue(AuditSubscribesTo('OnAfterGetDatabaseTableTriggerSetup'),
            'Expected codeunit "Vault Delete Audit" to subscribe to the platform''s question about which database triggers a table needs (GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup) — no table gets the database delete trigger unless something answers that question, and a subscriber on the table''s own delete trigger events never does');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditListensToThePlatformsDatabaseDeleteTrigger()
    var
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] "Vault Delete Audit" takes the vanished row from the platform's database delete trigger
        // [WHEN] looking up the audit codeunit's subscriptions to the platform's database delete trigger
        // [THEN] one exists
        Assert.IsTrue(AuditSubscribesTo('OnBeforeOnDatabaseDelete|OnAfterOnDatabaseDelete'),
            'Expected codeunit "Vault Delete Audit" to subscribe to the platform''s database delete trigger (GlobalTriggerManagement.OnAfterOnDatabaseDelete) — that is where the platform hands over every row that leaves an opted-in table, whatever AL statement removed it');
    end;

    local procedure AuditSubscribesTo(PublishedFunctionFilter: Text): Boolean
    var
        EventSubscription: Record "Event Subscription";
    begin
        EventSubscription.SetRange("Subscriber Codeunit ID", Codeunit::"Vault Delete Audit");
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Codeunit);
        EventSubscription.SetRange("Publisher Object ID", Codeunit::GlobalTriggerManagement);
        EventSubscription.SetFilter("Published Function", PublishedFunctionFilter);
        exit(not EventSubscription.IsEmpty());
    end;

    local procedure CreateFolder(FolderCode: Code[20])
    var
        VaultFolder: Record "Vault Folder";
    begin
        VaultFolder.Init();
        VaultFolder."Folder Code" := FolderCode;
        VaultFolder.Description := CopyStr('Folder ' + FolderCode, 1, MaxStrLen(VaultFolder.Description));
        VaultFolder.Insert(true);
    end;

    local procedure CreateDocument(FolderCode: Code[20]; DocumentCode: Code[20]; DocumentTitle: Text[100])
    var
        VaultDocument: Record "Vault Document";
    begin
        VaultDocument.Init();
        VaultDocument."Document Code" := DocumentCode;
        VaultDocument."Folder Code" := FolderCode;
        VaultDocument.Title := DocumentTitle;
        VaultDocument.Insert(true);
    end;

    local procedure SeedFolderWithThreeDocuments(FolderCode: Code[20])
    var
        Index: Integer;
    begin
        CreateFolder(FolderCode);
        for Index := 1 to 3 do
            CreateDocument(FolderCode, DocumentCodeFor(FolderCode, Index),
                CopyStr(StrSubstNo('Document %1 of %2', Index, FolderCode), 1, 100));
    end;

    local procedure DocumentCodeFor(FolderCode: Code[20]; Index: Integer): Code[20]
    begin
        exit(CopyStr(FolderCode + '-0' + Format(Index), 1, 20));
    end;

    local procedure LogRowsFor(DocumentCode: Code[20]): Integer
    var
        VaultDeleteLog: Record "Vault Delete Log";
    begin
        VaultDeleteLog.SetRange("Document Code", DocumentCode);
        exit(VaultDeleteLog.Count());
    end;

    local procedure VerifyExactlyOneLogRowPerDocument(FolderCode: Code[20]; DeletePath: Text)
    var
        VaultDeleteLog: Record "Vault Delete Log";
        Assert: Codeunit Assert;
        Index: Integer;
    begin
        for Index := 1 to 3 do
            Assert.AreEqual(1, LogRowsFor(DocumentCodeFor(FolderCode, Index)),
                StrSubstNo('Expected exactly one "Vault Delete Log" row for document %1 after %2',
                    DocumentCodeFor(FolderCode, Index), DeletePath));

        VaultDeleteLog.SetFilter("Document Code", FolderCode + '-*');
        Assert.AreEqual(3, VaultDeleteLog.Count(),
            StrSubstNo('Expected exactly three "Vault Delete Log" rows in total for the three documents of folder %1 after %2',
                FolderCode, DeletePath));
    end;
}
