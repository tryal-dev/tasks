codeunit 50900 "Wallet Statement Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecordTransactionPersistsAllFields()
    var
        WalletTransaction: Record "Wallet Transaction";
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
        EntryNo: Integer;
    begin
        // [SCENARIO] A recorded transaction lands in the "Wallet Transaction" table under the returned entry number
        EntryNo := StatementBuilder.RecordTransaction('STMT-T1', DMY2Date(5, 3, 2026), 250.75, 'Opening deposit');

        Assert.IsTrue(WalletTransaction.Get(EntryNo), StrSubstNo('Expected RecordTransaction to insert a "Wallet Transaction" whose "Entry No." is the returned value, but no row exists for the returned %1', EntryNo));
        Assert.AreEqual('STMT-T1', WalletTransaction."Account No.", 'Expected the recorded transaction to store the account number it was called with');
        Assert.AreEqual(DMY2Date(5, 3, 2026), WalletTransaction."Posting Date", 'Expected the recorded transaction to store the posting date it was called with');
        Assert.AreEqual(250.75, WalletTransaction.Amount, 'Expected the recorded transaction to store the amount it was called with');
        Assert.AreEqual('Opening deposit', WalletTransaction.Description, 'Expected the recorded transaction to store the description it was called with');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryNumbersFormOneSequenceAcrossAccounts()
    var
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
        FirstEntryNo: Integer;
        SecondEntryNo: Integer;
        ThirdEntryNo: Integer;
    begin
        // [SCENARIO] Entry numbers are one ledger-wide sequence starting at 1, regardless of account
        FirstEntryNo := StatementBuilder.RecordTransaction('STMT-T2A', DMY2Date(1, 2, 2026), 10.00, 'First');
        SecondEntryNo := StatementBuilder.RecordTransaction('STMT-T2B', DMY2Date(2, 2, 2026), 20.00, 'Second');
        ThirdEntryNo := StatementBuilder.RecordTransaction('STMT-T2A', DMY2Date(3, 2, 2026), 30.00, 'Third');

        Assert.AreEqual(1, FirstEntryNo, 'Expected the first transaction recorded into an empty table to get entry number 1');
        Assert.AreEqual(2, SecondEntryNo, 'Expected the second recorded transaction to get entry number 2 — the sequence is shared across accounts, not per account');
        Assert.AreEqual(3, ThirdEntryNo, 'Expected the third recorded transaction to get entry number 3 — the sequence is shared across accounts, not per account');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextEntryNumberFollowsTheHighestExistingEntry()
    var
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
        EntryNo: Integer;
    begin
        // [SCENARIO] The assigned entry number is one above the highest existing one, not derived from the row count
        SeedTransaction(40, 'STMT-T3', DMY2Date(1, 1, 2026), 5.00, 'Imported entry');

        EntryNo := StatementBuilder.RecordTransaction('STMT-T3', DMY2Date(2, 1, 2026), 10.00, 'New entry');

        Assert.AreEqual(41, EntryNo, 'Expected the next entry number to be one greater than the highest existing "Entry No." (40), not counted from the number of rows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatementListsNewestFirst()
    var
        WalletStatementLine: Record "Wallet Statement Line" temporary;
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Statement lines come out ordered by posting date, newest at line 1
        SeedTransaction(1, 'STMT-T4', DMY2Date(15, 1, 2026), 50.00, 'Middle');
        SeedTransaction(2, 'STMT-T4', DMY2Date(28, 1, 2026), 20.00, 'Newest');
        SeedTransaction(3, 'STMT-T4', DMY2Date(3, 1, 2026), 80.00, 'Oldest');

        StatementBuilder.BuildStatement('STMT-T4', WalletStatementLine);

        WalletStatementLine.Reset();
        Assert.AreEqual(3, WalletStatementLine.Count(), 'Expected exactly one statement line per transaction on the account');
        Assert.IsTrue(WalletStatementLine.Get(1), 'Expected the statement to have a line with "Line No." 1 at the top');
        Assert.AreEqual('Newest', WalletStatementLine.Description, 'Expected line 1 to be the transaction with the latest posting date (28-01-2026)');
        Assert.AreEqual(2, WalletStatementLine."Entry No.", 'Expected line 1 to carry the entry number of the newest transaction');
        Assert.IsTrue(WalletStatementLine.Get(2), 'Expected the statement to have a line with "Line No." 2');
        Assert.AreEqual('Middle', WalletStatementLine.Description, 'Expected line 2 to be the transaction with the middle posting date (15-01-2026)');
        Assert.IsTrue(WalletStatementLine.Get(3), 'Expected the statement to have a line with "Line No." 3 at the bottom');
        Assert.AreEqual('Oldest', WalletStatementLine.Description, 'Expected the bottom line to be the transaction with the earliest posting date (03-01-2026)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunningBalanceAccumulatesFromOldestToNewest()
    var
        WalletStatementLine: Record "Wallet Statement Line" temporary;
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Each line shows the wallet balance right after its transaction; charges subtract
        SeedTransaction(1, 'STMT-T5', DMY2Date(5, 1, 2026), 100.00, 'Deposit');
        SeedTransaction(2, 'STMT-T5', DMY2Date(12, 1, 2026), -30.50, 'Charge');
        SeedTransaction(3, 'STMT-T5', DMY2Date(20, 1, 2026), 20.25, 'Top-up');

        StatementBuilder.BuildStatement('STMT-T5', WalletStatementLine);

        Assert.IsTrue(WalletStatementLine.Get(3), 'Expected the statement to have a line with "Line No." 3 at the bottom');
        Assert.AreEqual(100.00, WalletStatementLine."Running Balance", 'Expected the bottom (oldest) line to show a running balance equal to its own amount — nothing older exists');
        Assert.IsTrue(WalletStatementLine.Get(2), 'Expected the statement to have a line with "Line No." 2');
        Assert.AreEqual(69.50, WalletStatementLine."Running Balance", 'Expected line 2 to show 100.00 - 30.50 = 69.50 — the balance right after the charge');
        Assert.IsTrue(WalletStatementLine.Get(1), 'Expected the statement to have a line with "Line No." 1 at the top');
        Assert.AreEqual(89.75, WalletStatementLine."Running Balance", 'Expected the top (newest) line to show the wallet''s balance after all transactions');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SameDayTransactionsBreakTheTieByEntryNo()
    var
        WalletStatementLine: Record "Wallet Statement Line" temporary;
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Two transactions on the same date: the higher entry number is newer and sits above
        SeedTransaction(7, 'STMT-T6', DMY2Date(10, 2, 2026), 10.00, 'Morning');
        SeedTransaction(8, 'STMT-T6', DMY2Date(10, 2, 2026), 5.00, 'Afternoon');

        StatementBuilder.BuildStatement('STMT-T6', WalletStatementLine);

        Assert.IsTrue(WalletStatementLine.Get(1), 'Expected the statement to have a line with "Line No." 1 at the top');
        Assert.AreEqual(8, WalletStatementLine."Entry No.", 'Expected the same-day tie to be broken by "Entry No.": the higher entry number is the newer transaction and belongs on top');
        Assert.AreEqual(15.00, WalletStatementLine."Running Balance", 'Expected the top line''s running balance to include both same-day transactions');
        Assert.IsTrue(WalletStatementLine.Get(2), 'Expected the statement to have a line with "Line No." 2');
        Assert.AreEqual(7, WalletStatementLine."Entry No.", 'Expected the lower entry number of the same day below its sibling');
        Assert.AreEqual(10.00, WalletStatementLine."Running Balance", 'Expected the older same-day line to show only its own amount — the newer sibling must not be counted yet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatementContainsOnlyTheRequestedAccount()
    var
        WalletStatementLine: Record "Wallet Statement Line" temporary;
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Another account's interleaved transactions neither appear nor leak into the balances
        SeedTransaction(1, 'STMT-T7A', DMY2Date(2, 1, 2026), 100.00, 'A first');
        SeedTransaction(2, 'STMT-T7B', DMY2Date(3, 1, 2026), 999.00, 'B noise');
        SeedTransaction(3, 'STMT-T7A', DMY2Date(9, 1, 2026), 40.00, 'A second');
        SeedTransaction(4, 'STMT-T7B', DMY2Date(10, 1, 2026), 999.00, 'B noise');

        StatementBuilder.BuildStatement('STMT-T7A', WalletStatementLine);

        VerifyStatement('STMT-T7A', WalletStatementLine);
        Assert.AreEqual(2, WalletStatementLine.Count(), 'Expected only the requested account''s transactions on the statement');
        Assert.IsTrue(WalletStatementLine.Get(1), 'Expected the statement to have a line with "Line No." 1 at the top');
        Assert.AreEqual(140.00, WalletStatementLine."Running Balance", 'Expected the running balance to sum only the requested account''s amounts — the other account''s 999.00 rows must not leak in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RebuildEmptiesTheBufferFirst()
    var
        WalletStatementLine: Record "Wallet Statement Line" temporary;
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Reusing one buffer for a second account starts from a clean slate
        SeedTransaction(1, 'STMT-T8A', DMY2Date(4, 1, 2026), 10.00, 'A one');
        SeedTransaction(2, 'STMT-T8A', DMY2Date(6, 1, 2026), 20.00, 'A two');
        SeedTransaction(3, 'STMT-T8B', DMY2Date(8, 1, 2026), 5.00, 'B only');
        StatementBuilder.BuildStatement('STMT-T8A', WalletStatementLine);

        StatementBuilder.BuildStatement('STMT-T8B', WalletStatementLine);

        WalletStatementLine.Reset();
        Assert.AreEqual(1, WalletStatementLine.Count(), 'Expected BuildStatement to empty the buffer before filling it — lines from the previous statement must not survive a rebuild');
        Assert.IsTrue(WalletStatementLine.Get(1), 'Expected the rebuilt statement to have a line with "Line No." 1');
        Assert.AreEqual(3, WalletStatementLine."Entry No.", 'Expected the rebuilt statement to hold the second account''s transaction, not leftovers of the first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AccountWithNoTransactionsYieldsEmptyStatement()
    var
        WalletStatementLine: Record "Wallet Statement Line" temporary;
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] An account that never transacted gets an empty statement, even though other accounts have entries
        SeedTransaction(1, 'STMT-T9OTHER', DMY2Date(5, 1, 2026), 50.00, 'Noise');

        StatementBuilder.BuildStatement('STMT-T9', WalletStatementLine);

        WalletStatementLine.Reset();
        Assert.AreEqual(0, WalletStatementLine.Count(), 'Expected an account with no transactions to produce an empty statement — other accounts'' entries must not appear');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedLedgerKeepsEveryGuarantee()
    var
        WalletStatementLine: Record "Wallet Statement Line" temporary;
        StatementBuilder: Codeunit "Wallet Statement Builder";
        Any: Codeunit Any;
        i: Integer;
    begin
        // [SCENARIO] A generated ledger of deposits and charges keeps order, numbering, filtering and balances intact
        for i := 1 to 8 do
            SeedTransaction(i, 'STMT-T10', Any.DateInRange(DMY2Date(1, 1, 2026), 1, 40), (Any.IntegerInRange(1, 100000) - 50000) / 100, StrSubstNo('Random %1', i));
        SeedTransaction(9, 'STMT-T10X', DMY2Date(15, 1, 2026), 77.77, 'Decoy');
        SeedTransaction(10, 'STMT-T10X', DMY2Date(25, 1, 2026), -13.13, 'Decoy');

        StatementBuilder.BuildStatement('STMT-T10', WalletStatementLine);

        VerifyStatement('STMT-T10', WalletStatementLine);
    end;

    local procedure SeedTransaction(EntryNo: Integer; AccountNo: Code[20]; PostingDate: Date; Amount: Decimal; Description: Text[100])
    var
        WalletTransaction: Record "Wallet Transaction";
    begin
        WalletTransaction."Entry No." := EntryNo;
        WalletTransaction."Account No." := AccountNo;
        WalletTransaction."Posting Date" := PostingDate;
        WalletTransaction.Amount := Amount;
        WalletTransaction.Description := Description;
        WalletTransaction.Insert();
    end;

    local procedure VerifyStatement(AccountNo: Code[20]; var WalletStatementLine: Record "Wallet Statement Line" temporary)
    var
        WalletTransaction: Record "Wallet Transaction";
        Assert: Codeunit Assert;
        ExpectedTotal: Decimal;
        PrevBalance: Decimal;
        PrevAmount: Decimal;
        PrevDate: Date;
        PrevEntryNo: Integer;
        LineIndex: Integer;
    begin
        WalletStatementLine.Reset();
        WalletTransaction.SetRange("Account No.", AccountNo);
        if WalletTransaction.FindSet() then
            repeat
                ExpectedTotal += WalletTransaction.Amount;
            until WalletTransaction.Next() = 0;
        Assert.AreEqual(WalletTransaction.Count(), WalletStatementLine.Count(), 'Expected exactly one statement line per transaction on the requested account');

        if WalletStatementLine.FindSet() then
            repeat
                LineIndex += 1;
                Assert.AreEqual(LineIndex, WalletStatementLine."Line No.", 'Expected statement line numbers to run 1, 2, 3, ... from the newest line down, without gaps');
                Assert.IsTrue(WalletTransaction.Get(WalletStatementLine."Entry No."), StrSubstNo('Expected line %1 to reference an existing transaction, got entry no. %2', LineIndex, WalletStatementLine."Entry No."));
                Assert.AreEqual(AccountNo, WalletTransaction."Account No.", StrSubstNo('Expected line %1 (entry no. %2) to belong to the requested account', LineIndex, WalletStatementLine."Entry No."));
                Assert.AreEqual(WalletTransaction."Posting Date", WalletStatementLine."Posting Date", StrSubstNo('Expected line %1 to copy the posting date of entry no. %2', LineIndex, WalletStatementLine."Entry No."));
                Assert.AreEqual(WalletTransaction.Amount, WalletStatementLine.Amount, StrSubstNo('Expected line %1 to copy the amount of entry no. %2', LineIndex, WalletStatementLine."Entry No."));
                Assert.AreEqual(WalletTransaction.Description, WalletStatementLine.Description, StrSubstNo('Expected line %1 to copy the description of entry no. %2', LineIndex, WalletStatementLine."Entry No."));
                if LineIndex = 1 then
                    Assert.AreEqual(ExpectedTotal, WalletStatementLine."Running Balance", 'Expected the top line''s running balance to equal the account''s total balance over all its transactions')
                else begin
                    Assert.IsTrue(
                        (WalletStatementLine."Posting Date" < PrevDate) or
                        ((WalletStatementLine."Posting Date" = PrevDate) and (WalletStatementLine."Entry No." < PrevEntryNo)),
                        StrSubstNo('Expected newest-first order: line %1 (posting date %2, entry no. %3) must be older than the line above it (posting date %4, entry no. %5)', LineIndex, WalletStatementLine."Posting Date", WalletStatementLine."Entry No.", PrevDate, PrevEntryNo));
                    Assert.AreEqual(PrevBalance - PrevAmount, WalletStatementLine."Running Balance", StrSubstNo('Expected the running balance on line %1 to be the line above''s balance minus the line above''s amount', LineIndex));
                end;
                PrevBalance := WalletStatementLine."Running Balance";
                PrevAmount := WalletStatementLine.Amount;
                PrevDate := WalletStatementLine."Posting Date";
                PrevEntryNo := WalletStatementLine."Entry No.";
            until WalletStatementLine.Next() = 0;
        if LineIndex > 0 then
            Assert.AreEqual(PrevAmount, PrevBalance, 'Expected the bottom (oldest) line''s running balance to equal its own amount — nothing older exists to accumulate');
    end;
}
