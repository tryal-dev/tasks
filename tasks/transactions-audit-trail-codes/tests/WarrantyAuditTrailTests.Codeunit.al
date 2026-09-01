// [FEATURE] [Audit Codes] [Source Code] [Reason Code]
codeunit 50900 "Warranty Audit Trail Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        WarrantySourceCodeFieldTok: Label 'Warranty Claim Source Code', Locked = true;
        WarrantyReasonCodeFieldTok: Label 'Warranty Claim Reason Code', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitAuditCodesCreatesTheMissingSetupRow()
    var
        SourceCodeSetup: Record "Source Code Setup";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
    begin
        // [SCENARIO] The Source Code Setup singleton is created the first time the audit codes are initialized
        // [GIVEN] a company whose "Source Code Setup" record does not exist
        SourceCodeSetup.DeleteAll();

        // [WHEN] initializing the audit codes
        WarrantyClaimPosting.InitAuditCodes();

        // [THEN] the singleton record exists
        Assert.IsTrue(SourceCodeSetup.Get(),
            'Expected InitAuditCodes to create the "Source Code Setup" record (the singleton with the blank primary key) in a company that has none');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitAuditCodesSeedsTheWarrantySourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
    begin
        // [SCENARIO] Initializing seeds the WARRANTY source code and points the setup at it
        // [GIVEN] a company with no setup record and no WARRANTY source code
        SourceCodeSetup.DeleteAll();
        if SourceCode.Get(SeededSourceCode()) then
            SourceCode.Delete();

        // [WHEN] initializing the audit codes
        WarrantyClaimPosting.InitAuditCodes();

        // [THEN] the seeded code exists as a real "Source Code" record and the setup points at it
        SourceCodeSetup.Get();
        Assert.AreEqual(SeededSourceCode(), GetWarrantySourceCode(SourceCodeSetup),
            'Expected InitAuditCodes to store the seeded code in "Warranty Claim Source Code" on Source Code Setup');
        Assert.IsTrue(SourceCode.Get(SeededSourceCode()),
            StrSubstNo('Expected InitAuditCodes to create the "Source Code" record %1 — the setup field may only point at a code that really exists', SeededSourceCode()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitAuditCodesSeedsTheWarrantyReasonCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        ReasonCode: Record "Reason Code";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
    begin
        // [SCENARIO] Initializing seeds the WARRCLAIM reason code and points the setup at it
        // [GIVEN] a company with no setup record and no WARRCLAIM reason code
        SourceCodeSetup.DeleteAll();
        if ReasonCode.Get(SeededReasonCode()) then
            ReasonCode.Delete();

        // [WHEN] initializing the audit codes
        WarrantyClaimPosting.InitAuditCodes();

        // [THEN] the seeded code exists as a real "Reason Code" record and the setup points at it
        SourceCodeSetup.Get();
        Assert.AreEqual(SeededReasonCode(), GetWarrantyReasonCode(SourceCodeSetup),
            'Expected InitAuditCodes to store the seeded code in "Warranty Claim Reason Code" on Source Code Setup');
        Assert.IsTrue(ReasonCode.Get(SeededReasonCode()),
            StrSubstNo('Expected InitAuditCodes to create the "Reason Code" record %1 — the setup field may only point at a code that really exists', SeededReasonCode()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitAuditCodesKeepsCodesThatAreAlreadySet()
    var
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        ReasonCode: Record "Reason Code";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
    begin
        // [SCENARIO] A setup that was customized survives a second initialization
        // [GIVEN] a setup record pointing at codes of the implementer's own choosing
        LibraryERM.CreateSourceCode(SourceCode);
        LibraryERM.CreateReasonCode(ReasonCode);
        SetWarrantyCodes(SourceCode.Code, ReasonCode.Code);

        // [WHEN] initializing the audit codes again
        WarrantyClaimPosting.InitAuditCodes();

        // [THEN] both codes are untouched
        SourceCodeSetup.Get();
        Assert.AreEqual(SourceCode.Code, GetWarrantySourceCode(SourceCodeSetup),
            'Expected InitAuditCodes to leave a "Warranty Claim Source Code" that is already filled in alone — it may only fill a blank field');
        Assert.AreEqual(ReasonCode.Code, GetWarrantyReasonCode(SourceCodeSetup),
            'Expected InitAuditCodes to leave a "Warranty Claim Reason Code" that is already filled in alone — it may only fill a blank field');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitAuditCodesSeedsBlankCodesOnAnExistingSetupRow()
    var
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        ReasonCode: Record "Reason Code";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
    begin
        // [SCENARIO] A company that already has the setup record still gets both audit codes seeded
        // [GIVEN] an existing setup record whose two warranty fields are blank, and neither seeded code in place
        SetWarrantyCodes('', '');
        if SourceCode.Get(SeededSourceCode()) then
            SourceCode.Delete();
        if ReasonCode.Get(SeededReasonCode()) then
            ReasonCode.Delete();

        // [WHEN] initializing the audit codes
        WarrantyClaimPosting.InitAuditCodes();

        // [THEN] both fields hold the seeded codes and both codes exist as records
        SourceCodeSetup.Get();
        Assert.AreEqual(SeededSourceCode(), GetWarrantySourceCode(SourceCodeSetup),
            'Expected InitAuditCodes to seed a blank "Warranty Claim Source Code" on a "Source Code Setup" record that already exists — seeding may not be limited to the company where the record had to be created');
        Assert.AreEqual(SeededReasonCode(), GetWarrantyReasonCode(SourceCodeSetup),
            'Expected InitAuditCodes to seed a blank "Warranty Claim Reason Code" on a "Source Code Setup" record that already exists — seeding may not be limited to the company where the record had to be created');
        Assert.IsTrue(SourceCode.Get(SeededSourceCode()),
            StrSubstNo('Expected InitAuditCodes to create the "Source Code" record %1 when it seeds a setup record that already exists', SeededSourceCode()));
        Assert.IsTrue(ReasonCode.Get(SeededReasonCode()),
            StrSubstNo('Expected InitAuditCodes to create the "Reason Code" record %1 when it seeds a setup record that already exists', SeededReasonCode()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitAuditCodesSeedsTheReasonCodeAndKeepsAChosenSourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
    begin
        // [SCENARIO] Each of the two setup fields is judged on its own blankness
        // [GIVEN] a setup pointing at a source code of the implementer's own choosing, with the reason code left blank
        LibraryERM.CreateSourceCode(SourceCode);
        SetWarrantyCodes(SourceCode.Code, '');

        // [WHEN] initializing the audit codes
        WarrantyClaimPosting.InitAuditCodes();

        // [THEN] the chosen source code survives and only the blank reason code is seeded
        SourceCodeSetup.Get();
        Assert.AreEqual(SourceCode.Code, GetWarrantySourceCode(SourceCodeSetup),
            'Expected InitAuditCodes to leave a filled-in "Warranty Claim Source Code" alone even though the "Warranty Claim Reason Code" beside it was blank — the two fields are guarded one by one, never as a pair');
        Assert.AreEqual(SeededReasonCode(), GetWarrantyReasonCode(SourceCodeSetup),
            'Expected InitAuditCodes to seed the blank "Warranty Claim Reason Code" even though the "Warranty Claim Source Code" beside it was already filled in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitAuditCodesSeedsTheSourceCodeAndKeepsAChosenReasonCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        ReasonCode: Record "Reason Code";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
    begin
        // [SCENARIO] Each of the two setup fields is judged on its own blankness
        // [GIVEN] a setup pointing at a reason code of the implementer's own choosing, with the source code left blank
        LibraryERM.CreateReasonCode(ReasonCode);
        SetWarrantyCodes('', ReasonCode.Code);

        // [WHEN] initializing the audit codes
        WarrantyClaimPosting.InitAuditCodes();

        // [THEN] the chosen reason code survives and only the blank source code is seeded
        SourceCodeSetup.Get();
        Assert.AreEqual(ReasonCode.Code, GetWarrantyReasonCode(SourceCodeSetup),
            'Expected InitAuditCodes to leave a filled-in "Warranty Claim Reason Code" alone even though the "Warranty Claim Source Code" beside it was blank — the two fields are guarded one by one, never as a pair');
        Assert.AreEqual(SeededSourceCode(), GetWarrantySourceCode(SourceCodeSetup),
            'Expected InitAuditCodes to seed the blank "Warranty Claim Source Code" even though the "Warranty Claim Reason Code" beside it was already filled in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedEntriesCarryTheSourceCodeFromTheSetup()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceCode: Record "Source Code";
        ReasonCode: Record "Reason Code";
        GLEntry: Record "G/L Entry";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
        DocumentNo: Code[20];
        AccountNo: Code[20];
        BalAccountNo: Code[20];
    begin
        // [SCENARIO] Both G/L entries of a posted claim carry the source code the setup holds right now
        // [GIVEN] a setup pointing at a freshly generated source code and a general journal line to post
        LibraryERM.CreateSourceCode(SourceCode);
        LibraryERM.CreateReasonCode(ReasonCode);
        SetWarrantyCodes(SourceCode.Code, ReasonCode.Code);
        CreateWarrantyClaimLine(GenJournalLine, DocumentNo, AccountNo, BalAccountNo);

        // [WHEN] posting the claim
        WarrantyClaimPosting.PostWarrantyClaim(GenJournalLine);

        // [THEN] the entry on the account and the entry on the balancing account both carry that code
        FindGLEntry(GLEntry, DocumentNo, AccountNo);
        Assert.AreEqual(SourceCode.Code, GLEntry."Source Code",
            'Expected the G/L entry on "Account No." to carry the "Warranty Claim Source Code" the setup holds at posting time — read the setup, never a literal');
        FindGLEntry(GLEntry, DocumentNo, BalAccountNo);
        Assert.AreEqual(SourceCode.Code, GLEntry."Source Code",
            'Expected the G/L entry on "Bal. Account No." to carry the same "Warranty Claim Source Code" as the entry on "Account No."');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedEntriesCarryTheReasonCodeFromTheSetup()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceCode: Record "Source Code";
        ReasonCode: Record "Reason Code";
        GLEntry: Record "G/L Entry";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
        DocumentNo: Code[20];
        AccountNo: Code[20];
        BalAccountNo: Code[20];
    begin
        // [SCENARIO] Both G/L entries of a posted claim carry the reason code the setup holds right now
        // [GIVEN] a setup pointing at a freshly generated reason code and a general journal line to post
        LibraryERM.CreateSourceCode(SourceCode);
        LibraryERM.CreateReasonCode(ReasonCode);
        SetWarrantyCodes(SourceCode.Code, ReasonCode.Code);
        CreateWarrantyClaimLine(GenJournalLine, DocumentNo, AccountNo, BalAccountNo);

        // [WHEN] posting the claim
        WarrantyClaimPosting.PostWarrantyClaim(GenJournalLine);

        // [THEN] the entry on the account and the entry on the balancing account both carry that code
        FindGLEntry(GLEntry, DocumentNo, AccountNo);
        Assert.AreEqual(ReasonCode.Code, GLEntry."Reason Code",
            'Expected the G/L entry on "Account No." to carry the "Warranty Claim Reason Code" the setup holds at posting time — the reason code is a separate field from the source code');
        FindGLEntry(GLEntry, DocumentNo, BalAccountNo);
        Assert.AreEqual(ReasonCode.Code, GLEntry."Reason Code",
            'Expected the G/L entry on "Bal. Account No." to carry the same "Warranty Claim Reason Code" as the entry on "Account No."');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingWithoutASetupRowStampsTheSeededCodes()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry: Record "G/L Entry";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
        DocumentNo: Code[20];
        AccountNo: Code[20];
        BalAccountNo: Code[20];
    begin
        // [SCENARIO] The very first warranty claim in a company posts and carries the seeded codes
        // [GIVEN] a general journal line, and a company whose "Source Code Setup" record has been removed
        CreateWarrantyClaimLine(GenJournalLine, DocumentNo, AccountNo, BalAccountNo);
        SourceCodeSetup.DeleteAll();

        // [WHEN] posting the claim
        WarrantyClaimPosting.PostWarrantyClaim(GenJournalLine);

        // [THEN] posting succeeded and the entry carries the seeded codes
        FindGLEntry(GLEntry, DocumentNo, AccountNo);
        Assert.AreEqual(SeededSourceCode(), GLEntry."Source Code",
            'Expected the first warranty claim in a company with no setup record to post with the seeded source code — PostWarrantyClaim has to initialize before it posts');
        Assert.AreEqual(SeededReasonCode(), GLEntry."Reason Code",
            'Expected the first warranty claim in a company with no setup record to post with the seeded reason code — PostWarrantyClaim has to initialize before it posts');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingCreatesTheBalancedGLEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        WarrantyClaimPosting: Codeunit "Warranty Claim Posting";
        ClaimAmount: Decimal;
        DocumentNo: Code[20];
        AccountNo: Code[20];
        BalAccountNo: Code[20];
    begin
        // [SCENARIO] Stamping is not enough — the line has to reach the general ledger
        // [GIVEN] a general journal line carrying a generated amount
        CreateWarrantyClaimLine(GenJournalLine, DocumentNo, AccountNo, BalAccountNo);
        ClaimAmount := GenJournalLine.Amount;

        // [WHEN] posting the claim
        WarrantyClaimPosting.PostWarrantyClaim(GenJournalLine);

        // [THEN] the account is debited and the balancing account credited with that amount
        FindGLEntry(GLEntry, DocumentNo, AccountNo);
        Assert.AreEqual(ClaimAmount, GLEntry.Amount,
            'Expected the G/L entry on "Account No." to carry the amount of the journal line handed to PostWarrantyClaim');
        FindGLEntry(GLEntry, DocumentNo, BalAccountNo);
        Assert.AreEqual(-ClaimAmount, GLEntry.Amount,
            'Expected the G/L entry on "Bal. Account No." to carry the opposite amount — the posted transaction must balance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownSourceCodeIsRejected()
    var
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        RecRef: RecordRef;
        WarrantySourceCode: FieldRef;
    begin
        // [SCENARIO] "Warranty Claim Source Code" only accepts codes that exist in the Source Code table
        // [GIVEN] an in-memory setup record, and a code that is not in the "Source Code" table
        SourceCodeSetup.Init();
        RecRef.GetTable(SourceCodeSetup);
        WarrantySourceCode := FieldByName(RecRef, WarrantySourceCodeFieldTok);
        if SourceCode.Get(UnknownCode()) then
            SourceCode.Delete();

        // [WHEN] validating "Warranty Claim Source Code" with that code
        asserterror WarrantySourceCode.Validate(UnknownCode());

        // [THEN] the write is rejected with an error naming the offending code
        Assert.ExpectedError(UnknownCode());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownReasonCodeIsRejected()
    var
        SourceCodeSetup: Record "Source Code Setup";
        ReasonCode: Record "Reason Code";
        RecRef: RecordRef;
        WarrantyReasonCode: FieldRef;
    begin
        // [SCENARIO] "Warranty Claim Reason Code" only accepts codes that exist in the Reason Code table
        // [GIVEN] an in-memory setup record, and a code that is not in the "Reason Code" table
        SourceCodeSetup.Init();
        RecRef.GetTable(SourceCodeSetup);
        WarrantyReasonCode := FieldByName(RecRef, WarrantyReasonCodeFieldTok);
        if ReasonCode.Get(UnknownCode()) then
            ReasonCode.Delete();

        // [WHEN] validating "Warranty Claim Reason Code" with that code
        asserterror WarrantyReasonCode.Validate(UnknownCode());

        // [THEN] the write is rejected with an error naming the offending code
        Assert.ExpectedError(UnknownCode());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupFieldsAreCodeTen()
    var
        RecRef: RecordRef;
    begin
        // [SCENARIO] Both setup fields are declared wide enough for a full audit code and no wider
        RecRef.Open(Database::"Source Code Setup");
        VerifyFieldIsCodeTen(FieldByName(RecRef, WarrantySourceCodeFieldTok), 'Source Code');
        VerifyFieldIsCodeTen(FieldByName(RecRef, WarrantyReasonCodeFieldTok), 'Reason Code');
    end;

    local procedure VerifyFieldIsCodeTen(FldRef: FieldRef; RelatedTableName: Text)
    begin
        Assert.IsTrue(FldRef.Type() = FieldType::Code,
            StrSubstNo('Expected "%1" to be declared as Code[10], not %2[%3]', FldRef.Name(), FldRef.Type(), FldRef.Length()));
        Assert.AreEqual(10, FldRef.Length(),
            StrSubstNo('Expected "%1" to be declared as Code[10] — the same width as the Code field of the %2 table', FldRef.Name(), RelatedTableName));
    end;

    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        Index: Integer;
    begin
        // Looked up by name at run time so the tests compile against a starter that
        // has not added the fields yet, and fail with a message that names them.
        for Index := 1 to RecRef.FieldCount() do
            if RecRef.FieldIndex(Index).Name() = FieldName then
                exit(RecRef.FieldIndex(Index));
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;

    local procedure GetWarrantySourceCode(SourceCodeSetup: Record "Source Code Setup") WarrantySourceCode: Code[10]
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceCodeSetup);
        WarrantySourceCode := FieldByName(RecRef, WarrantySourceCodeFieldTok).Value();
    end;

    local procedure GetWarrantyReasonCode(SourceCodeSetup: Record "Source Code Setup") WarrantyReasonCode: Code[10]
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceCodeSetup);
        WarrantyReasonCode := FieldByName(RecRef, WarrantyReasonCodeFieldTok).Value();
    end;

    local procedure SeededSourceCode(): Code[10]
    begin
        exit('WARRANTY');
    end;

    local procedure SeededReasonCode(): Code[10]
    begin
        exit('WARRCLAIM');
    end;

    local procedure UnknownCode(): Code[10]
    begin
        exit('ZZNOSUCH');
    end;

    local procedure SetWarrantyCodes(SourceCodeValue: Code[10]; ReasonCodeValue: Code[10])
    var
        SourceCodeSetup: Record "Source Code Setup";
        RecRef: RecordRef;
    begin
        if not SourceCodeSetup.Get() then begin
            SourceCodeSetup.Init();
            SourceCodeSetup.Insert();
        end;
        RecRef.GetTable(SourceCodeSetup);
        FieldByName(RecRef, WarrantySourceCodeFieldTok).Value := SourceCodeValue;
        FieldByName(RecRef, WarrantyReasonCodeFieldTok).Value := ReasonCodeValue;
        RecRef.Modify();
    end;

    local procedure CreateWarrantyClaimLine(var GenJournalLine: Record "Gen. Journal Line"; var DocumentNo: Code[20]; var AccountNo: Code[20]; var BalAccountNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            LibraryRandom.RandDecInRange(100, 1000, 2));

        // Posting swaps "Account No." with "Bal. Account No." and negates Amount on whatever
        // record reaches codeunit "Gen. Jnl.-Post Line", so the entries have to be looked up by
        // the values the line carried before it was handed to PostWarrantyClaim.
        DocumentNo := GenJournalLine."Document No.";
        AccountNo := GenJournalLine."Account No.";
        BalAccountNo := GenJournalLine."Bal. Account No.";
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.IsTrue(GLEntry.FindFirst(),
            StrSubstNo('Expected PostWarrantyClaim to post the line it was given: no G/L entry found on account %1 for document %2', GLAccountNo, DocumentNo));
    end;
}
