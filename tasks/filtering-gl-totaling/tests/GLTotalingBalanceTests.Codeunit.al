codeunit 50900 "G/L Totaling Balance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The fixtures post through "Gen. Jnl.-Post Batch", which commits on its
    // own; CommitBehavior::Ignore keeps every test on the auto-rollback path.

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RangeTotalsEveryPostingAccountInsideIt()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLTotalingBalance: Codeunit "G/L Totaling Balance";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LowAmount: Decimal;
        MiddleAmount: Decimal;
        HighAmount: Decimal;
    begin
        // [GIVEN] three posting accounts inside TRYAL-T1-1000..TRYAL-T1-1998, one just outside, and a Total line over the range
        CreateAccount('TRYAL-T1-1000', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T1-1500', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T1-1998', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T1-2500', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T1-1999', "G/L Account Type"::Total, 'TRYAL-T1-1000..TRYAL-T1-1998');
        LowAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        MiddleAmount := -LibraryRandom.RandDecInRange(10, 90, 2);
        HighAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        OpenJournal(GenJournalBatch, 'TRYAL-T1-BAL');
        AddJournalLine(GenJournalBatch, 'TRYAL-T1-1000', LowAmount, WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T1-1500', MiddleAmount, WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T1-1998', HighAmount, WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T1-2500', LibraryRandom.RandDecInRange(100, 200, 2), WorkDate());
        PostJournal(GenJournalBatch);

        // [WHEN] evaluating the Total line over a window around the posting date
        // [THEN] the three accounts inside the range are summed with their signs; the account outside is not
        Assert.AreEqual(LowAmount + MiddleAmount + HighAmount,
            GLTotalingBalance.TotalingBalance('TRYAL-T1-1999', WorkDate() - 5, WorkDate() + 5),
            'Expected the signed sum of the three posting accounts inside TRYAL-T1-1000..TRYAL-T1-1998 — the account just outside the range must not count, and the negative entry must reduce the figure');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UnionAddsTheListedAccountToTheRange()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLTotalingBalance: Codeunit "G/L Totaling Balance";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        FirstRangeAmount: Decimal;
        SecondRangeAmount: Decimal;
        ListedAmount: Decimal;
    begin
        // [GIVEN] two posting accounts inside the range, one listed after the pipe, and one between the two parts
        CreateAccount('TRYAL-T2-1000', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T2-1500', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T2-2200', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T2-2500', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T2-2999', "G/L Account Type"::Total, 'TRYAL-T2-1000..TRYAL-T2-1999|TRYAL-T2-2500');
        FirstRangeAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        SecondRangeAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        ListedAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        OpenJournal(GenJournalBatch, 'TRYAL-T2-BAL');
        AddJournalLine(GenJournalBatch, 'TRYAL-T2-1000', FirstRangeAmount, WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T2-1500', SecondRangeAmount, WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T2-2200', LibraryRandom.RandDecInRange(100, 200, 2), WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T2-2500', ListedAmount, WorkDate());
        PostJournal(GenJournalBatch);

        // [WHEN] evaluating the Total line whose Totaling is a range joined with a single account
        // [THEN] both parts of the union count; the account between them does not
        Assert.AreEqual(FirstRangeAmount + SecondRangeAmount + ListedAmount,
            GLTotalingBalance.TotalingBalance('TRYAL-T2-2999', WorkDate() - 5, WorkDate() + 5),
            'Expected the two accounts inside TRYAL-T2-1000..TRYAL-T2-1999 plus the single account TRYAL-T2-2500 — the | joins both parts, and TRYAL-T2-2200 lies in neither');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure NonPostingAccountsInsideTheRangeContributeNothing()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLTotalingBalance: Codeunit "G/L Totaling Balance";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        FirstAmount: Decimal;
        SecondAmount: Decimal;
    begin
        // [GIVEN] a Heading and a Begin-Total inside the range, next to two posting accounts with entries
        CreateAccount('TRYAL-T3-1000', "G/L Account Type"::Heading, '');
        CreateAccount('TRYAL-T3-1100', "G/L Account Type"::"Begin-Total", '');
        CreateAccount('TRYAL-T3-1200', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T3-1300', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T3-1999', "G/L Account Type"::Total, 'TRYAL-T3-1000..TRYAL-T3-1998');
        FirstAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        SecondAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        OpenJournal(GenJournalBatch, 'TRYAL-T3-BAL');
        AddJournalLine(GenJournalBatch, 'TRYAL-T3-1200', FirstAmount, WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T3-1300', SecondAmount, WorkDate());
        PostJournal(GenJournalBatch);

        // [WHEN] evaluating the Total line over the range
        // [THEN] the figure is exactly the two posting accounts; the Heading and Begin-Total neither add anything nor break the evaluation
        Assert.AreEqual(FirstAmount + SecondAmount,
            GLTotalingBalance.TotalingBalance('TRYAL-T3-1999', WorkDate() - 5, WorkDate() + 5),
            'Expected exactly the sum of the two posting accounts — the Heading and Begin-Total inside the range have no entries and must simply be skipped, not counted and not rejected');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure EndTotalEmbracingATotalCountsEachEntryOnce()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLTotalingBalance: Codeunit "G/L Totaling Balance";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        FirstAmount: Decimal;
        SecondAmount: Decimal;
        ThirdAmount: Decimal;
    begin
        // [GIVEN] a Total line over the first two posting accounts, and an End-Total whose range embraces that Total line, a third posting account and its own number
        CreateAccount('TRYAL-T4-1000', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T4-1100', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T4-1199', "G/L Account Type"::Total, 'TRYAL-T4-1000..TRYAL-T4-1100');
        CreateAccount('TRYAL-T4-1500', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T4-1999', "G/L Account Type"::"End-Total", 'TRYAL-T4-1000..TRYAL-T4-1999');
        FirstAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        SecondAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        ThirdAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        OpenJournal(GenJournalBatch, 'TRYAL-T4-BAL');
        AddJournalLine(GenJournalBatch, 'TRYAL-T4-1000', FirstAmount, WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T4-1100', SecondAmount, WorkDate());
        AddJournalLine(GenJournalBatch, 'TRYAL-T4-1500', ThirdAmount, WorkDate());
        PostJournal(GenJournalBatch);

        // [WHEN] evaluating the End-Total line
        // [THEN] each posting entry is counted once — the embraced Total line is not added on top of the accounts it summarises
        Assert.AreEqual(FirstAmount + SecondAmount + ThirdAmount,
            GLTotalingBalance.TotalingBalance('TRYAL-T4-1999', WorkDate() - 5, WorkDate() + 5),
            'Expected each posting entry exactly once — the Total line TRYAL-T4-1199 inside the End-Total''s range already summarises TRYAL-T4-1000 and TRYAL-T4-1100 and must not be added on top of them (and the End-Total must not add itself either)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure BlankTotalingReturnsZeroEvenWithOwnEntries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLTotalingBalance: Codeunit "G/L Totaling Balance";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
    begin
        // [GIVEN] a posting account with a blank Totaling, a posted entry of its own inside the window, and one unbalanced entry that keeps the whole ledger from netting to zero over the window
        CreateAccount('TRYAL-T5-1000', "G/L Account Type"::Posting, '');
        OpenJournal(GenJournalBatch, 'TRYAL-T5-BAL');
        AddJournalLine(GenJournalBatch, 'TRYAL-T5-1000', LibraryRandom.RandDecInRange(100, 200, 2), WorkDate());
        PostJournal(GenJournalBatch);
        InsertUnbalancedGLEntry('TRYAL-T5-1000', LibraryRandom.RandDecInRange(100, 200, 2), WorkDate());

        // [WHEN] evaluating that account as if it were a total line
        // [THEN] a blank Totaling totals nothing
        Assert.AreEqual(0.0,
            GLTotalingBalance.TotalingBalance('TRYAL-T5-1000', WorkDate() - 5, WorkDate() + 5),
            'Expected 0 for an account whose Totaling is blank — the procedure evaluates the Totaling expression, never the account''s own entries, and an empty expression names no accounts. A non-zero figure here usually means the blank expression was handed to the account filter as-is, which removes the filter and sums the whole chart instead of matching nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure DateWindowIncludesBothBoundaryDaysAndNothingOutside()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLTotalingBalance: Codeunit "G/L Totaling Balance";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        FromDate: Date;
        ToDate: Date;
        FromDayAmount: Decimal;
        ToDayAmount: Decimal;
    begin
        // [GIVEN] entries on FromDate and ToDate, and one entry just outside each boundary
        FromDate := WorkDate() - 3;
        ToDate := WorkDate() + 3;
        CreateAccount('TRYAL-T6-1000', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T6-1500', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T6-1999', "G/L Account Type"::Total, 'TRYAL-T6-1000..TRYAL-T6-1998');
        FromDayAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        ToDayAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        OpenJournal(GenJournalBatch, 'TRYAL-T6-BAL');
        AddJournalLine(GenJournalBatch, 'TRYAL-T6-1000', LibraryRandom.RandDecInRange(100, 200, 2), FromDate - 1);
        AddJournalLine(GenJournalBatch, 'TRYAL-T6-1000', FromDayAmount, FromDate);
        AddJournalLine(GenJournalBatch, 'TRYAL-T6-1500', ToDayAmount, ToDate);
        AddJournalLine(GenJournalBatch, 'TRYAL-T6-1500', LibraryRandom.RandDecInRange(100, 200, 2), ToDate + 1);
        PostJournal(GenJournalBatch);

        // [WHEN] evaluating the Total line for exactly FromDate..ToDate
        // [THEN] the entries on the boundary days count and the entries one day outside do not
        Assert.AreEqual(FromDayAmount + ToDayAmount,
            GLTotalingBalance.TotalingBalance('TRYAL-T6-1999', FromDate, ToDate),
            'Expected the entries posted exactly on FromDate and exactly on ToDate to count, and the entries one day outside each boundary not to — the window narrows the figure and includes both boundary days');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure WindowWithNoEntriesReturnsZero()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLTotalingBalance: Codeunit "G/L Totaling Balance";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
    begin
        // [GIVEN] a Total line over a posting account whose only entry lies before the window
        CreateAccount('TRYAL-T7-1000', "G/L Account Type"::Posting, '');
        CreateAccount('TRYAL-T7-1999', "G/L Account Type"::Total, 'TRYAL-T7-1000..TRYAL-T7-1998');
        OpenJournal(GenJournalBatch, 'TRYAL-T7-BAL');
        AddJournalLine(GenJournalBatch, 'TRYAL-T7-1000', LibraryRandom.RandDecInRange(100, 200, 2), WorkDate());
        PostJournal(GenJournalBatch);

        // [WHEN] evaluating the Total line for a window that starts the day after the entry
        // [THEN] the answer is 0, not an error and not the entry outside the window
        Assert.AreEqual(0.0,
            GLTotalingBalance.TotalingBalance('TRYAL-T7-1999', WorkDate() + 1, WorkDate() + 10),
            'Expected 0 for a window that contains none of the totaled accounts'' entries — the entry posted before FromDate must not leak in');
    end;

    // The account numbers are the subject of the Totaling expressions under test,
    // so they are fixed per test instead of generated by "Library - ERM".
    local procedure CreateAccount(No: Code[20]; AccountType: Enum "G/L Account Type"; TotalingText: Text)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", No);
        GLAccount.Validate(Name, No);
        GLAccount.Validate("Account Type", AccountType);
        GLAccount.Insert(true);
        if TotalingText <> '' then begin
            GLAccount.Validate(Totaling, CopyStr(TotalingText, 1, MaxStrLen(GLAccount.Totaling)));
            GLAccount.Modify(true);
        end;
    end;

    local procedure OpenJournal(var GenJournalBatch: Record "Gen. Journal Batch"; BalancingAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        LibraryERM: Codeunit "Library - ERM";
    begin
        EnsureAnyPostingDateAllowed();
        // The balancing account sorts after every TRYAL-Tn-dddd number, so it never
        // falls inside a Totaling expression under test.
        CreateAccount(BalancingAccountNo, "G/L Account Type"::Posting, '');
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", BalancingAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure EnsureAnyPostingDateAllowed()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
    begin
        // The fixtures post a few days either side of the work date; a grading company
        // with "Allow Posting From/To" restrictions would reject those dates before the
        // graded code ever runs. Lifted only inside the test transaction (auto-rollback).
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := 0D;
        GeneralLedgerSetup."Allow Posting To" := 0D;
        GeneralLedgerSetup.Modify();
        if UserSetup.Get(UserId()) then begin
            UserSetup."Allow Posting From" := 0D;
            UserSetup."Allow Posting To" := 0D;
            UserSetup.Modify();
        end;
    end;

    local procedure AddJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; EntryAmount: Decimal; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo, EntryAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure PostJournal(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    // Every posting balances within its posting date, so a filter-less scan of the
    // whole chart nets to exactly 0 over any window — the same figure a correct blank
    // guard returns. One entry written without a counterpart breaks that symmetry.
    local procedure InsertUnbalancedGLEntry(AccountNo: Code[20]; EntryAmount: Decimal; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := NextGLEntryNo();
        GLEntry."G/L Account No." := AccountNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Amount := EntryAmount;
        GLEntry."Debit Amount" := EntryAmount;
        GLEntry.Insert();
    end;

    local procedure NextGLEntryNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast() then
            exit(GLEntry."Entry No." + 1);
        exit(1);
    end;
}
