codeunit 50900 "Customer Sales Total Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SumsEveryEntryOfTheCustomer()
    var
        CustomerSalesTotal: Codeunit "Customer Sales Total";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
    begin
        CustomerNo := CreateCustomer();
        Amount1 := Any.DecimalInRange(100, 900, 2);
        Amount2 := Any.DecimalInRange(100, 900, 2);
        Amount3 := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerNo, Amount1);
        MockLedgerEntry(CustomerNo, Amount2);
        MockLedgerEntry(CustomerNo, Amount3);

        Assert.AreEqual(Amount1 + Amount2 + Amount3, CustomerSalesTotal.TotalSales(CustomerNo),
            'Expected the total to add up every ledger entry of the customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OtherCustomersEntriesDoNotLeakIn()
    var
        CustomerSalesTotal: Codeunit "Customer Sales Total";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        OtherCustomerNo: Code[20];
        Amount: Decimal;
    begin
        CustomerNo := CreateCustomer();
        OtherCustomerNo := CreateCustomer();
        Amount := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerNo, Amount);
        MockLedgerEntry(OtherCustomerNo, Any.DecimalInRange(1000, 2000, 2));

        Assert.AreEqual(Amount, CustomerSalesTotal.TotalSales(CustomerNo),
            'Expected the total to be built only from the given customer''s entries — another customer''s entry leaked in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeEntriesReduceTheTotal()
    var
        CustomerSalesTotal: Codeunit "Customer Sales Total";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        InvoiceAmount: Decimal;
        CreditAmount: Decimal;
    begin
        CustomerNo := CreateCustomer();
        InvoiceAmount := Any.DecimalInRange(500, 900, 2);
        CreditAmount := Any.DecimalInRange(100, 400, 2);
        MockLedgerEntry(CustomerNo, InvoiceAmount);
        MockLedgerEntry(CustomerNo, -CreditAmount);

        Assert.AreEqual(InvoiceAmount - CreditAmount, CustomerSalesTotal.TotalSales(CustomerNo),
            'Expected the negative entry (a credit memo) to reduce the total, not to be skipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsZeroForACustomerWithNoEntries()
    var
        CustomerSalesTotal: Codeunit "Customer Sales Total";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer();

        Assert.AreEqual(0.0, CustomerSalesTotal.TotalSales(CustomerNo),
            'Expected exactly 0 for a customer without a single ledger entry — not an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsZeroForAnUnknownCustomerNumber()
    var
        CustomerSalesTotal: Codeunit "Customer Sales Total";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(0.0, CustomerSalesTotal.TotalSales(UnknownCustomerNo()),
            'Expected exactly 0 for a number that matches no Customer record at all — the procedure must not raise an error for unknown numbers');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheRowBudget()
    var
        CustomerSalesTotal: Codeunit "Customer Sales Total";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        Total: Decimal;
        EntryCount: Integer;
        MaxRows: Integer;
        i: Integer;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        MaxRows := 10;
        EntryCount := Any.IntegerInRange(120, 180);
        CustomerNo := CreateCustomer();
        for i := 1 to EntryCount do
            MockLedgerEntry(CustomerNo, 10);

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        CustomerSalesTotal.TotalSales(CustomerNo);
        InvalidateDataCache();
        RowsBefore := SessionInformation.SqlRowsRead();
        Total := CustomerSalesTotal.TotalSales(CustomerNo);
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(EntryCount * 10.0, Total,
            StrSubstNo('Expected the cheap call to still carry the real sum of all %1 entries — the entries must be added up, just not in AL', EntryCount));
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected the call to read at most %1 rows no matter how many entries the customer has, but it read %2 for %3 entries — fetching every entry to add it up in AL does not scale; let the database do the adding', MaxRows, RowsUsed, EntryCount));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure UnknownCustomerNo(): Code[20]
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        CandidateNo: Code[20];
    begin
        repeat
            CandidateNo := CopyStr('TRYAL-' + Any.AlphanumericText(10), 1, MaxStrLen(CandidateNo));
        until not Customer.Get(CandidateNo);
        exit(CandidateNo);
    end;

    local procedure MockLedgerEntry(CustomerNo: Code[20]; SalesLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then;
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." += 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Sales (LCY)" := SalesLCY;
        CustLedgerEntry.Insert();
    end;

    local procedure InvalidateDataCache()
    var
        DecoyCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // The warm-up call leaves the read tables' result sets in the server data
        // cache, and a cached read costs zero SQL — the graded call would measure
        // nothing and the row-by-row loop would sail under the budget. A write
        // bumps each table's version and forces real reads again;
        // SelectLatestVersion alone is not enough for rows this transaction has
        // locked. The decoy entry belongs to a fresh customer, so the graded
        // customer's total is untouched.
        LibrarySales.CreateCustomer(DecoyCustomer);
        MockLedgerEntry(DecoyCustomer."No.", 1);
        SelectLatestVersion();
    end;
}
