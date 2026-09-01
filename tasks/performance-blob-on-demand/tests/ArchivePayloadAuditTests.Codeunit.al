codeunit 50900 "Archive Payload Audit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MixedDepartmentTotalsRecordedAndMeasuredBytes()
    var
        ArchivedDocument: Record "Archived Document";
        ArchivePayloadAudit: Codeunit "Archive Payload Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedTotal: Integer;
        RecordedSize1: Integer;
        RecordedSize2: Integer;
    begin
        // [SCENARIO] Recorded sizes are trusted, legacy payloads are measured, and both add up
        // [GIVEN] a department with two recorded-size documents (whose stored payloads deliberately differ from the recorded number) and two legacy documents
        RecordedSize1 := Any.IntegerInRange(1000, 9999);
        RecordedSize2 := Any.IntegerInRange(1000, 9999);
        CreateArchivedDocument(1101, 'TRYAL-A1', RecordedSize1, Any.IntegerInRange(20, 60));
        ExpectedTotal += RecordedSize1;
        ExpectedTotal += CreateArchivedDocument(1102, 'TRYAL-A1', 0, Any.IntegerInRange(30, 120));
        CreateArchivedDocument(1103, 'TRYAL-A1', RecordedSize2, Any.IntegerInRange(20, 60));
        ExpectedTotal += RecordedSize2;
        ExpectedTotal += CreateArchivedDocument(1104, 'TRYAL-A1', 0, Any.IntegerInRange(30, 120));
        CreateArchivedDocument(1109, 'TRYAL-A9', 0, Any.IntegerInRange(30, 120));

        // [WHEN] totalling the department's payload bytes
        // [THEN] the total is recorded sizes plus measured legacy payloads, decoy department excluded
        Assert.AreEqual(ExpectedTotal, ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-A1'),
            'Expected the total to trust each Recorded Size greater than zero and to measure only the legacy documents'' stored payloads, counting the requested department alone');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyDocumentWithEmptyPayloadAddsNothing()
    var
        ArchivedDocument: Record "Archived Document";
        ArchivePayloadAudit: Codeunit "Archive Payload Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedTotal: Integer;
    begin
        // [SCENARIO] A legacy document whose stored payload is empty contributes zero bytes
        // [GIVEN] a department with one empty-payload legacy document and one legacy document with content
        CreateArchivedDocument(1201, 'TRYAL-B1', 0, 0);
        ExpectedTotal := CreateArchivedDocument(1202, 'TRYAL-B1', 0, Any.IntegerInRange(30, 120));

        // [WHEN] totalling the department's payload bytes
        // [THEN] only the non-empty payload counts, and the empty one raises no error
        Assert.AreEqual(ExpectedTotal, ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-B1'),
            'Expected the empty-payload legacy document to contribute 0 bytes and the other legacy document its measured payload size');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DepartmentWithNoDocumentsTotalsZero()
    var
        ArchivedDocument: Record "Archived Document";
        ArchivePayloadAudit: Codeunit "Archive Payload Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] An unknown department totals zero without erroring
        // [GIVEN] archived documents that all belong to another department
        CreateArchivedDocument(1301, 'TRYAL-C9', 0, Any.IntegerInRange(30, 120));
        CreateArchivedDocument(1302, 'TRYAL-C9', Any.IntegerInRange(1000, 9999), Any.IntegerInRange(20, 60));

        // [WHEN] totalling a department that owns no documents
        // [THEN] the result is zero and no error is raised
        Assert.AreEqual(0, ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-C1'),
            'Expected a department with no archived documents to total 0 bytes without raising an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DocumentsOutsideTheDepartmentAreIgnored()
    var
        ArchivedDocument: Record "Archived Document";
        ArchivePayloadAudit: Codeunit "Archive Payload Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedTotal: Integer;
    begin
        // [SCENARIO] Only the requested department's documents enter the total
        // [GIVEN] one legacy document in the audited department and richer decoys in another
        ExpectedTotal := CreateArchivedDocument(1401, 'TRYAL-D1', 0, Any.IntegerInRange(30, 120));
        CreateArchivedDocument(1402, 'TRYAL-D9', 0, Any.IntegerInRange(30, 120));
        CreateArchivedDocument(1403, 'TRYAL-D9', Any.IntegerInRange(1000, 9999), Any.IntegerInRange(20, 60));

        // [WHEN] totalling the audited department
        // [THEN] the decoy department's documents stay out of the total
        Assert.AreEqual(ExpectedTotal, ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-D1'),
            'Expected only the requested department''s documents in the total — documents of other departments must stay out');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PassRunsOnTheHandedInstanceAndEndsOnTheDepartmentsLastEntry()
    var
        ArchivedDocument: Record "Archived Document";
        ArchivePayloadAudit: Codeunit "Archive Payload Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] The pass runs on the handed instance, narrowed to the department
        // [GIVEN] a department of four entries, plus a later entry in another department
        CreateArchivedDocument(1501, 'TRYAL-E1', 0, Any.IntegerInRange(30, 120));
        CreateArchivedDocument(1502, 'TRYAL-E1', Any.IntegerInRange(1000, 9999), Any.IntegerInRange(20, 60));
        CreateArchivedDocument(1503, 'TRYAL-E1', 0, Any.IntegerInRange(30, 120));
        CreateArchivedDocument(1505, 'TRYAL-E1', Any.IntegerInRange(1000, 9999), Any.IntegerInRange(20, 60));
        CreateArchivedDocument(1509, 'TRYAL-E9', 0, Any.IntegerInRange(30, 120));

        // [WHEN] totalling the department on the handed record instance
        ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-E1');

        // [THEN] the instance rests on the department's last entry
        Assert.AreEqual(1505, ArchivedDocument."Entry No.",
            'Expected the pass to end on the department''s last archive entry — the audit must run on the very record instance it was handed, narrowed to the requested department');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditStaysWithinTheStatementBudget()
    var
        ArchivedDocument: Record "Archived Document";
        ArchivePayloadAudit: Codeunit "Archive Payload Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DocumentCount: Integer;
        LegacyCount: Integer;
        ExpectedTotal: Integer;
        RecordedSize: Integer;
        MaxStatements: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
        Total: Integer;
    begin
        // [SCENARIO] One department audit costs a bounded number of SQL statements
        // [GIVEN] a department of 35-45 documents, roughly a third of them legacy
        MaxStatements := 25;
        DocumentCount := Any.IntegerInRange(35, 45);
        for i := 1 to DocumentCount do
            if i mod 3 = 0 then begin
                ExpectedTotal += CreateArchivedDocument(6000 + i, 'TRYAL-F1', 0, Any.IntegerInRange(30, 120));
                LegacyCount += 1;
            end else begin
                RecordedSize := Any.IntegerInRange(1000, 9999);
                CreateArchivedDocument(6000 + i, 'TRYAL-F1', RecordedSize, Any.IntegerInRange(20, 60));
                ExpectedTotal += RecordedSize;
            end;

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-F1');
        InvalidateDataCache(999901);

        // [WHEN] totalling the department once with the counters snapshotted around the call
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Total := ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-F1');
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        // [THEN] the total is right and the call stays within the statement budget
        Assert.AreEqual(ExpectedTotal, Total,
            StrSubstNo('Expected the correct total for all %1 documents before judging the budget', DocumentCount));
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the audit to cost at most %1 SQL statements for %2 documents of which only %3 needed their payload measured, but this call executed %4 — fetching a payload the Recorded Size already answers pays one statement per document for nothing', MaxStatements, DocumentCount, LegacyCount, StatementsUsed));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditStaysWithinTheRowBudgetAcrossACrowdedArchive()
    var
        ArchivedDocument: Record "Archived Document";
        ArchivePayloadAudit: Codeunit "Archive Payload Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DocumentCount: Integer;
        BackgroundCount: Integer;
        ExpectedTotal: Integer;
        RecordedSize: Integer;
        MaxRows: Integer;
        i: Integer;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
        Total: Integer;
    begin
        // [SCENARIO] The audit reads only the department's rows, however crowded the archive is
        // [GIVEN] a department of 35-45 documents inside an archive of about 600
        MaxRows := 120;
        DocumentCount := Any.IntegerInRange(35, 45);
        for i := 1 to DocumentCount do
            if i mod 3 = 0 then
                ExpectedTotal += CreateArchivedDocument(7000 + i, 'TRYAL-G1', 0, Any.IntegerInRange(30, 120))
            else begin
                RecordedSize := Any.IntegerInRange(1000, 9999);
                CreateArchivedDocument(7000 + i, 'TRYAL-G1', RecordedSize, Any.IntegerInRange(20, 60));
                ExpectedTotal += RecordedSize;
            end;
        BackgroundCount := 600 - DocumentCount;
        for i := 1 to BackgroundCount do
            if i mod 2 = 0 then
                CreateArchivedDocument(8000 + i, 'TRYAL-G9', 0, Any.IntegerInRange(10, 20))
            else
                CreateArchivedDocument(8000 + i, 'TRYAL-G9', Any.IntegerInRange(1000, 9999), Any.IntegerInRange(10, 20));

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-G1');
        InvalidateDataCache(999902);

        // [WHEN] totalling the department once with the counters snapshotted around the call
        RowsBefore := SessionInformation.SqlRowsRead();
        Total := ArchivePayloadAudit.TotalPayloadBytes(ArchivedDocument, 'TRYAL-G1');
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        // [THEN] the total is right and the call stays within the row budget
        Assert.AreEqual(ExpectedTotal, Total,
            StrSubstNo('Expected the correct total for the %1 documents of the audited department before judging the row budget', DocumentCount));
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected the audit to read at most %1 rows for a department of %2 documents, but this call read %3 while the archive holds about 600 — scanning the whole archive and picking the department in code does not scale', MaxRows, DocumentCount, RowsUsed));
    end;

    local procedure CreateArchivedDocument(EntryNo: Integer; DepartmentCode: Code[20]; RecordedSize: Integer; PayloadLength: Integer): Integer
    var
        ArchivedDocument: Record "Archived Document";
        Any: Codeunit Any;
        PayloadOutStream: OutStream;
    begin
        ArchivedDocument.Init();
        ArchivedDocument."Entry No." := EntryNo;
        ArchivedDocument."Department Code" := DepartmentCode;
        ArchivedDocument.Description := 'TRYAL archived payload';
        ArchivedDocument."Recorded Size" := RecordedSize;
        if PayloadLength > 0 then begin
            ArchivedDocument.Content.CreateOutStream(PayloadOutStream);
            PayloadOutStream.WriteText(Any.AlphabeticText(PayloadLength));
        end;
        ArchivedDocument.Insert();
        // the caller's expected total uses the byte count actually stored, so the
        // arithmetic stays independent of the stream's text encoding
        exit(ArchivedDocument.Content.Length());
    end;

    local procedure InvalidateDataCache(DecoyEntryNo: Integer)
    var
        ArchivedDocument: Record "Archived Document";
    begin
        // The warm-up call leaves the Archived Document result sets in the server
        // data cache, and a cached read costs zero SQL — the graded call would
        // measure nothing. A write bumps the table's version and forces real
        // statements again; SelectLatestVersion alone is not enough for rows this
        // transaction has locked. The decoy lives in department TRYAL-ZZ, which no
        // graded call audits.
        ArchivedDocument.Init();
        ArchivedDocument."Entry No." := DecoyEntryNo;
        ArchivedDocument."Department Code" := 'TRYAL-ZZ';
        ArchivedDocument."Recorded Size" := 1;
        ArchivedDocument.Insert();
        SelectLatestVersion();
    end;
}
