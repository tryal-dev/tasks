codeunit 50900 "Staging Importer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertsEveryNewKeyNumberedInListOrder()
    var
        ImportStaging: Record "Import Staging";
        StagingImporter: Codeunit "Staging Importer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExternalNos: List of [Code[20]];
        BatchSize: Integer;
        Inserted: Integer;
        i: Integer;
    begin
        // [SCENARIO] A batch of brand-new keys lands in the table once each, numbered 1..N in list order
        ImportStaging.DeleteAll();
        BatchSize := Any.IntegerInRange(5, 9);
        for i := 1 to BatchSize do
            ExternalNos.Add(KeyFor('A', i));

        Inserted := StagingImporter.ImportBatch(ExternalNos);

        Assert.AreEqual(BatchSize, Inserted,
            'Expected the call to report one inserted row per brand-new key in the batch');
        Assert.AreEqual(BatchSize, ImportStaging.Count(),
            'Expected exactly one Import Staging row per key of the batch — no extras, none missing');
        for i := 1 to BatchSize do
            AssertRow(KeyFor('A', i), i,
                'in an empty table the first inserted row gets line number 1 and the numbering follows list order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContinuesNumberingFromTheHighestExistingLineNo()
    var
        StagingImporter: Codeunit "Staging Importer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ImportStaging: Record "Import Staging";
        ExternalNos: List of [Code[20]];
        HighLineNo: Integer;
        Inserted: Integer;
    begin
        // [SCENARIO] New rows continue from the highest existing line number, gaps in the old numbering included
        ImportStaging.DeleteAll();
        HighLineNo := Any.IntegerInRange(10, 40);
        // the HIGH number sits on the alphabetically EARLIER key: the table's PK is
        // "External No.", so a FindLast() on the default sort order must not
        // coincidentally land on the true "Line No." maximum
        SeedRow(KeyFor('B-OLD', 1), HighLineNo);
        SeedRow(KeyFor('B-OLD', 2), 3);
        ExternalNos.Add(KeyFor('B-NEW', 1));
        ExternalNos.Add(KeyFor('B-NEW', 2));

        Inserted := StagingImporter.ImportBatch(ExternalNos);

        Assert.AreEqual(2, Inserted, 'Expected both new keys to be inserted');
        AssertRow(KeyFor('B-NEW', 1), HighLineNo + 1,
            'the first inserted row continues right after the highest line number already in the table');
        AssertRow(KeyFor('B-NEW', 2), HighLineNo + 2,
            'the second inserted row takes the next number in the same running sequence');
        AssertRow(KeyFor('B-OLD', 1), HighLineNo,
            'a pre-existing row must keep its old line number untouched');
        AssertRow(KeyFor('B-OLD', 2), 3,
            'a pre-existing row must keep its old line number — the gap in the old numbering is not refilled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AlreadyStagedKeyIsSkippedWithoutConsumingANumber()
    var
        StagingImporter: Codeunit "Staging Importer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ImportStaging: Record "Import Staging";
        ExternalNos: List of [Code[20]];
        OldLineNo: Integer;
        Inserted: Integer;
    begin
        // [SCENARIO] A key already in the table is skipped: not re-inserted, not renumbered, no number consumed
        ImportStaging.DeleteAll();
        OldLineNo := Any.IntegerInRange(3, 30);
        SeedRow(KeyFor('C-OLD', 1), OldLineNo);
        ExternalNos.Add(KeyFor('C-NEW', 1));
        ExternalNos.Add(KeyFor('C-OLD', 1));
        ExternalNos.Add(KeyFor('C-NEW', 2));

        Inserted := StagingImporter.ImportBatch(ExternalNos);

        Assert.AreEqual(2, Inserted,
            'Expected the return value to count only the rows actually inserted — the already-staged key adds nothing');
        Assert.AreEqual(3, ImportStaging.Count(),
            'Expected the staged key to stay a single row next to the two new ones');
        AssertRow(KeyFor('C-NEW', 1), OldLineNo + 1,
            'the first new key takes the number right after the existing maximum');
        AssertRow(KeyFor('C-NEW', 2), OldLineNo + 2,
            'the skipped key in between must not consume a number — the inserted rows are numbered consecutively');
        AssertRow(KeyFor('C-OLD', 1), OldLineNo,
            'the already-staged row must come out of the call completely untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeyRepeatedInsideTheBatchIsInsertedOnce()
    var
        StagingImporter: Codeunit "Staging Importer";
        Assert: Codeunit Assert;
        ImportStaging: Record "Import Staging";
        ExternalNos: List of [Code[20]];
        Inserted: Integer;
    begin
        // [SCENARIO] A key occurring twice in one batch lands once, at its first position
        ImportStaging.DeleteAll();
        ExternalNos.Add(KeyFor('D', 1));
        ExternalNos.Add(KeyFor('D', 2));
        ExternalNos.Add(KeyFor('D', 1));
        ExternalNos.Add(KeyFor('D', 3));
        ExternalNos.Add(KeyFor('D', 2));

        Inserted := StagingImporter.ImportBatch(ExternalNos);

        Assert.AreEqual(3, Inserted,
            'Expected only the three distinct keys of the batch to be counted as inserted');
        Assert.AreEqual(3, ImportStaging.Count(),
            'Expected one row per distinct key — repeats inside the batch must not raise an error or a second row');
        AssertRow(KeyFor('D', 1), 1, 'the repeated key keeps the number of its FIRST position in the batch');
        AssertRow(KeyFor('D', 2), 2, 'the second distinct key takes the second number');
        AssertRow(KeyFor('D', 3), 3, 'later repeats consume no number — the third distinct key gets 3, not 4');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyBatchInsertsNothingAndReturnsZero()
    var
        StagingImporter: Codeunit "Staging Importer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ImportStaging: Record "Import Staging";
        EmptyBatch: List of [Code[20]];
        OldLineNo: Integer;
        Inserted: Integer;
    begin
        // [SCENARIO] An empty batch is a normal input: nothing inserted, nothing touched, no error
        ImportStaging.DeleteAll();
        OldLineNo := Any.IntegerInRange(1, 20);
        SeedRow(KeyFor('E-OLD', 1), OldLineNo);

        Inserted := StagingImporter.ImportBatch(EmptyBatch);

        Assert.AreEqual(0, Inserted, 'Expected an empty batch to report zero inserted rows');
        Assert.AreEqual(1, ImportStaging.Count(),
            'Expected the table to hold exactly the row it held before the empty call');
        AssertRow(KeyFor('E-OLD', 1), OldLineNo, 'the existing row survives an empty call untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BatchOfOnlyStagedKeysReturnsZeroWithoutError()
    var
        StagingImporter: Codeunit "Staging Importer";
        Assert: Codeunit Assert;
        ImportStaging: Record "Import Staging";
        ExternalNos: List of [Code[20]];
        Inserted: Integer;
    begin
        // [SCENARIO] Re-importing a batch whose keys are all staged already changes nothing and raises no error
        ImportStaging.DeleteAll();
        SeedRow(KeyFor('F', 1), 1);
        SeedRow(KeyFor('F', 2), 2);
        ExternalNos.Add(KeyFor('F', 1));
        ExternalNos.Add(KeyFor('F', 2));

        Inserted := StagingImporter.ImportBatch(ExternalNos);

        Assert.AreEqual(0, Inserted,
            'Expected zero inserted rows — and no error — when every key of the batch is staged already');
        Assert.AreEqual(2, ImportStaging.Count(),
            'Expected the table unchanged after re-importing an already-staged batch');
        AssertRow(KeyFor('F', 1), 1, 'a re-imported row keeps its line number');
        AssertRow(KeyFor('F', 2), 2, 'a re-imported row keeps its line number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheSqlStatementBudget()
    var
        StagingImporter: Codeunit "Staging Importer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ImportStaging: Record "Import Staging";
        WarmupNos: List of [Code[20]];
        ExternalNos: List of [Code[20]];
        ExistingCount: Integer;
        WarmupCount: Integer;
        NewCount: Integer;
        HighestLineNo: Integer;
        MaxStatements: Integer;
        Inserted: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        // [SCENARIO] One call staging 25-30 new keys plus already-staged decoys fits the 15-statement budget
        MaxStatements := 15;
        ImportStaging.DeleteAll();
        ExistingCount := 4;
        // seeded in DESCENDING line-number order: the alphabetically last pre-existing
        // key must not carry the highest "Line No.", or a FindLast() on the PK
        // ("External No.") would coincidentally find the numbering base here too
        for i := 1 to ExistingCount do
            SeedRow(KeyFor('P-EX', i), ExistingCount + 1 - i);
        WarmupCount := Any.IntegerInRange(6, 9);
        for i := 1 to WarmupCount do
            WarmupNos.Add(KeyFor('P-WU', i));
        NewCount := Any.IntegerInRange(25, 30);
        for i := 1 to NewCount do
            ExternalNos.Add(KeyFor('P-NW', i));
        // already-staged decoys make the graded call prove its dedup at batch scale
        ExternalNos.Add(KeyFor('P-EX', 1));
        ExternalNos.Add(KeyFor('P-WU', 2));

        // warm-up: the first call pays one-time metadata statements; grade the steady state
        StagingImporter.ImportBatch(WarmupNos);
        // this read flushes any writes the warm-up call still has buffered OUT of the measured window
        Assert.AreEqual(ExistingCount + WarmupCount, ImportStaging.Count(),
            'Expected the warm-up batch to be staged before the graded call is measured');
        // measure the codeunit cold: keys or numbering remembered in instance state from the
        // warm-up must not let the graded call skip its own look at the table
        Clear(StagingImporter);
        InvalidateDataCache();
        HighestLineNo := ExistingCount + WarmupCount;

        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Inserted := StagingImporter.ImportBatch(ExternalNos);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        if DebugBudgets() then
            Assert.Fail(StrSubstNo('DEBUG: the graded call executed %1 SQL statements for %2 new keys', StatementsUsed, NewCount));
        Assert.AreEqual(NewCount, Inserted,
            StrSubstNo('Expected the graded call to insert every one of the %1 new keys before judging the budget', NewCount));
        Assert.AreEqual(ExistingCount + WarmupCount + 1 + NewCount, ImportStaging.Count(),
            'Expected the graded call to add exactly the new keys — already-staged decoys in the batch must not double up');
        AssertRow(KeyFor('P-NW', 1), HighestLineNo + 1,
            'the budget-friendly import still numbers its first new row right after the existing maximum');
        AssertRow(KeyFor('P-NW', NewCount), HighestLineNo + NewCount,
            'the budget-friendly import still numbers its last new row consecutively');
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the whole import to cost at most %1 SQL statements, but this call executed %2 for %3 new keys — asking the staging table about candidate keys one at a time, or writing rows one statement at a time, spends the budget many times over', MaxStatements, StatementsUsed, NewCount));
    end;

    local procedure KeyFor(Infix: Text; Index: Integer): Code[20]
    begin
        exit(CopyStr(StrSubstNo('TRYAL-%1-%2', Infix, Index), 1, 20));
    end;

    local procedure SeedRow(ExternalNo: Code[20]; LineNo: Integer)
    var
        ImportStaging: Record "Import Staging";
    begin
        ImportStaging.Init();
        ImportStaging."External No." := ExternalNo;
        ImportStaging."Line No." := LineNo;
        ImportStaging.Insert();
    end;

    local procedure AssertRow(ExternalNo: Code[20]; ExpectedLineNo: Integer; Because: Text)
    var
        ImportStaging: Record "Import Staging";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(ImportStaging.Get(ExternalNo),
            StrSubstNo('Expected an Import Staging row for key %1 — %2', ExternalNo, Because));
        Assert.AreEqual(ExpectedLineNo, ImportStaging."Line No.",
            StrSubstNo('Expected line number %1 on key %2 — %3', ExpectedLineNo, ExternalNo, Because));
    end;

    local procedure InvalidateDataCache()
    begin
        // The warm-up leaves Import Staging's result sets in the server data cache, and a
        // cached read costs zero SQL — the graded call's own look at the table would measure
        // nothing. A write bumps the table version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has locked.
        // Line number 0 keeps the decoy below every real row, so the numbering is unaffected.
        SeedRow('TRYAL-DECOY', 0);
        SelectLatestVersion();
    end;

    local procedure DebugBudgets(): Boolean
    begin
        // flip to true to fail right after measuring with the raw counter in the message —
        // the calibration channel for re-baselining MaxStatements on a new BC version
        exit(false);
    end;
}
