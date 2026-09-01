codeunit 50900 "Salesperson Sales Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SumsEntriesAcrossAllCustomersOfOneSalesperson()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        CustomerA: Code[20];
        CustomerB: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
    begin
        CreateSalesperson('TRYAL-P1-A');
        CustomerA := CreateCustomerFor('TRYAL-P1-A');
        CustomerB := CreateCustomerFor('TRYAL-P1-A');
        Amount1 := Any.DecimalInRange(100, 900, 2);
        Amount2 := Any.DecimalInRange(100, 900, 2);
        Amount3 := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerA, Amount1, 'TRYAL-P1-A');
        MockLedgerEntry(CustomerA, Amount2, 'TRYAL-P1-A');
        MockLedgerEntry(CustomerB, Amount3, 'TRYAL-P1-A');

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P1*');

        Assert.AreEqual(Amount1 + Amount2 + Amount3, GetTotal(Totals, 'TRYAL-P1-A'),
            'Expected the salesperson''s total to add up every entry of every customer assigned to them');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsEachSalespersonsTotalSeparate()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AmountA: Decimal;
        AmountB: Decimal;
    begin
        CreateSalesperson('TRYAL-P2-A');
        CreateSalesperson('TRYAL-P2-B');
        AmountA := Any.DecimalInRange(100, 900, 2);
        AmountB := Any.DecimalInRange(1000, 2000, 2);
        MockLedgerEntry(CreateCustomerFor('TRYAL-P2-A'), AmountA, 'TRYAL-P2-A');
        MockLedgerEntry(CreateCustomerFor('TRYAL-P2-B'), AmountB, 'TRYAL-P2-B');

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P2*');

        Assert.AreEqual(AmountA, GetTotal(Totals, 'TRYAL-P2-A'),
            'Expected salesperson A''s total to contain only entries of A''s own customers');
        Assert.AreEqual(AmountB, GetTotal(Totals, 'TRYAL-P2-B'),
            'Expected salesperson B''s total to contain only entries of B''s own customers');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativePostingsReduceTheTotal()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        CustomerNo: Code[20];
        InvoiceAmount: Decimal;
        CreditAmount: Decimal;
    begin
        CreateSalesperson('TRYAL-P3-A');
        CustomerNo := CreateCustomerFor('TRYAL-P3-A');
        InvoiceAmount := Any.DecimalInRange(500, 900, 2);
        CreditAmount := Any.DecimalInRange(100, 400, 2);
        MockLedgerEntry(CustomerNo, InvoiceAmount, 'TRYAL-P3-A');
        MockLedgerEntry(CustomerNo, -CreditAmount, 'TRYAL-P3-A');

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P3*');

        Assert.AreEqual(InvoiceAmount - CreditAmount, GetTotal(Totals, 'TRYAL-P3-A'),
            'Expected the negative entry (a credit memo) to reduce the salesperson''s total, not to be skipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SalespersonWithNoEntriesAppearsWithZero()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Totals: Dictionary of [Code[20], Decimal];
    begin
        CreateSalesperson('TRYAL-P4-A');
        CreateCustomerFor('TRYAL-P4-A');

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P4*');

        Assert.IsTrue(Totals.ContainsKey('TRYAL-P4-A'),
            'Expected the salesperson to stay in the report even though their customers have no ledger entries at all');
        Assert.AreEqual(0.0, Totals.Get('TRYAL-P4-A'),
            'Expected a total of exactly 0 for a salesperson whose customers have no ledger entries');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GroupsByTheCustomerCardNotTheEntryStamp()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        CustomerOfA: Code[20];
        Amount: Decimal;
    begin
        CreateSalesperson('TRYAL-P5-A');
        CreateSalesperson('TRYAL-P5-B');
        CustomerOfA := CreateCustomerFor('TRYAL-P5-A');
        CreateCustomerFor('TRYAL-P5-B');
        Amount := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerOfA, Amount, 'TRYAL-P5-B');

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P5*');

        Assert.AreEqual(Amount, GetTotal(Totals, 'TRYAL-P5-A'),
            'Expected the amount under the salesperson from the customer card — the code stamped on the ledger entry points at somebody else and must be ignored');
        Assert.AreEqual(0.0, GetTotal(Totals, 'TRYAL-P5-B'),
            'Expected 0 for the salesperson the entry stamp points at — the stamp must not attract the amount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomersOutsideTheFilterAreNotCounted()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        InFilterAmount: Decimal;
    begin
        CreateSalesperson('TRYAL-P6A-1');
        CreateSalesperson('TRYAL-P6B-1');
        InFilterAmount := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CreateCustomerFor('TRYAL-P6A-1'), InFilterAmount, 'TRYAL-P6A-1');
        MockLedgerEntry(CreateCustomerFor('TRYAL-P6B-1'), Any.DecimalInRange(100, 900, 2), 'TRYAL-P6B-1');

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P6A*');

        Assert.AreEqual(1, Totals.Count(),
            'Expected only the salesperson matching the filter to appear in the report');
        Assert.AreEqual(InFilterAmount, GetTotal(Totals, 'TRYAL-P6A-1'),
            'Expected the total to be built only from customers inside the filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactCodeFilterReturnsJustThatSalesperson()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        Amount: Decimal;
    begin
        CreateSalesperson('TRYAL-PA-1');
        CreateSalesperson('TRYAL-PA-2');
        Amount := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CreateCustomerFor('TRYAL-PA-1'), Amount, 'TRYAL-PA-1');
        MockLedgerEntry(CreateCustomerFor('TRYAL-PA-2'), Any.DecimalInRange(100, 900, 2), 'TRYAL-PA-2');

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-PA-1');

        Assert.AreEqual(1, Totals.Count(),
            'Expected a filter holding a single exact code to return exactly that salesperson and nobody else');
        Assert.AreEqual(Amount, GetTotal(Totals, 'TRYAL-PA-1'),
            'Expected the exact-code filter to return that salesperson''s total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EverySalespersonAppearsExactlyOnce()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        SalespersonCode: Code[20];
        SalespersonCount: Integer;
        i: Integer;
    begin
        SalespersonCount := Any.IntegerInRange(5, 9);
        for i := 1 to SalespersonCount do begin
            SalespersonCode := CopyStr(StrSubstNo('TRYAL-P7-%1', i), 1, MaxStrLen(SalespersonCode));
            CreateSalesperson(SalespersonCode);
            MockLedgerEntry(CreateCustomerFor(SalespersonCode), 100, SalespersonCode);
            MockLedgerEntry(CreateCustomerFor(SalespersonCode), 100, SalespersonCode);
        end;

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P7*');

        Assert.AreEqual(SalespersonCount, Totals.Count(),
            StrSubstNo('Expected exactly one row per salesperson — %1 salespersons were seeded, each with two customers', SalespersonCount));
        for i := 1 to SalespersonCount do begin
            SalespersonCode := CopyStr(StrSubstNo('TRYAL-P7-%1', i), 1, MaxStrLen(SalespersonCode));
            Assert.IsTrue(Totals.ContainsKey(SalespersonCode),
                StrSubstNo('Expected salesperson %1 to appear in the report', SalespersonCode));
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsEmptyWhenNoCustomerMatches()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Totals: Dictionary of [Code[20], Decimal];
    begin
        CreateSalesperson('TRYAL-P8-A');

        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P8*');

        Assert.AreEqual(0, Totals.Count(),
            'Expected an empty report: no customer matches the filter, and a salesperson without customers must not appear on the strength of the master record alone');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheSqlStatementBudget()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        SalespersonCode: Code[20];
        CustomerNo: Code[20];
        SalespersonCount: Integer;
        MaxStatements: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        MaxStatements := 4;
        SalespersonCount := Any.IntegerInRange(12, 18);
        for i := 1 to SalespersonCount do begin
            SalespersonCode := CopyStr(StrSubstNo('TRYAL-P9-%1', i), 1, MaxStrLen(SalespersonCode));
            CreateSalesperson(SalespersonCode);
            MockLedgerEntry(CreateCustomerFor(SalespersonCode), Any.DecimalInRange(100, 900, 2), SalespersonCode);
            CustomerNo := CreateCustomerFor(SalespersonCode);
            // every other salesperson gets a second customer with no entries,
            // so the cheap path must still carry entry-less customers along
            if i mod 2 = 0 then
                MockLedgerEntry(CustomerNo, Any.DecimalInRange(100, 900, 2), SalespersonCode);
        end;

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P9*');
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-P9*');
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        Assert.AreEqual(SalespersonCount, Totals.Count(),
            StrSubstNo('Expected every one of the %1 salespersons in the report before judging the budget', SalespersonCount));
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the whole report to cost at most %1 SQL statements no matter how many customers match, but this call executed %2 for %3 salespersons with two customers each — one round trip per customer does not scale', MaxStatements, StatementsUsed, SalespersonCount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllZeroReportStaysWithinTheStatementBudget()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        SalespersonCode: Code[20];
        SalespersonCount: Integer;
        MaxStatements: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        MaxStatements := 4;
        SalespersonCount := Any.IntegerInRange(12, 18);
        for i := 1 to SalespersonCount do begin
            SalespersonCode := CopyStr(StrSubstNo('TRYAL-PB-%1', i), 1, MaxStrLen(SalespersonCode));
            CreateSalesperson(SalespersonCode);
            CreateCustomerFor(SalespersonCode);
            CreateCustomerFor(SalespersonCode);
        end;

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-PB*');
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-PB*');
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        Assert.AreEqual(SalespersonCount, Totals.Count(),
            StrSubstNo('Expected all %1 salespersons in the report even though none of their customers has a single entry', SalespersonCount));
        Assert.AreEqual(0.0, GetTotal(Totals, SalespersonCode),
            'Expected a total of exactly 0 when the salesperson''s customers have no entries');
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the all-zero report to cost at most %1 SQL statements, but this call executed %2 for %3 salespersons — keeping entry-less customers in the result must not cost extra round trips', MaxStatements, StatementsUsed, SalespersonCount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheRowBudgetForManyEntries()
    var
        SalespersonSalesReport: Codeunit "Salesperson Sales Report";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        SalespersonCode: Code[20];
        CustomerNo: Code[20];
        SalespersonCount: Integer;
        EntriesPerCustomer: Integer;
        MaxRows: Integer;
        i: Integer;
        j: Integer;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        MaxRows := 50;
        EntriesPerCustomer := 25;
        SalespersonCount := Any.IntegerInRange(8, 12);
        for i := 1 to SalespersonCount do begin
            SalespersonCode := CopyStr(StrSubstNo('TRYAL-PC-%1', i), 1, MaxStrLen(SalespersonCode));
            CreateSalesperson(SalespersonCode);
            CustomerNo := CreateCustomerFor(SalespersonCode);
            for j := 1 to EntriesPerCustomer do
                MockLedgerEntry(CustomerNo, 10, SalespersonCode);
        end;

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-PC*');
        InvalidateDataCache();
        RowsBefore := SessionInformation.SqlRowsRead();
        Totals := SalespersonSalesReport.TotalSalesBySalesperson('TRYAL-PC*');
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(SalespersonCount, Totals.Count(),
            StrSubstNo('Expected every one of the %1 salespersons in the report before judging the row budget', SalespersonCount));
        Assert.AreEqual(EntriesPerCustomer * 10.0, GetTotal(Totals, SalespersonCode),
            'Expected the low-row report to still carry the real sums — the entries must be added up, just not in AL');
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected the report to read at most %1 rows, but this call read %2 — the %3 customers hold %4 ledger entries between them, and dragging every entry across the wire to add it up in AL does not scale; let the database do the adding', MaxRows, RowsUsed, SalespersonCount, SalespersonCount * EntriesPerCustomer));
    end;

    local procedure CreateSalesperson(SalespersonCode: Code[20])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Init();
        SalespersonPurchaser.Code := SalespersonCode;
        SalespersonPurchaser.Name := SalespersonCode;
        SalespersonPurchaser.Insert(true);
    end;

    local procedure CreateCustomerFor(SalespersonCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure MockLedgerEntry(CustomerNo: Code[20]; SalesLCY: Decimal; StampedSalespersonCode: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then;
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." += 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Salesperson Code" := StampedSalespersonCode;
        CustLedgerEntry."Sales (LCY)" := SalesLCY;
        CustLedgerEntry.Insert();
    end;

    local procedure GetTotal(Totals: Dictionary of [Code[20], Decimal]; SalespersonCode: Code[20]): Decimal
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(Totals.ContainsKey(SalespersonCode),
            StrSubstNo('Expected salesperson %1 to appear in the report', SalespersonCode));
        exit(Totals.Get(SalespersonCode));
    end;

    local procedure InvalidateDataCache()
    var
        DecoyCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // The warm-up call leaves both tables' result sets in the server data cache,
        // and a cached read costs zero SQL — the graded call would measure nothing
        // (query objects bypass the cache, so only record-based chatter hides there).
        // A write bumps each table's version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has locked.
        // The decoy customer carries no salesperson code, so no TRYAL-* filter sees it.
        LibrarySales.CreateCustomer(DecoyCustomer);
        MockLedgerEntry(DecoyCustomer."No.", 1, '');
        SelectLatestVersion();
    end;
}
