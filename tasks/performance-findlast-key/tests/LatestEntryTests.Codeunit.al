codeunit 50900 "Latest Entry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheEntryWithTheHighestEntryNo()
    var
        LatestEntryFinder: Codeunit "Latest Entry Finder";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LatestAmount: Decimal;
        LatestEntryNo: Integer;
    begin
        MockLedgerEntry('TRYAL-D1', Any.DecimalInRange(500, 900, 2));
        MockLedgerEntry('TRYAL-D1', Any.DecimalInRange(500, 900, 2));
        // the newest entry carries the smallest amount, so "biggest amount" is not "latest"
        LatestAmount := Any.DecimalInRange(100, 400, 2);
        LatestEntryNo := MockLedgerEntry('TRYAL-D1', LatestAmount);

        Assert.IsTrue(LatestEntryFinder.FindLatest('TRYAL-D1', CustLedgerEntry),
            'Expected true: the document has three entries, so a latest one exists');
        Assert.AreEqual(LatestEntryNo, CustLedgerEntry."Entry No.",
            'Expected the entry with the highest "Entry No." — that is the newest posting, whatever its amount');
        Assert.AreEqual(LatestAmount, CustLedgerEntry."Sales (LCY)",
            'Expected the returned record to carry the latest entry''s own data');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnoresNewerEntriesOfOtherDocuments()
    var
        LatestEntryFinder: Codeunit "Latest Entry Finder";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OwnAmount: Decimal;
        OwnEntryNo: Integer;
    begin
        OwnAmount := Any.DecimalInRange(100, 900, 2);
        OwnEntryNo := MockLedgerEntry('TRYAL-D2A', OwnAmount);
        MockLedgerEntry('TRYAL-D2B', Any.DecimalInRange(100, 900, 2));

        Assert.IsTrue(LatestEntryFinder.FindLatest('TRYAL-D2A', CustLedgerEntry),
            'Expected true: the requested document has an entry of its own');
        Assert.AreEqual(OwnEntryNo, CustLedgerEntry."Entry No.",
            'Expected the requested document''s own latest entry — the newer entry posted under a different document number must not win');
        Assert.AreEqual(OwnAmount, CustLedgerEntry."Sales (LCY)",
            'Expected the amount of the requested document''s entry, not the other document''s');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheDocumentHasNoEntries()
    var
        LatestEntryFinder: Codeunit "Latest Entry Finder";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        MockLedgerEntry('TRYAL-D3-OTHER', Any.DecimalInRange(100, 900, 2));

        Assert.IsFalse(LatestEntryFinder.FindLatest('TRYAL-D3', CustLedgerEntry),
            'Expected false for a document with no entries — entries of other documents must not be mistaken for a match');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheRowBudgetForAnEntryHeavyDocument()
    var
        LatestEntryFinder: Codeunit "Latest Entry Finder";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        EntryCount: Integer;
        MaxRows: Integer;
        LatestEntryNo: Integer;
        i: Integer;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        MaxRows := 10;
        EntryCount := Any.IntegerInRange(40, 60);
        for i := 1 to EntryCount do
            LatestEntryNo := MockLedgerEntry('TRYAL-D4', 10);

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        LatestEntryFinder.FindLatest('TRYAL-D4', CustLedgerEntry);
        InvalidateDataCache();
        Clear(CustLedgerEntry);
        RowsBefore := SessionInformation.SqlRowsRead();
        Assert.IsTrue(LatestEntryFinder.FindLatest('TRYAL-D4', CustLedgerEntry),
            'Expected the latest entry to be found before judging the budget');
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(LatestEntryNo, CustLedgerEntry."Entry No.",
            'Expected the cheap call to still return the newest entry — the right answer first, then the right cost');
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected the call to read at most %1 rows, but it read %2 — the document holds %3 entries, and hauling every one across the wire just to keep the newest does not scale; the newest entry is a single row', MaxRows, RowsUsed, EntryCount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheStatementBudgetForAnEntryHeavyDocument()
    var
        LatestEntryFinder: Codeunit "Latest Entry Finder";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        EntryCount: Integer;
        MaxStatements: Integer;
        LatestEntryNo: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        MaxStatements := 3;
        EntryCount := Any.IntegerInRange(40, 60);
        for i := 1 to EntryCount do
            LatestEntryNo := MockLedgerEntry('TRYAL-D5', 10);

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        LatestEntryFinder.FindLatest('TRYAL-D5', CustLedgerEntry);
        InvalidateDataCache();
        Clear(CustLedgerEntry);
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Assert.IsTrue(LatestEntryFinder.FindLatest('TRYAL-D5', CustLedgerEntry),
            'Expected the latest entry to be found before judging the budget');
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        Assert.AreEqual(LatestEntryNo, CustLedgerEntry."Entry No.",
            'Expected the cheap call to still return the newest entry — the right answer first, then the right cost');
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the call to execute at most %1 SQL statements, but it executed %2 for a document with %3 entries — going back to the database per entry does not scale', MaxStatements, StatementsUsed, EntryCount));
    end;

    local procedure MockLedgerEntry(DocumentNo: Code[20]; SalesLCY: Decimal): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then;
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." += 1;
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry."Sales (LCY)" := SalesLCY;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure InvalidateDataCache()
    begin
        // The warm-up call leaves the table's result set in the server data cache,
        // and a cached read costs zero SQL — the graded call would measure nothing.
        // A write bumps the table's version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has locked.
        // The decoy entry sits under its own document number, so no graded lookup sees it.
        MockLedgerEntry('TRYAL-DECOY', 1);
        SelectLatestVersion();
    end;
}
