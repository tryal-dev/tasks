codeunit 50900 "Journal Preflight Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheLowestDefectiveLineNo()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Base: Integer;
    begin
        // [SCENARIO] The first verdict is the defective line with the LOWEST line number,
        // whichever rule it breaks
        Base := Any.IntegerInRange(1000, 5000);
        InsertLine('TRYAL-A', Base + 10, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-A', Base + 20, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-A', Base + 30, '', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-A', Base + 40, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-A', Base + 50, 'TRYAL-ACC', 0);

        Assert.AreEqual(Base + 30, JournalPreflight.CheckBatch('TRYAL-A'),
            'Expected the line number of the FIRST defective line in line-number order — a later defect must not shadow an earlier one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsAZeroAmountLine()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DefectLineNo: Integer;
    begin
        // [SCENARIO] A line with an account but a zero amount is defective, and it wins over
        // a LATER blank-account line — the verdict orders by line number, not by rule
        DefectLineNo := Any.IntegerInRange(200, 900);
        InsertLine('TRYAL-B', DefectLineNo - 100, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-B', DefectLineNo, 'TRYAL-ACC', 0);
        InsertLine('TRYAL-B', DefectLineNo + 100, '', Any.DecimalInRange(1, 500, 2));

        Assert.AreEqual(DefectLineNo, JournalPreflight.CheckBatch('TRYAL-B'),
            'Expected the zero-amount line to be flagged as the batch''s first defect — a later blank-account line must not win just because it breaks a different rule');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsABlankAccountLine()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DefectLineNo: Integer;
    begin
        // [SCENARIO] A line with an amount but no account is defective
        DefectLineNo := Any.IntegerInRange(200, 900);
        InsertLine('TRYAL-C', DefectLineNo - 100, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-C', DefectLineNo, '', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-C', DefectLineNo + 100, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));

        Assert.AreEqual(DefectLineNo, JournalPreflight.CheckBatch('TRYAL-C'),
            'Expected the blank-account line to be flagged as the batch''s first defect');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsZeroForACleanBatch()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A batch where every line has an account and a nonzero amount passes;
        // a negative amount is valid, not a defect
        InsertLine('TRYAL-D', 100, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-D', 200, 'TRYAL-ACC', -Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-D', 300, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));

        Assert.AreEqual(0, JournalPreflight.CheckBatch('TRYAL-D'),
            'Expected 0 for a clean batch — every line has an account and a nonzero amount, and a negative amount is valid');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChecksOnlyTheRequestedBatch()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A defect in a neighbouring batch must not fail the requested one
        InsertLine('TRYAL-E1', 100, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-E1', 200, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-E2', 50, '', 0);

        Assert.AreEqual(0, JournalPreflight.CheckBatch('TRYAL-E1'),
            'Expected the clean batch to pass — the defective line belongs to another batch and must not leak into the verdict');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckBatchReturnsZeroForABatchWithNoLines()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A batch with no lines at all is clean, not an error
        Assert.AreEqual(0, JournalPreflight.CheckBatch('TRYAL-F'),
            'Expected 0 — without an error — for a batch that has no lines at all');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsEveryDefectiveLineInTheBatch()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DefectCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] The count spans the whole batch — blank-account and zero-amount defects
        // alike — while a neighbouring batch's defect stays out
        DefectCount := Any.IntegerInRange(4, 9);
        for i := 1 to DefectCount do begin
            InsertLine('TRYAL-G', i * 100, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
            if i mod 2 = 0 then
                InsertLine('TRYAL-G', i * 100 + 50, '', Any.DecimalInRange(1, 500, 2))
            else
                InsertLine('TRYAL-G', i * 100 + 50, 'TRYAL-ACC', 0);
        end;
        InsertLine('TRYAL-G2', 100, '', 0);

        Assert.AreEqual(DefectCount, JournalPreflight.CountDefects('TRYAL-G'),
            'Expected every defective line of the batch counted — blank accounts and zero amounts alike — and the neighbouring batch''s defect left out');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ALineBreakingBothRulesCountsOnce()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] Defective lines are counted, not broken rules: blank account AND zero
        // amount on one line is still one defective line
        InsertLine('TRYAL-H', 100, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-H', 200, '', 0);

        Assert.AreEqual(1, JournalPreflight.CountDefects('TRYAL-H'),
            'Expected a line that breaks both rules to count as ONE defective line, not two');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsZeroForACleanBatch()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A batch of only valid lines has zero defects
        InsertLine('TRYAL-I', 100, 'TRYAL-ACC', Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-I', 200, 'TRYAL-ACC', -Any.DecimalInRange(1, 500, 2));

        Assert.AreEqual(0, JournalPreflight.CountDefects('TRYAL-I'),
            'Expected a defect count of 0 for a batch where every line has an account and a nonzero amount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsZeroForABatchWithNoLines()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A batch with no lines has zero defects, not an error
        Assert.AreEqual(0, JournalPreflight.CountDefects('TRYAL-J'),
            'Expected a defect count of 0 — without an error — for a batch that has no lines at all');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckBatchReadsOnlyTheTopOfTheBatch()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        TotalLines: Integer;
        MaxRows: Integer;
        i: Integer;
        FirstDefect: Integer;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        // [SCENARIO] With the third line of a 20,000-line batch already defective, one
        // CheckBatch call reads at most 2,000 rows
        MaxRows := 2000;
        TotalLines := 20000;
        for i := 1 to TotalLines do
            if i = 3 then
                InsertLine('TRYAL-BIG', i, '', 100)
            else
                InsertLine('TRYAL-BIG', i, 'TRYAL-ACC', 1);

        // warm-up: the first call pays one-time metadata reads; grade the steady state
        JournalPreflight.CheckBatch('TRYAL-BIG');
        InvalidateDataCache();
        RowsBefore := SessionInformation.SqlRowsRead();
        FirstDefect := JournalPreflight.CheckBatch('TRYAL-BIG');
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        if DebugBudgets() then
            Assert.Fail(StrSubstNo('DEBUG: the graded CheckBatch call read %1 rows over the %2-line batch', RowsUsed, TotalLines));
        Assert.AreEqual(3, FirstDefect,
            StrSubstNo('Expected the graded call to still return the first defective line no. (3) of the %1-line batch', TotalLines));
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected one CheckBatch call to read at most %1 rows, but this call read %2 — the batch holds %3 lines and its third line already fails, so a read that fetches the complete set pays for all %3 rows to learn what the first handful already said', MaxRows, RowsUsed, TotalLines));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountDefectsAffordsItsFullPass()
    var
        JournalPreflight: Codeunit "Journal Preflight";
        Assert: Codeunit Assert;
        TotalLines: Integer;
        ExpectedDefects: Integer;
        MaxRows: Integer;
        i: Integer;
        Defects: Integer;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        // [SCENARIO] Counting defects over a 3,000-line batch stays correct and fits a
        // budget a single full pass over the batch has plenty of room in
        MaxRows := 12000;
        TotalLines := 3000;
        for i := 1 to TotalLines do
            if i mod 250 = 0 then begin
                InsertLine('TRYAL-CNT', i, 'TRYAL-ACC', 0);
                ExpectedDefects += 1;
            end else
                InsertLine('TRYAL-CNT', i, 'TRYAL-ACC', 1);

        // warm-up: the first call pays one-time metadata reads; grade the steady state
        JournalPreflight.CountDefects('TRYAL-CNT');
        InvalidateDataCache();
        RowsBefore := SessionInformation.SqlRowsRead();
        Defects := JournalPreflight.CountDefects('TRYAL-CNT');
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        if DebugBudgets() then
            Assert.Fail(StrSubstNo('DEBUG: the graded CountDefects call read %1 rows over the %2-line batch', RowsUsed, TotalLines));
        Assert.AreEqual(ExpectedDefects, Defects,
            StrSubstNo('Expected the exact defect count over the whole %1-line batch — every line must be inspected, there is no early exit from counting', TotalLines));
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected one CountDefects call over the %3-line batch to read at most %1 rows, but this call read %2 — a single full pass fits this budget with room to spare, so the batch is being read more than once', MaxRows, RowsUsed, TotalLines));
    end;

    local procedure InsertLine(BatchName: Code[10]; LineNo: Integer; AccountNo: Code[20]; Amount: Decimal)
    var
        DraftJournalLine: Record "Draft Journal Line";
    begin
        DraftJournalLine.Init();
        DraftJournalLine."Batch Name" := BatchName;
        DraftJournalLine."Line No." := LineNo;
        DraftJournalLine."Account No." := AccountNo;
        DraftJournalLine.Amount := Amount;
        DraftJournalLine.Insert();
    end;

    local procedure InvalidateDataCache()
    begin
        // The warm-up call leaves the batch's result set in the server data cache, and a
        // cached read costs zero SQL — the graded call would measure nothing, letting a
        // whole-set read sail under the budget. A write bumps the table's version and
        // forces real statements again; SelectLatestVersion alone is not enough for rows
        // this transaction has locked. The decoy batch sits outside every graded filter.
        InsertLine('TRYAL-DCY', 1, 'TRYAL-ACC', 1);
        SelectLatestVersion();
    end;

    local procedure DebugBudgets(): Boolean
    begin
        // flip to true to fail right after measuring with the raw counters in the message —
        // the calibration channel for re-baselining MaxRows on a new BC version
        exit(false);
    end;
}
