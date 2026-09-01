codeunit 50900 "Customer Activity Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenEntriesIsTrueWhenAnOpenEntryExists()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer();
        MockLedgerEntry(CustomerNo, false);
        MockLedgerEntry(CustomerNo, true);
        MockLedgerEntry(CustomerNo, false);

        Assert.IsTrue(CustomerActivityCheck.HasOpenEntries(CustomerNo),
            'Expected true from HasOpenEntries: the customer has an open entry sitting between two closed ones, but the call returned false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenEntriesIsFalseWhenAllEntriesAreClosed()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer();
        MockLedgerEntry(CustomerNo, false);
        MockLedgerEntry(CustomerNo, false);
        MockLedgerEntry(CustomerNo, false);

        Assert.IsFalse(CustomerActivityCheck.HasOpenEntries(CustomerNo),
            'Expected false from HasOpenEntries: every entry of this customer is closed, and a closed entry must not count as an open one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenEntriesIsFalseForACustomerWithNoEntries()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(CustomerActivityCheck.HasOpenEntries(CreateCustomer()),
            'Expected false from HasOpenEntries for a customer with no ledger entries at all — and no error: an empty set is a normal input');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenEntriesIgnoresOtherCustomersOpenEntries()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        NeighbourNo: Code[20];
    begin
        CustomerNo := CreateCustomer();
        NeighbourNo := CreateCustomer();
        MockLedgerEntry(CustomerNo, false);
        MockLedgerEntry(NeighbourNo, true);

        Assert.IsFalse(CustomerActivityCheck.HasOpenEntries(CustomerNo),
            'Expected false from HasOpenEntries: the only open entry belongs to a neighbour customer and must not leak into this customer''s answer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsDormantIsTrueWhenTheCustomerHasNoEntries()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        NeighbourNo: Code[20];
    begin
        CustomerNo := CreateCustomer();
        NeighbourNo := CreateCustomer();
        MockLedgerEntry(NeighbourNo, true);

        Assert.IsTrue(CustomerActivityCheck.IsDormant(CustomerNo),
            'Expected true from IsDormant: this customer has no entries of their own — the neighbour customer''s entry must not count as activity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsDormantIsFalseWhenOnlyClosedEntriesExist()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer();
        MockLedgerEntry(CustomerNo, false);

        Assert.IsFalse(CustomerActivityCheck.IsDormant(CustomerNo),
            'Expected false from IsDormant: a single closed entry is history enough — dormancy asks for no entries at all, not for no open ones');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenEntryCountCountsExactlyTheOpenEntries()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        NeighbourNo: Code[20];
        OpenCount: Integer;
        ClosedCount: Integer;
        i: Integer;
    begin
        CustomerNo := CreateCustomer();
        NeighbourNo := CreateCustomer();
        OpenCount := Any.IntegerInRange(3, 9);
        ClosedCount := Any.IntegerInRange(2, 6);
        for i := 1 to OpenCount do
            MockLedgerEntry(CustomerNo, true);
        for i := 1 to ClosedCount do
            MockLedgerEntry(CustomerNo, false);
        MockLedgerEntry(NeighbourNo, true);

        Assert.AreEqual(OpenCount, CustomerActivityCheck.OpenEntryCount(CustomerNo),
            'Expected OpenEntryCount to count exactly the customer''s own open entries — closed entries and the neighbour customer''s open entry must not be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenEntryCountIsZeroWhenNothingIsOpen()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer();
        MockLedgerEntry(CustomerNo, false);
        MockLedgerEntry(CustomerNo, false);

        Assert.AreEqual(0, CustomerActivityCheck.OpenEntryCount(CustomerNo),
            'Expected 0 from OpenEntryCount when the customer''s entries are all closed — and no error either');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenEntriesStaysWithinTheBudget()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        EntryCount: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
        Answer: Boolean;
    begin
        CustomerNo := CreateCustomer();
        EntryCount := Any.IntegerInRange(180, 220);
        for i := 1 to EntryCount do
            MockLedgerEntry(CustomerNo, false);

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        CustomerActivityCheck.HasOpenEntries(CustomerNo);
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        Answer := CustomerActivityCheck.HasOpenEntries(CustomerNo);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.IsFalse(Answer,
            StrSubstNo('Expected false from HasOpenEntries before judging the budget: all %1 entries of this customer are closed', EntryCount));
        Assert.IsTrue(StatementsUsed <= MaxStatements(),
            StrSubstNo('Expected HasOpenEntries to execute at most %1 SQL statements no matter how many entries the customer has, but one call executed %2 against %3 entries', MaxStatements(), StatementsUsed, EntryCount));
        Assert.IsTrue(RowsUsed <= MaxRows(),
            StrSubstNo('Expected HasOpenEntries to read at most %1 rows, but one call read %2 — the customer holds %3 closed entries, and a yes/no answer must not drag them into AL to inspect them one by one', MaxRows(), RowsUsed, EntryCount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsDormantStaysWithinTheBudget()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        EntryCount: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
        Answer: Boolean;
    begin
        CustomerNo := CreateCustomer();
        EntryCount := Any.IntegerInRange(140, 180);
        for i := 1 to EntryCount do
            MockLedgerEntry(CustomerNo, i mod 2 = 0);

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        CustomerActivityCheck.IsDormant(CustomerNo);
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        Answer := CustomerActivityCheck.IsDormant(CustomerNo);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.IsFalse(Answer,
            StrSubstNo('Expected false from IsDormant before judging the budget: the customer holds %1 entries', EntryCount));
        Assert.IsTrue(StatementsUsed <= MaxStatements(),
            StrSubstNo('Expected IsDormant to execute at most %1 SQL statements no matter how many entries the customer has, but one call executed %2 against %3 entries', MaxStatements(), StatementsUsed, EntryCount));
        Assert.IsTrue(RowsUsed <= MaxRows(),
            StrSubstNo('Expected IsDormant to read at most %1 rows, but one call read %2 — existence is a one-row question even when the customer holds %3 entries', MaxRows(), RowsUsed, EntryCount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenEntryCountStaysWithinTheBudget()
    var
        CustomerActivityCheck: Codeunit "Customer Activity Check";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        OpenCount: Integer;
        ClosedCount: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
        Answer: Integer;
    begin
        CustomerNo := CreateCustomer();
        OpenCount := Any.IntegerInRange(120, 160);
        ClosedCount := Any.IntegerInRange(30, 50);
        for i := 1 to OpenCount do
            MockLedgerEntry(CustomerNo, true);
        for i := 1 to ClosedCount do
            MockLedgerEntry(CustomerNo, false);

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        CustomerActivityCheck.OpenEntryCount(CustomerNo);
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        Answer := CustomerActivityCheck.OpenEntryCount(CustomerNo);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(OpenCount, Answer,
            'Expected the exact open-entry count before judging the budget — cheap must not mean wrong');
        Assert.IsTrue(StatementsUsed <= MaxStatements(),
            StrSubstNo('Expected OpenEntryCount to execute at most %1 SQL statements no matter how many entries the customer has, but one call executed %2 against %3 entries', MaxStatements(), StatementsUsed, OpenCount + ClosedCount));
        Assert.IsTrue(RowsUsed <= MaxRows(),
            StrSubstNo('Expected OpenEntryCount to read at most %1 rows, but one call read %2 — the customer holds %3 entries, and counting them must happen in the database, not by fetching them into AL', MaxRows(), RowsUsed, OpenCount + ClosedCount));
    end;

    local procedure MaxStatements(): Integer
    begin
        exit(5);
    end;

    local procedure MaxRows(): Integer
    begin
        exit(10);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // A real customer from the number series, not a fixed literal: the graded
        // numbers drift from run to run in the reused company, so a submission
        // pattern-matching the published test data has nothing stable to key on.
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure MockLedgerEntry(CustomerNo: Code[20]; IsOpen: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then;
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." += 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry.Open := IsOpen;
        CustLedgerEntry.Insert();
    end;

    local procedure InvalidateDataCache()
    var
        DecoyCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // The warm-up call leaves the table's result sets in the server data cache,
        // and a cached read costs zero SQL — the graded call would measure nothing.
        // A write bumps the table's version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has locked.
        // The decoy entry belongs to a fresh customer no graded call asks about.
        LibrarySales.CreateCustomer(DecoyCustomer);
        MockLedgerEntry(DecoyCustomer."No.", false);
        SelectLatestVersion();
    end;
}
