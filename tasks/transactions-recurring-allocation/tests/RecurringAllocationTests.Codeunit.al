// Grading tests. Every test builds a journal through the submitted codeunit and
// then posts that batch with the standard "Gen. Jnl.-Post Batch" routine, exactly
// as a user would from the Recurring General Journals page. Nothing of the
// submission runs during posting: what is graded is the journal setup it left
// behind, read back from the posted G/L entries and from the journal itself.
//
// Posting commits — hence transactionModel: committed and companyIsolation: fresh
// in metadata.yaml. Each test owns a template name, a batch name and freshly
// created G/L accounts and dimension values, so tests never see each other's data.
codeunit 50900 "Recurring Allocation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Standard posting commits on its own; CommitBehavior::Ignore on every test
    // silences those commits so the run stays rollback-safe and can grade in the
    // shared warm company.

    // [FEATURE] [Recurring Journal] [Allocation]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure OneRunSplitsTheRentAcrossTheDepartments()
    var
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        PostingDate: Date;
        RentAmount: Decimal;
        SharePct: Decimal;
        AccrualAccountNo: Code[20];
        ExpenseAccountNo: Code[20];
        FirstDepartment: Code[20];
        SecondDepartment: Code[20];
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] The department shares balance the accrual line, each with its own share of the amount and its own department
        // [GIVEN] A rent accrual split over two departments by percentage
        Initialize('TRYALRA01');
        Evaluate(Frequency, '<1W>');
        PostingDate := CalcDate('<-14D>', WorkDate());
        RentAmount := -LibraryRandom.RandIntInRange(500, 2000);
        SharePct := LibraryRandom.RandIntInRange(10, 90);
        AccrualAccountNo := NewAccountNo();
        ExpenseAccountNo := NewAccountNo();
        FirstDepartment := NewDepartmentCode();
        SecondDepartment := NewDepartmentCode();
        RecurringRentAccrual.CreateAccrualBatch('TRYALRA01', 'RENT01');
        AccrualLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                'TRYALRA01', 'RENT01', 'RENT-01', PostingDate, AccrualAccountNo, RentAmount,
                Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, 0D);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA01', 'RENT01', AccrualLineNo, ExpenseAccountNo, FirstDepartment, SharePct);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA01', 'RENT01', AccrualLineNo, ExpenseAccountNo, SecondDepartment, 100 - SharePct);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA01', 'RENT01');

        // [THEN] Each department carries its own slice of the rent, opposite in sign to the accrual line
        Assert.AreEqual(-RentAmount * SharePct / 100, EntrySum('RENT01', ExpenseAccountNo, 0D, FirstDepartment),
            StrSubstNo('Expected the first department (%1) to carry its share of the rent on the expense account, with the opposite sign of the accrual line', FirstDepartment));
        Assert.AreEqual(-RentAmount * (100 - SharePct) / 100, EntrySum('RENT01', ExpenseAccountNo, 0D, SecondDepartment),
            StrSubstNo('Expected the second department (%1) to carry the rest of the rent on the expense account', SecondDepartment));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure OneRunPostsTheAccrualLineAndNothingElse()
    var
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        PostingDate: Date;
        RentAmount: Decimal;
        AccrualAccountNo: Code[20];
        ExpenseAccountNo: Code[20];
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] A run posts the accrual line plus one entry per share, all on the line's date and document number
        // [GIVEN] A rent accrual split over two departments
        Initialize('TRYALRA02');
        Evaluate(Frequency, '<1W>');
        PostingDate := CalcDate('<-14D>', WorkDate());
        RentAmount := -LibraryRandom.RandIntInRange(500, 2000);
        AccrualAccountNo := NewAccountNo();
        ExpenseAccountNo := NewAccountNo();
        RecurringRentAccrual.CreateAccrualBatch('TRYALRA02', 'RENT02');
        AccrualLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                'TRYALRA02', 'RENT02', 'RENT-02', PostingDate, AccrualAccountNo, RentAmount,
                Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, 0D);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA02', 'RENT02', AccrualLineNo, ExpenseAccountNo, NewDepartmentCode(), 60);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA02', 'RENT02', AccrualLineNo, ExpenseAccountNo, NewDepartmentCode(), 40);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA02', 'RENT02');

        // [THEN] The accrual account took the whole amount, on the line's posting date, and no fourth entry was created
        Assert.AreEqual(RentAmount, EntrySum('RENT02', AccrualAccountNo, PostingDate, ''),
            'Expected the whole accrual amount on the accrual account, dated with the line''s posting date');
        Assert.AreEqual(3, EntryCount('RENT02', AccountFilter(AccrualAccountNo, ExpenseAccountNo), ''),
            'Expected exactly three ledger entries from one run — the accrual line plus one entry per department share');
        Assert.AreEqual(3, EntryCount('RENT02', AccountFilter(AccrualAccountNo, ExpenseAccountNo), 'RENT-02'),
            'Expected all three entries to carry the document number the accrual line was given');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure PostingTheBatchAgainPostsTheNextPeriodOnItsOwn()
    var
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        PostingDate: Date;
        SecondRunDate: Date;
        RentAmount: Decimal;
        SharePct: Decimal;
        AccrualAccountNo: Code[20];
        ExpenseAccountNo: Code[20];
        FirstDepartment: Code[20];
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] A second posting run repeats the whole accrual one frequency later, untouched in between
        // [GIVEN] A rent accrual that has already been posted once
        Initialize('TRYALRA03');
        Evaluate(Frequency, '<1W>');
        PostingDate := CalcDate('<-14D>', WorkDate());
        SecondRunDate := CalcDate(Frequency, PostingDate);
        RentAmount := -LibraryRandom.RandIntInRange(500, 2000);
        SharePct := LibraryRandom.RandIntInRange(10, 90);
        AccrualAccountNo := NewAccountNo();
        ExpenseAccountNo := NewAccountNo();
        FirstDepartment := NewDepartmentCode();
        RecurringRentAccrual.CreateAccrualBatch('TRYALRA03', 'RENT03');
        AccrualLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                'TRYALRA03', 'RENT03', 'RENT-03', PostingDate, AccrualAccountNo, RentAmount,
                Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, 0D);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA03', 'RENT03', AccrualLineNo, ExpenseAccountNo, FirstDepartment, SharePct);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA03', 'RENT03', AccrualLineNo, ExpenseAccountNo, NewDepartmentCode(), 100 - SharePct);
        PostBatch('TRYALRA03', 'RENT03');

        // [WHEN] The very same batch is posted a second time, with nothing touched in between
        PostBatch('TRYALRA03', 'RENT03');

        // [THEN] The whole accrual is posted again, one frequency later
        Assert.AreEqual(RentAmount, EntrySum('RENT03', AccrualAccountNo, SecondRunDate, ''),
            'Expected the second run to post the accrual again, dated one recurring frequency after the first run');
        Assert.AreEqual(-RentAmount * SharePct / 100, EntrySum('RENT03', ExpenseAccountNo, SecondRunDate, FirstDepartment),
            'Expected the second run to repeat the department split by itself — the journal must not need any editing between runs');
        Assert.AreEqual(6, EntryCount('RENT03', AccountFilter(AccrualAccountNo, ExpenseAccountNo), ''),
            'Expected six ledger entries after two runs — three per run, and nothing posted twice');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure PostingMovesTheLineOnByItsRecurringFrequency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        PostingDate: Date;
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] After a run the line waits on the next due date instead of leaving the journal
        // [GIVEN] A monthly rent accrual
        Initialize('TRYALRA04');
        Evaluate(Frequency, '<1M>');
        PostingDate := CalcDate('<-14D>', WorkDate());
        AccrualLineNo := BuildSingleShareAccrual('TRYALRA04', 'RENT04', 'RENT-04', PostingDate,
            -LibraryRandom.RandIntInRange(500, 2000), Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, 0D);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA04', 'RENT04');

        // [THEN] The line is still there, dated one frequency later
        GetJournalLine('TRYALRA04', 'RENT04', AccrualLineNo, GenJournalLine);
        Assert.AreEqual(CalcDate(Frequency, PostingDate), GenJournalLine."Posting Date",
            'Expected the posted line to be waiting on its next due date — its old posting date moved on by the recurring frequency');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure FixedKeepsTheAmountOnTheLineForTheNextRun()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        RentAmount: Decimal;
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] A Fixed line keeps its amount after posting
        // [GIVEN] A rent accrual posted with the Fixed recurring method
        Initialize('TRYALRA05');
        Evaluate(Frequency, '<1W>');
        RentAmount := -LibraryRandom.RandIntInRange(500, 2000);
        AccrualLineNo := BuildSingleShareAccrual('TRYALRA05', 'RENT05', 'RENT-05', CalcDate('<-14D>', WorkDate()),
            RentAmount, Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, 0D);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA05', 'RENT05');

        // [THEN] The amount survived the run
        GetJournalLine('TRYALRA05', 'RENT05', AccrualLineNo, GenJournalLine);
        Assert.AreEqual(RentAmount, GenJournalLine.Amount,
            'Expected a Fixed line to keep its amount after posting, ready to post the same rent again');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure VariableClearsTheAmountAfterPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] A Variable line comes back empty, waiting for next period's amount
        // [GIVEN] A rent accrual posted with the Variable recurring method
        Initialize('TRYALRA06');
        Evaluate(Frequency, '<1W>');
        AccrualLineNo := BuildSingleShareAccrual('TRYALRA06', 'RENT06', 'RENT-06', CalcDate('<-14D>', WorkDate()),
            -LibraryRandom.RandIntInRange(500, 2000), Enum::"Gen. Journal Recurring Method"::"V  Variable", Frequency, 0D);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA06', 'RENT06');

        // [THEN] The line is still in the journal, but its amount is gone
        GetJournalLine('TRYALRA06', 'RENT06', AccrualLineNo, GenJournalLine);
        Assert.AreEqual(0.0, GenJournalLine.Amount,
            'Expected a Variable line to come back with its amount cleared after posting, while the line itself stays in the journal');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReversingFixedPostsTheMirrorEntriesTheNextDay()
    var
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        PostingDate: Date;
        RentAmount: Decimal;
        AccrualAccountNo: Code[20];
        ExpenseAccountNo: Code[20];
        FirstDepartment: Code[20];
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] A Reversing Fixed accrual is booked and reversed out on the following day
        // [GIVEN] A rent accrual split 75/25 and posted with the Reversing Fixed recurring method
        Initialize('TRYALRA07');
        Evaluate(Frequency, '<1W>');
        PostingDate := CalcDate('<-14D>', WorkDate());
        RentAmount := -LibraryRandom.RandIntInRange(500, 2000);
        AccrualAccountNo := NewAccountNo();
        ExpenseAccountNo := NewAccountNo();
        FirstDepartment := NewDepartmentCode();
        RecurringRentAccrual.CreateAccrualBatch('TRYALRA07', 'RENT07');
        AccrualLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                'TRYALRA07', 'RENT07', 'RENT-07', PostingDate, AccrualAccountNo, RentAmount,
                Enum::"Gen. Journal Recurring Method"::"RF Reversing Fixed", Frequency, 0D);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA07', 'RENT07', AccrualLineNo, ExpenseAccountNo, FirstDepartment, 75);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA07', 'RENT07', AccrualLineNo, ExpenseAccountNo, NewDepartmentCode(), 25);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA07', 'RENT07');

        // [THEN] Everything posted on the posting date comes back mirrored on the day after
        Assert.AreEqual(RentAmount, EntrySum('RENT07', AccrualAccountNo, PostingDate, ''),
            'Expected the accrual itself on the line''s posting date');
        Assert.AreEqual(-RentAmount, EntrySum('RENT07', AccrualAccountNo, PostingDate + 1, ''),
            'Expected the accrual account reversed on the day after the posting date');
        Assert.AreEqual(RentAmount * 75 / 100, EntrySum('RENT07', ExpenseAccountNo, PostingDate + 1, FirstDepartment),
            'Expected the department share reversed on the day after as well, department and all');
        Assert.AreEqual(0.0, EntrySum('RENT07', ExpenseAccountNo, 0D, ''),
            'Expected the expense account to net to zero over the two days — a reversing accrual leaves no balance behind');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ALinePastItsExpirationDatePostsNothing()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        LiveDate: Date;
        ExpiredDate: Date;
        LiveAccountNo: Code[20];
        ExpiredAccountNo: Code[20];
        ExpenseAccountNo: Code[20];
        LiveLineNo: Integer;
        ExpiredLineNo: Integer;
    begin
        // [SCENARIO] An expired line posts nothing and does not move, while its neighbour in the batch posts as usual
        // [GIVEN] A batch with a live accrual and one whose expiration date is a day behind its posting date
        Initialize('TRYALRA08');
        Evaluate(Frequency, '<1W>');
        LiveDate := CalcDate('<-14D>', WorkDate());
        ExpiredDate := CalcDate('<-10D>', WorkDate());
        LiveAccountNo := NewAccountNo();
        ExpiredAccountNo := NewAccountNo();
        ExpenseAccountNo := NewAccountNo();
        RecurringRentAccrual.CreateAccrualBatch('TRYALRA08', 'RENT08');
        LiveLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                'TRYALRA08', 'RENT08', 'RENT-08A', LiveDate, LiveAccountNo, -LibraryRandom.RandIntInRange(500, 2000),
                Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, 0D);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA08', 'RENT08', LiveLineNo, ExpenseAccountNo, NewDepartmentCode(), 100);
        ExpiredLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                'TRYALRA08', 'RENT08', 'RENT-08B', ExpiredDate, ExpiredAccountNo, -LibraryRandom.RandIntInRange(500, 2000),
                Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, ExpiredDate - 1);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA08', 'RENT08', ExpiredLineNo, ExpenseAccountNo, NewDepartmentCode(), 100);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA08', 'RENT08');

        // [THEN] The expired line posted nothing and kept its date; the live line posted
        Assert.AreEqual(0, EntryCount('RENT08', ExpiredAccountNo, ''),
            'Expected no ledger entry at all for the line whose posting date is past its expiration date');
        GetJournalLine('TRYALRA08', 'RENT08', ExpiredLineNo, GenJournalLine);
        Assert.AreEqual(ExpiredDate, GenJournalLine."Posting Date",
            'Expected the expired line to stay exactly where it is — a line that posts nothing must not move on by its frequency either');
        Assert.AreEqual(1, EntryCount('RENT08', LiveAccountNo, ''),
            'Expected the live line in the same batch to post normally next to the expired one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ALineOnItsExpirationDateStillPosts()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Frequency: DateFormula;
        PostingDate: Date;
        RentAmount: Decimal;
        AccrualAccountNo: Code[20];
        ExpenseAccountNo: Code[20];
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] The expiration date is the last date the line may post, so a run dated exactly on it still posts
        // [GIVEN] A rent accrual whose posting date is its expiration date to the day
        Initialize('TRYALRA10');
        Evaluate(Frequency, '<1W>');
        PostingDate := CalcDate('<-14D>', WorkDate());
        RentAmount := -LibraryRandom.RandIntInRange(500, 2000);
        AccrualAccountNo := NewAccountNo();
        ExpenseAccountNo := NewAccountNo();
        RecurringRentAccrual.CreateAccrualBatch('TRYALRA10', 'RENT10');
        AccrualLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                'TRYALRA10', 'RENT10', 'RENT-10', PostingDate, AccrualAccountNo, RentAmount,
                Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, PostingDate);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA10', 'RENT10', AccrualLineNo, ExpenseAccountNo, NewDepartmentCode(), 100);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA10', 'RENT10');

        // [THEN] The accrual posted on that last allowed date, and the line moved on afterwards like any other run
        Assert.AreEqual(RentAmount, EntrySum('RENT10', AccrualAccountNo, PostingDate, ''),
            'Expected a line dated exactly on its expiration date to still post — the expiration date is the last date the line may post, not the first date it is blocked');
        Assert.AreEqual(1, EntryCount('RENT10', AccrualAccountNo, ''),
            'Expected exactly one accrual entry from the run on the expiration date');
        GetJournalLine('TRYALRA10', 'RENT10', AccrualLineNo, GenJournalLine);
        Assert.AreEqual(CalcDate(Frequency, PostingDate), GenJournalLine."Posting Date",
            'Expected the line that posted on its expiration date to move on by its recurring frequency, past the expiration date it has now used up');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure PercentageSharesLeaveNoRoundingResidual()
    var
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        Assert: Codeunit Assert;
        Frequency: DateFormula;
        PostingDate: Date;
        RentAmount: Decimal;
        AccrualAccountNo: Code[20];
        ExpenseAccountNo: Code[20];
        FirstDepartment: Code[20];
        AccrualLineNo: Integer;
    begin
        // [SCENARIO] Percentages that do not divide evenly still cover the accrual to the cent
        // [GIVEN] 100.01 of rent split 33.33 / 33.33 / 33.34 over three departments
        Initialize('TRYALRA09');
        Evaluate(Frequency, '<1W>');
        PostingDate := CalcDate('<-14D>', WorkDate());
        RentAmount := -100.01;
        AccrualAccountNo := NewAccountNo();
        ExpenseAccountNo := NewAccountNo();
        FirstDepartment := NewDepartmentCode();
        RecurringRentAccrual.CreateAccrualBatch('TRYALRA09', 'RENT09');
        AccrualLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                'TRYALRA09', 'RENT09', 'RENT-09', PostingDate, AccrualAccountNo, RentAmount,
                Enum::"Gen. Journal Recurring Method"::"F  Fixed", Frequency, 0D);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA09', 'RENT09', AccrualLineNo, ExpenseAccountNo, FirstDepartment, 33.33);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA09', 'RENT09', AccrualLineNo, ExpenseAccountNo, NewDepartmentCode(), 33.33);
        RecurringRentAccrual.AddDepartmentShare('TRYALRA09', 'RENT09', AccrualLineNo, ExpenseAccountNo, NewDepartmentCode(), 33.34);

        // [WHEN] The batch is posted
        PostBatch('TRYALRA09', 'RENT09');

        // [THEN] The three shares add up to the whole rent, each within a cent of a third
        Assert.AreEqual(-RentAmount, EntrySum('RENT09', ExpenseAccountNo, 0D, ''),
            'Expected the three department shares to add up to the whole rent — an uneven percentage split may not lose or invent a cent');
        Assert.AreNearlyEqual(-RentAmount / 3, EntrySum('RENT09', ExpenseAccountNo, 0D, FirstDepartment), 0.01,
            'Expected the first department to carry about a third of the rent');
        Assert.AreEqual(RentAmount, EntrySum('RENT09', AccrualAccountNo, 0D, ''),
            'Expected the accrual account to carry the whole rent as the counterpart of the three shares');
    end;

    local procedure Initialize(TemplateName: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        // The fixtures post up to two weeks either side of the work date; a grading
        // company with "Allow Posting From/To" restrictions would reject those dates
        // before anything of the submission is graded.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := 0D;
        GeneralLedgerSetup."Allow Posting To" := 0D;
        GeneralLedgerSetup.Modify();
        if UserSetup.Get(UserId()) then begin
            UserSetup."Allow Posting From" := 0D;
            UserSetup."Allow Posting To" := 0D;
            UserSetup.Modify();
        end;

        // Posting commits, so a company that grades twice would still hold the
        // previous run's journal. Every test starts from a template that does not exist.
        GenJnlAllocation.SetRange("Journal Template Name", TemplateName);
        GenJnlAllocation.DeleteAll();
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.DeleteAll();
        GenJournalBatch.SetRange("Journal Template Name", TemplateName);
        GenJournalBatch.DeleteAll();
        if GenJournalTemplate.Get(TemplateName) then
            GenJournalTemplate.Delete();
    end;

    local procedure BuildSingleShareAccrual(TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date; RentAmount: Decimal; Method: Enum "Gen. Journal Recurring Method"; Frequency: DateFormula; ExpirationDate: Date): Integer
    var
        RecurringRentAccrual: Codeunit "Recurring Rent Accrual";
        AccrualLineNo: Integer;
    begin
        RecurringRentAccrual.CreateAccrualBatch(TemplateName, BatchName);
        AccrualLineNo :=
            RecurringRentAccrual.AddAccrualLine(
                TemplateName, BatchName, DocumentNo, PostingDate, NewAccountNo(), RentAmount, Method, Frequency, ExpirationDate);
        RecurringRentAccrual.AddDepartmentShare(TemplateName, BatchName, AccrualLineNo, NewAccountNo(), NewDepartmentCode(), 100);
        exit(AccrualLineNo);
    end;

    local procedure PostBatch(TemplateName: Code[10]; BatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
    begin
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        Assert.IsTrue(GenJournalLine.FindFirst(),
            StrSubstNo('Expected journal lines in batch %1 of template %2 — the batch has to hold the accrual line before it can be posted, and every run has to leave its lines behind for the next one', BatchName, TemplateName));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetJournalLine(TemplateName: Code[10]; BatchName: Code[10]; LineNo: Integer; var GenJournalLine: Record "Gen. Journal Line")
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(GenJournalLine.Get(TemplateName, BatchName, LineNo),
            StrSubstNo('Expected journal line %1 of batch %2 to still exist after posting — a recurring run keeps its lines instead of consuming them', LineNo, BatchName));
    end;

    local procedure EntrySum(BatchName: Code[10]; AccountNo: Code[20]; PostingDate: Date; DepartmentCode: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Journal Batch Name", BatchName);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        if PostingDate <> 0D then
            GLEntry.SetRange("Posting Date", PostingDate);
        if DepartmentCode <> '' then
            GLEntry.SetRange("Global Dimension 1 Code", DepartmentCode);
        GLEntry.CalcSums(Amount);
        exit(GLEntry.Amount);
    end;

    local procedure EntryCount(BatchName: Code[10]; AccountNoFilter: Text; DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Journal Batch Name", BatchName);
        GLEntry.SetFilter("G/L Account No.", AccountNoFilter);
        if DocumentNo <> '' then
            GLEntry.SetRange("Document No.", DocumentNo);
        exit(GLEntry.Count());
    end;

    local procedure AccountFilter(FirstAccountNo: Code[20]; SecondAccountNo: Code[20]): Text
    begin
        exit(StrSubstNo('%1|%2', FirstAccountNo, SecondAccountNo));
    end;

    local procedure NewAccountNo(): Code[20]
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        exit(LibraryERM.CreateGLAccountNoWithDirectPosting());
    end;

    local procedure NewDepartmentCode(): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        exit(DimensionValue.Code);
    end;
}
