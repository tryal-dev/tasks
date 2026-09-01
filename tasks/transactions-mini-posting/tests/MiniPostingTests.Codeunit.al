codeunit 50900 "Mini Posting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingCreatesOneLedgerEntryPerOpenLine()
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        AmountA: Decimal;
        AmountB: Decimal;
    begin
        // [SCENARIO] A balanced three-line batch produces three ledger entries
        AmountA := Any.DecimalInRange(10, 500, 2);
        AmountB := Any.DecimalInRange(10, 500, 2);
        CreateLine('TRYAL-T01', 10, 'ACC-1', WorkDate(), AmountA);
        CreateLine('TRYAL-T01', 20, 'ACC-2', WorkDate(), AmountB);
        CreateLine('TRYAL-T01', 30, 'ACC-3', WorkDate(), -(AmountA + AmountB));

        MiniJnlPostBatch.PostBatch('TRYAL-T01');

        Assert.AreEqual(3, LedgerEntryCount('TRYAL-T01'),
            'Expected exactly one ledger entry per journal line of the posted batch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingCopiesTheLineFieldsToTheLedgerEntry()
    var
        MiniLedgerEntry: Record "Mini Ledger Entry";
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        AccountNo: Code[20];
        PostingDate: Date;
        LineDescription: Text[50];
        LineAmount: Decimal;
    begin
        // [SCENARIO] Account No., Posting Date, Description, Amount and Batch Name travel line -> entry
        AccountNo := CopyStr('T02-' + UpperCase(Any.AlphabeticText(8)), 1, 20);
        PostingDate := Any.DateInRange(120);
        LineDescription := CopyStr(Any.AlphabeticText(30), 1, 50);
        LineAmount := Any.DecimalInRange(100, 900, 2);
        CreateLine('TRYAL-T02', 10, AccountNo, PostingDate, LineDescription, LineAmount);
        CreateLine('TRYAL-T02', 20, 'ACC-BAL', WorkDate(), -LineAmount);

        MiniJnlPostBatch.PostBatch('TRYAL-T02');

        MiniLedgerEntry.SetRange("Account No.", AccountNo);
        Assert.IsTrue(MiniLedgerEntry.FindFirst(),
            StrSubstNo('Expected a ledger entry carrying the posted line''s account %1', AccountNo));
        Assert.AreEqual(PostingDate, MiniLedgerEntry."Posting Date",
            'Expected the line''s posting date on its ledger entry');
        Assert.AreEqual(LineDescription, MiniLedgerEntry.Description,
            'Expected the line''s description on its ledger entry');
        Assert.AreEqual(LineAmount, MiniLedgerEntry.Amount,
            'Expected the line''s amount on its ledger entry');
        Assert.AreEqual('TRYAL-T02', MiniLedgerEntry."Batch Name",
            'Expected the batch name on the ledger entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryNumbersContinueAfterTheLastExistingEntry()
    var
        MiniLedgerEntry: Record "Mini Ledger Entry";
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SeedEntryNo: Integer;
        AmountA: Decimal;
    begin
        // [SCENARIO] New entry numbers pick up right after the highest entry already in the ledger
        SeedEntryNo := SeedLedgerEntry(Any.IntegerInRange(100, 900));
        AmountA := Any.DecimalInRange(10, 500, 2);
        CreateLine('TRYAL-T03', 10, 'ACC-1', WorkDate(), AmountA);
        CreateLine('TRYAL-T03', 20, 'ACC-2', WorkDate(), -AmountA);

        MiniJnlPostBatch.PostBatch('TRYAL-T03');

        MiniLedgerEntry.SetRange("Batch Name", 'TRYAL-T03');
        Assert.AreEqual(2, MiniLedgerEntry.Count(),
            'Expected exactly two new ledger entries for the batch');
        MiniLedgerEntry.FindFirst();
        Assert.AreEqual(SeedEntryNo + 1, MiniLedgerEntry."Entry No.",
            'Expected the first new entry number to continue right after the highest existing ledger entry');
        MiniLedgerEntry.FindLast();
        Assert.AreEqual(SeedEntryNo + 2, MiniLedgerEntry."Entry No.",
            'Expected the second new entry number to follow the first with no gap');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesFollowLineNumberOrder()
    var
        MiniLedgerEntry: Record "Mini Ledger Entry";
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Entries are numbered in ascending Line No. order, however the lines were inserted
        CreateLine('TRYAL-T04', 30, 'ACC-3', WorkDate(), 5);
        CreateLine('TRYAL-T04', 10, 'ACC-1', WorkDate(), 10);
        CreateLine('TRYAL-T04', 20, 'ACC-2', WorkDate(), -15);

        MiniJnlPostBatch.PostBatch('TRYAL-T04');

        MiniLedgerEntry.SetRange("Batch Name", 'TRYAL-T04');
        Assert.AreEqual(3, MiniLedgerEntry.Count(),
            'Expected exactly one ledger entry per journal line of the posted batch');
        MiniLedgerEntry.FindSet();
        Assert.AreEqual('ACC-1', MiniLedgerEntry."Account No.",
            'Expected the lowest new entry number to carry line 10 — entries are created in ascending Line No. order');
        MiniLedgerEntry.Next();
        Assert.AreEqual('ACC-2', MiniLedgerEntry."Account No.",
            'Expected the middle entry number to carry line 20');
        MiniLedgerEntry.Next();
        Assert.AreEqual('ACC-3', MiniLedgerEntry."Account No.",
            'Expected the highest entry number to carry line 30');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingMarksEveryBatchLinePosted()
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A successful post flips every line to Posted and keeps the lines in the journal
        CreateLine('TRYAL-T05', 10, 'ACC-1', WorkDate(), 100);
        CreateLine('TRYAL-T05', 20, 'ACC-2', WorkDate(), -100);

        MiniJnlPostBatch.PostBatch('TRYAL-T05');

        Assert.AreEqual(2, LineCount('TRYAL-T05'),
            'Expected both journal lines to remain in the batch after posting — posting updates their status, it must not delete them');
        AssertAllLinesHaveStatus('TRYAL-T05', "Mini Journal Status"::Posted);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankAccountNoFailsTheWholeBatch()
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] One line without an account fails the batch with the field-guard error
        CreateLine('TRYAL-T06', 10, 'ACC-1', WorkDate(), 100);
        CreateLine('TRYAL-T06', 20, '', WorkDate(), -100);

        asserterror MiniJnlPostBatch.PostBatch('TRYAL-T06');

        AssertErrorContains('Account No.');
        AssertErrorContains('must have a value');
        Assert.AreEqual(0, LedgerEntryCount('TRYAL-T06'),
            'Expected no ledger entries when a line fails the Account No. guard — a failing batch must write nothing');
        AssertAllLinesHaveStatus('TRYAL-T06', "Mini Journal Status"::Open);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankPostingDateFailsTheWholeBatch()
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] One line without a posting date fails the batch with the field-guard error
        CreateLine('TRYAL-T07', 10, 'ACC-1', WorkDate(), 100);
        CreateLine('TRYAL-T07', 20, 'ACC-2', 0D, -100);

        asserterror MiniJnlPostBatch.PostBatch('TRYAL-T07');

        AssertErrorContains('Posting Date');
        AssertErrorContains('must have a value');
        Assert.AreEqual(0, LedgerEntryCount('TRYAL-T07'),
            'Expected no ledger entries when a line fails the Posting Date guard — a failing batch must write nothing');
        AssertAllLinesHaveStatus('TRYAL-T07', "Mini Journal Status"::Open);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroAmountLineFailsTheWholeBatch()
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A zero-amount line fails the batch even though the batch balances
        CreateLine('TRYAL-T08', 10, 'ACC-1', WorkDate(), 100);
        CreateLine('TRYAL-T08', 20, 'ACC-2', WorkDate(), -100);
        CreateLine('TRYAL-T08', 30, 'ACC-3', WorkDate(), 0);

        asserterror MiniJnlPostBatch.PostBatch('TRYAL-T08');

        AssertErrorContains('Amount');
        AssertErrorContains('must have a value');
        Assert.AreEqual(0, LedgerEntryCount('TRYAL-T08'),
            'Expected no ledger entries when a line fails the Amount guard — a failing batch must write nothing');
        AssertAllLinesHaveStatus('TRYAL-T08', "Mini Journal Status"::Open);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnbalancedBatchFailsWithOutOfBalanceError()
    var
        Any: Codeunit Any;
    begin
        // [SCENARIO] Valid lines whose amounts sum below zero are rejected
        VerifyOutOfBalanceBatchFails('TRYAL-T09', -Any.IntegerInRange(1, 5000) / 100);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneCentImbalanceFailsWithOutOfBalanceError()
    begin
        // [SCENARIO] An imbalance of a single cent is already enough to reject the batch
        VerifyOutOfBalanceBatchFails('TRYAL-T09B', 0.01);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyBatchFailsWithNothingToPost()
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
    begin
        // [SCENARIO] A batch with no lines at all is rejected
        asserterror MiniJnlPostBatch.PostBatch('TRYAL-T10');

        AssertErrorContains('nothing to post');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PostingTheSameBatchTwiceCreatesNoDuplicates()
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Re-posting an already posted batch errors and leaves the ledger unchanged
        CreateLine('TRYAL-T11', 10, 'ACC-1', WorkDate(), 250);
        CreateLine('TRYAL-T11', 20, 'ACC-2', WorkDate(), -250);
        MiniJnlPostBatch.PostBatch('TRYAL-T11');
        // The refused call rolls the database back to the last commit; without
        // this the first posting's entries would vanish together with the rejected one.
        Commit();

        asserterror MiniJnlPostBatch.PostBatch('TRYAL-T11');

        AssertErrorContains('nothing to post');
        Assert.AreEqual(2, LedgerEntryCount('TRYAL-T11'),
            'Expected the second posting attempt to create no duplicate ledger entries');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewOpenLinesPostWithoutDuplicatingPostedOnes()
    var
        MiniLedgerEntry: Record "Mini Ledger Entry";
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Lines added after a post are posted alone on the next run
        CreateLine('TRYAL-T12', 10, 'T12-A', WorkDate(), 60);
        CreateLine('TRYAL-T12', 20, 'T12-B', WorkDate(), -60);
        MiniJnlPostBatch.PostBatch('TRYAL-T12');
        CreateLine('TRYAL-T12', 30, 'T12-C', WorkDate(), 40);
        CreateLine('TRYAL-T12', 40, 'T12-D', WorkDate(), -40);

        MiniJnlPostBatch.PostBatch('TRYAL-T12');

        Assert.AreEqual(4, LedgerEntryCount('TRYAL-T12'),
            'Expected the second run to post only the two new open lines — already-posted lines must not produce ledger entries again');
        MiniLedgerEntry.SetRange("Batch Name", 'TRYAL-T12');
        MiniLedgerEntry.SetRange("Account No.", 'T12-A');
        Assert.AreEqual(1, MiniLedgerEntry.Count(),
            'Expected the line posted in the first run to appear in the ledger exactly once');
        AssertAllLinesHaveStatus('TRYAL-T12', "Mini Journal Status"::Posted);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingScopesEveryCheckToTheGivenBatch()
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Posting one batch ignores a neighbour batch entirely
        // [GIVEN] the neighbour is deliberately unbalanced, so an unscoped balance check fails loudly
        CreateLine('TRYAL-13A', 10, 'ACC-1', WorkDate(), 90);
        CreateLine('TRYAL-13A', 20, 'ACC-2', WorkDate(), -90);
        CreateLine('TRYAL-13B', 10, 'ACC-3', WorkDate(), 77);

        MiniJnlPostBatch.PostBatch('TRYAL-13A');

        Assert.AreEqual(2, LedgerEntryCount('TRYAL-13A'),
            'Expected both lines of the posted batch in the ledger');
        Assert.AreEqual(0, LedgerEntryCount('TRYAL-13B'),
            'Expected no ledger entries for the other batch — posting one batch must not touch another');
        AssertAllLinesHaveStatus('TRYAL-13B', "Mini Journal Status"::Open);
    end;

    local procedure CreateLine(BatchName: Code[10]; LineNo: Integer; AccountNo: Code[20]; PostingDate: Date; LineAmount: Decimal)
    begin
        CreateLine(BatchName, LineNo, AccountNo, PostingDate, '', LineAmount);
    end;

    local procedure CreateLine(BatchName: Code[10]; LineNo: Integer; AccountNo: Code[20]; PostingDate: Date; LineDescription: Text[50]; LineAmount: Decimal)
    var
        MiniJournalLine: Record "Mini Journal Line";
    begin
        MiniJournalLine.Init();
        MiniJournalLine."Batch Name" := BatchName;
        MiniJournalLine."Line No." := LineNo;
        MiniJournalLine."Account No." := AccountNo;
        MiniJournalLine."Posting Date" := PostingDate;
        MiniJournalLine.Description := LineDescription;
        MiniJournalLine.Amount := LineAmount;
        MiniJournalLine.Status := "Mini Journal Status"::Open;
        MiniJournalLine.Insert();
    end;

    local procedure VerifyOutOfBalanceBatchFails(BatchName: Code[10]; Delta: Decimal)
    var
        MiniJnlPostBatch: Codeunit "Mini Jnl.-Post Batch";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        AmountA: Decimal;
    begin
        // A whole-number base amount keeps the imbalance exactly Delta, so a
        // rounded or integer total would see the 0.01 case as balanced and post it.
        AmountA := Any.IntegerInRange(10, 500);
        CreateLine(BatchName, 10, 'ACC-1', WorkDate(), AmountA);
        CreateLine(BatchName, 20, 'ACC-2', WorkDate(), -AmountA + Delta);

        asserterror MiniJnlPostBatch.PostBatch(BatchName);

        AssertErrorContains('out of balance');
        Assert.AreEqual(0, LedgerEntryCount(BatchName),
            'Expected no ledger entries for an out-of-balance batch — a failing batch must write nothing');
        AssertAllLinesHaveStatus(BatchName, "Mini Journal Status"::Open);
    end;

    local procedure SeedLedgerEntry(Offset: Integer): Integer
    var
        MiniLedgerEntry: Record "Mini Ledger Entry";
        SeedEntryNo: Integer;
    begin
        if MiniLedgerEntry.FindLast() then;
        SeedEntryNo := MiniLedgerEntry."Entry No." + Offset;
        MiniLedgerEntry.Init();
        MiniLedgerEntry."Entry No." := SeedEntryNo;
        MiniLedgerEntry."Account No." := 'SEED';
        MiniLedgerEntry.Amount := 1;
        MiniLedgerEntry.Insert();
        exit(SeedEntryNo);
    end;

    local procedure LedgerEntryCount(BatchName: Code[10]): Integer
    var
        MiniLedgerEntry: Record "Mini Ledger Entry";
    begin
        MiniLedgerEntry.SetRange("Batch Name", BatchName);
        exit(MiniLedgerEntry.Count());
    end;

    local procedure LineCount(BatchName: Code[10]): Integer
    var
        MiniJournalLine: Record "Mini Journal Line";
    begin
        MiniJournalLine.SetRange("Batch Name", BatchName);
        exit(MiniJournalLine.Count());
    end;

    local procedure AssertAllLinesHaveStatus(BatchName: Code[10]; ExpectedStatus: Enum "Mini Journal Status")
    var
        MiniJournalLine: Record "Mini Journal Line";
        Assert: Codeunit Assert;
    begin
        MiniJournalLine.SetRange("Batch Name", BatchName);
        if MiniJournalLine.FindSet() then
            repeat
                Assert.AreEqual(Format(ExpectedStatus), Format(MiniJournalLine.Status),
                    StrSubstNo('Expected line %1 of batch %2 to have status %3', MiniJournalLine."Line No.", BatchName, ExpectedStatus));
            until MiniJournalLine.Next() = 0;
    end;

    local procedure AssertErrorContains(Fragment: Text)
    var
        Assert: Codeunit Assert;
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains(LowerCase(Fragment)),
            StrSubstNo('Expected the posting error to contain "%1", got: %2', Fragment, ActualError));
    end;
}
