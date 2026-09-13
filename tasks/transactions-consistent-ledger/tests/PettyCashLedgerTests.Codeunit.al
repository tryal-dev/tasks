codeunit 50900 "Petty Cash Ledger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure TransferWritesACreditLegAndADebitLeg()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FromAccount: Code[20];
        ToAccount: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] A transfer produces exactly two legs: -Amount on the source account, +Amount on the target account
        FromAccount := CopyStr('FROM-' + UpperCase(Any.AlphabeticText(6)), 1, 20);
        ToAccount := CopyStr('TO-' + UpperCase(Any.AlphabeticText(6)), 1, 20);
        Amount := Any.DecimalInRange(1, 900, 2);

        PettyCashLedger.PostTransfer('TRYAL-T01', FromAccount, ToAccount, Amount);

        Assert.AreEqual(2, EntryCount('TRYAL-T01'),
            'Expected a transfer to write exactly two petty cash entries under its document no.');
        Assert.AreEqual(-Amount, LegAmount('TRYAL-T01', FromAccount),
            'Expected the source account to carry the transfer amount as a negative leg');
        Assert.AreEqual(Amount, LegAmount('TRYAL-T01', ToAccount),
            'Expected the target account to carry the transfer amount as a positive leg');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BalancedTransferIsAcceptedWhenTheTransactionCommits()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] The two legs of a transfer balance, so the transaction commits and both legs persist
        PettyCashLedger.PostTransfer('TRYAL-T02', 'CASH', 'OFFICE', Any.DecimalInRange(1, 900, 2));

        Commit();

        Assert.AreEqual(2, EntryCount('TRYAL-T02'),
            'Expected both legs of a balanced transfer to survive the commit');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PostingASingleLegDoesNotFailByItself()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] One leg on its own is written without any error — the imbalance is not judged at posting time
        Amount := Any.DecimalInRange(1, 900, 2);

        PettyCashLedger.PostEntry('TRYAL-T03', 'CASH', Amount);

        Assert.AreEqual(Amount, LegAmount('TRYAL-T03', 'CASH'),
            'Expected the single leg to be written and readable inside the transaction that posted it');
        // Balancing the ledger keeps the runner's own end-of-test commit from being refused.
        PettyCashLedger.PostEntry('TRYAL-T03', 'OFFICE', -Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AnUnbalancedTransactionIsRefusedAtCommit()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A transaction holding a single leg is refused when it tries to commit, and the leg does not survive
        // [GIVEN] one leg, posted without error and visible to the transaction
        PettyCashLedger.PostEntry('TRYAL-T04', 'CASH', Any.DecimalInRange(1, 900, 2));
        Assert.AreEqual(1, EntryCount('TRYAL-T04'),
            'Expected the single leg to be written before the transaction tries to commit — the refusal belongs to the commit, not to the posting call');

        // [WHEN] the transaction tries to commit
        asserterror Commit();

        // [THEN] the commit is refused because the ledger does not balance, and nothing of the transaction is left
        AssertCommitWasRefusedAsInconsistent();
        Assert.AreEqual(0, EntryCount('TRYAL-T04'),
            'Expected no entry of the refused transaction to survive — a refused commit rolls back every leg posted in it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure TwoSingleLegsThatBalanceAreAcceptedAtCommit()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] Two separately posted legs that sum to zero commit together
        Amount := Any.DecimalInRange(1, 900, 2);
        PettyCashLedger.PostEntry('TRYAL-T05', 'CASH', -Amount);
        PettyCashLedger.PostEntry('TRYAL-T05', 'TRAVEL', Amount);

        Commit();

        Assert.AreEqual(2, EntryCount('TRYAL-T05'),
            'Expected two single legs that balance each other to be accepted at commit and to persist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AnUnbalancedLegIsNotRescuedByABalancedTransfer()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A lone leg followed by a balanced transfer still leaves the transaction unbalanced; the refusal takes the transfer with it
        PettyCashLedger.PostEntry('TRYAL-T07A', 'TRAVEL', Any.DecimalInRange(1, 900, 2));
        PettyCashLedger.PostTransfer('TRYAL-T07B', 'CASH', 'OFFICE', Any.DecimalInRange(1, 900, 2));

        asserterror Commit();

        AssertCommitWasRefusedAsInconsistent();
        Assert.AreEqual(0, EntryCount('TRYAL-T07A'),
            'Expected the lone leg to be rolled back by the refused commit');
        Assert.AreEqual(0, EntryCount('TRYAL-T07B'),
            'Expected the balanced transfer to be rolled back together with the lone leg — a refused commit takes the whole transaction with it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ABalancedTransferPostedBeforeALoneLegIsRolledBackWithIt()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A balanced transfer followed by a lone leg is refused as a whole — the ledger must not have committed the transfer on its own while it balanced
        PettyCashLedger.PostTransfer('TRYAL-T13A', 'CASH', 'OFFICE', Any.DecimalInRange(1, 900, 2));
        PettyCashLedger.PostEntry('TRYAL-T13B', 'TRAVEL', Any.DecimalInRange(1, 900, 2));

        asserterror Commit();

        AssertCommitWasRefusedAsInconsistent();
        Assert.AreEqual(0, EntryCount('TRYAL-T13A'),
            'Expected the balanced transfer posted before the lone leg to be rolled back with it — the ledger must never commit on its own, even at a moment it balances');
        Assert.AreEqual(0, EntryCount('TRYAL-T13B'),
            'Expected the lone leg to be rolled back by the refused commit');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LegsUnderDifferentDocumentsBalanceTheTransaction()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] What must sum to zero is the transaction, not the document: two legs under different document nos. commit
        Amount := Any.DecimalInRange(1, 900, 2);
        PettyCashLedger.PostEntry('TRYAL-T08A', 'CASH', -Amount);
        PettyCashLedger.PostEntry('TRYAL-T08B', 'OFFICE', Amount);

        Commit();

        Assert.AreEqual(1, EntryCount('TRYAL-T08A'),
            'Expected the first leg to persist — legs under different document nos. balance the transaction together');
        Assert.AreEqual(1, EntryCount('TRYAL-T08B'),
            'Expected the second leg to persist — legs under different document nos. balance the transaction together');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ZeroAmountLegIsRejectedImmediately()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
    begin
        // [SCENARIO] A zero leg is nonsense on its own and fails at posting time, not at commit
        asserterror PettyCashLedger.PostEntry('TRYAL-T09', 'CASH', 0);

        AssertErrorContains('must not be zero');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ZeroTransferIsRejectedImmediately()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
    begin
        // [SCENARIO] A transfer of zero fails at posting time with the must-be-positive error
        asserterror PettyCashLedger.PostTransfer('TRYAL-T10', 'CASH', 'OFFICE', 0);

        AssertErrorContains('must be positive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure NegativeTransferIsRejectedImmediately()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Any: Codeunit Any;
    begin
        // [SCENARIO] A negative transfer fails at posting time with the must-be-positive error
        asserterror PettyCashLedger.PostTransfer('TRYAL-T11', 'CASH', 'OFFICE', -Any.DecimalInRange(1, 900, 2));

        AssertErrorContains('must be positive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LedgerIsUsableAgainAfterARefusedCommit()
    var
        PettyCashLedger: Codeunit "Petty Cash Ledger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] After a refused commit the next transaction starts from a balanced ledger and a transfer commits normally
        // [GIVEN] a transaction that was refused for holding a single leg
        PettyCashLedger.PostEntry('TRYAL-T12A', 'CASH', Any.DecimalInRange(1, 900, 2));
        asserterror Commit();
        AssertCommitWasRefusedAsInconsistent();

        // [WHEN] a balanced transfer is posted and committed in the next transaction
        PettyCashLedger.PostTransfer('TRYAL-T12B', 'CASH', 'OFFICE', Any.DecimalInRange(1, 900, 2));
        Commit();

        // [THEN] the transfer is in, the refused leg is not
        Assert.AreEqual(2, EntryCount('TRYAL-T12B'),
            'Expected a balanced transfer to commit in the transaction after a refused one — the running balance must come from the ledger table, not from state your codeunit remembers across transactions');
        Assert.AreEqual(0, EntryCount('TRYAL-T12A'),
            'Expected the leg of the refused transaction to stay gone after a later transaction committed');
    end;

    local procedure EntryCount(DocumentNo: Code[20]): Integer
    var
        PettyCashEntry: Record "Petty Cash Entry";
    begin
        PettyCashEntry.SetRange("Document No.", DocumentNo);
        exit(PettyCashEntry.Count());
    end;

    local procedure LegAmount(DocumentNo: Code[20]; AccountNo: Code[20]): Decimal
    var
        PettyCashEntry: Record "Petty Cash Entry";
        Assert: Codeunit Assert;
    begin
        PettyCashEntry.SetRange("Document No.", DocumentNo);
        PettyCashEntry.SetRange("Account No.", AccountNo);
        Assert.AreEqual(1, PettyCashEntry.Count(),
            StrSubstNo('Expected exactly one leg on account %1 under document %2', AccountNo, DocumentNo));
        PettyCashEntry.FindFirst();
        exit(PettyCashEntry.Amount);
    end;

    local procedure AssertCommitWasRefusedAsInconsistent()
    var
        Assert: Codeunit Assert;
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains('consisten'),
            StrSubstNo('Expected the commit to be refused because the ledger does not balance, but the error was: %1', ActualError));
    end;

    local procedure AssertErrorContains(Fragment: Text)
    var
        Assert: Codeunit Assert;
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains(LowerCase(Fragment)),
            StrSubstNo('Expected the ledger error to contain "%1", got: %2', Fragment, ActualError));
    end;
}
