codeunit 50900 "Customer Balance Window Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The fixtures post through "Gen. Jnl.-Post Batch", which commits on its
    // own; CommitBehavior::Ignore keeps every test on the auto-rollback path.

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ChangeBetweenCountsOnlyEntriesInsideTheWindow()
    var
        CustomerBalanceWindow: Codeunit "Customer Balance Window";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
        InsideAmount: Decimal;
    begin
        CustomerNo := CreateCustomerNo();
        InsideAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        PostAmountOnDate(CustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate() - 10);
        PostAmountOnDate(CustomerNo, InsideAmount, WorkDate());
        PostAmountOnDate(CustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate() + 10);

        Assert.AreEqual(InsideAmount, CustomerBalanceWindow.BalanceChangeBetween(CustomerNo, WorkDate() - 5, WorkDate() + 5),
            'Expected only the entry posted inside the window — entries before FromDate and after ToDate must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ChangeBetweenIncludesBothBoundaryDays()
    var
        CustomerBalanceWindow: Codeunit "Customer Balance Window";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
        FromDayAmount: Decimal;
        ToDayAmount: Decimal;
    begin
        CustomerNo := CreateCustomerNo();
        FromDayAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        ToDayAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        PostAmountOnDate(CustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate() - 9);
        PostAmountOnDate(CustomerNo, FromDayAmount, WorkDate() - 8);
        PostAmountOnDate(CustomerNo, ToDayAmount, WorkDate() + 8);
        PostAmountOnDate(CustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate() + 9);

        Assert.AreEqual(FromDayAmount + ToDayAmount, CustomerBalanceWindow.BalanceChangeBetween(CustomerNo, WorkDate() - 8, WorkDate() + 8),
            'Expected the entries posted exactly on FromDate and exactly on ToDate to count, and the entries one day outside each boundary not to');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ChangeBetweenCoveringEveryEntryReturnsTheFullBalance()
    var
        CustomerBalanceWindow: Codeunit "Customer Balance Window";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
        FirstAmount: Decimal;
        SecondAmount: Decimal;
        ThirdAmount: Decimal;
    begin
        CustomerNo := CreateCustomerNo();
        FirstAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        SecondAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        ThirdAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        PostAmountOnDate(CustomerNo, FirstAmount, WorkDate() - 10);
        PostAmountOnDate(CustomerNo, SecondAmount, WorkDate());
        PostAmountOnDate(CustomerNo, ThirdAmount, WorkDate() + 10);

        Assert.AreEqual(FirstAmount + SecondAmount + ThirdAmount, CustomerBalanceWindow.BalanceChangeBetween(CustomerNo, WorkDate() - 10, WorkDate() + 10),
            'Expected a window covering every posting date to return the sum of all the customer''s entries');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ChangeBetweenIsZeroWhenNoEntryFallsInTheWindow()
    var
        CustomerBalanceWindow: Codeunit "Customer Balance Window";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomerNo();
        PostAmountOnDate(CustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate() - 10);
        PostAmountOnDate(CustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate() - 5);

        Assert.AreEqual(0.0, CustomerBalanceWindow.BalanceChangeBetween(CustomerNo, WorkDate() + 1, WorkDate() + 10),
            'Expected 0 for a window that contains none of the customer''s entries — the customer''s balance outside the window must not leak in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ChangeBetweenNetsCreditsAgainstCharges()
    var
        CustomerBalanceWindow: Codeunit "Customer Balance Window";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
        ChargeAmount: Decimal;
        CreditAmount: Decimal;
    begin
        CustomerNo := CreateCustomerNo();
        ChargeAmount := LibraryRandom.RandDecInRange(200, 300, 2);
        CreditAmount := LibraryRandom.RandDecInRange(50, 150, 2);
        PostAmountOnDate(CustomerNo, ChargeAmount, WorkDate() - 2);
        PostAmountOnDate(CustomerNo, -CreditAmount, WorkDate() + 2);

        Assert.AreEqual(ChargeAmount - CreditAmount, CustomerBalanceWindow.BalanceChangeBetween(CustomerNo, WorkDate() - 5, WorkDate() + 5),
            'Expected the negative entry in the window to reduce the result — the answer is a signed net, not a sum of absolute amounts');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ChangeBetweenCountsOnlyTheNamedCustomer()
    var
        CustomerBalanceWindow: Codeunit "Customer Balance Window";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
        OtherCustomerNo: Code[20];
        OwnAmount: Decimal;
    begin
        CustomerNo := CreateCustomerNo();
        OtherCustomerNo := CreateCustomerNo();
        OwnAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        PostAmountOnDate(CustomerNo, OwnAmount, WorkDate());
        PostAmountOnDate(OtherCustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate());

        Assert.AreEqual(OwnAmount, CustomerBalanceWindow.BalanceChangeBetween(CustomerNo, WorkDate() - 5, WorkDate() + 5),
            'Expected only the named customer''s entry — another customer posting inside the same window must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure AsOfCountsEverythingThroughTheDateAndNothingAfter()
    var
        CustomerBalanceWindow: Codeunit "Customer Balance Window";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
        FarPastCreditAmount: Decimal;
        EarlierAmount: Decimal;
        OnTheDayAmount: Decimal;
    begin
        CustomerNo := CreateCustomerNo();
        FarPastCreditAmount := LibraryRandom.RandDecInRange(20, 80, 2);
        EarlierAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        OnTheDayAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        PostAmountOnDate(CustomerNo, -FarPastCreditAmount, WorkDate() - 400);
        PostAmountOnDate(CustomerNo, EarlierAmount, WorkDate() - 10);
        PostAmountOnDate(CustomerNo, OnTheDayAmount, WorkDate());
        PostAmountOnDate(CustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate() + 10);

        Assert.AreEqual(EarlierAmount + OnTheDayAmount - FarPastCreditAmount, CustomerBalanceWindow.BalanceAsOf(CustomerNo, WorkDate()),
            'Expected the as-of balance to include the entry posted on AsOfDate itself and everything before it — even a credit posted over a year back — but not the later entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure AsOfBeforeTheFirstEntryIsZero()
    var
        CustomerBalanceWindow: Codeunit "Customer Balance Window";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomerNo();
        PostAmountOnDate(CustomerNo, LibraryRandom.RandDecInRange(100, 200, 2), WorkDate());

        Assert.AreEqual(0.0, CustomerBalanceWindow.BalanceAsOf(CustomerNo, WorkDate() - 1),
            'Expected 0 for an as-of date one day before the customer''s first entry — later entries must not count');
    end;

    local procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        EnsureAnyPostingDateAllowed();
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure EnsureAnyPostingDateAllowed()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
    begin
        // The fixtures post up to 400 days away from the work date; a grading company
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

    local procedure PostAmountOnDate(CustomerNo: Code[20]; EntryAmount: Decimal; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, CustomerNo, EntryAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;
}
