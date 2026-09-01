codeunit 50900 "Top Customer Finder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncludesCustomerWhoseWindowSalesExceedTheThreshold()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        CustomerNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        Threshold: Decimal;
    begin
        CustomerNo := CreateCustomer();
        Amount1 := Any.DecimalInRange(100, 900, 2);
        Amount2 := Any.DecimalInRange(100, 900, 2);
        Amount3 := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(10, 3, 2101), Amount1);
        MockLedgerEntry(CustomerNo, DMY2Date(15, 6, 2101), Amount2);
        MockLedgerEntry(CustomerNo, DMY2Date(20, 9, 2101), Amount3);
        Threshold := Amount1 + Amount2 + Amount3 - Any.DecimalInRange(10, 90, 2);

        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2101), DMY2Date(31, 12, 2101), Threshold);

        Assert.IsTrue(Result.Contains(CustomerNo),
            StrSubstNo('Expected customer %1 in the list — their entries inside the window add up to more than the threshold; got: %2', CustomerNo, ListAsText(Result)));
        Assert.AreEqual(1, Result.Count(),
            StrSubstNo('Expected exactly one qualifying customer in this window, got: %1', ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExcludesCustomerWhoseWindowSalesStayBelowTheThreshold()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        CustomerNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        CustomerNo := CreateCustomer();
        Amount1 := Any.DecimalInRange(100, 900, 2);
        Amount2 := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(10, 4, 2102), Amount1);
        MockLedgerEntry(CustomerNo, DMY2Date(10, 8, 2102), Amount2);

        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2102), DMY2Date(31, 12, 2102), Amount1 + Amount2 + Any.DecimalInRange(10, 90, 2));

        Assert.AreEqual(0, Result.Count(),
            StrSubstNo('Expected an empty list — the customer''s window sales stay below the threshold; got: %1', ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExcludesCustomerNettingToExactlyTheThreshold()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        CustomerNo: Code[20];
        Threshold: Decimal;
        InvoiceAmount: Decimal;
    begin
        CustomerNo := CreateCustomer();
        Threshold := Any.DecimalInRange(200, 500, 2);
        InvoiceAmount := Threshold + Any.DecimalInRange(100, 400, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(5, 5, 2103), InvoiceAmount);
        MockLedgerEntry(CustomerNo, DMY2Date(6, 5, 2103), Threshold - InvoiceAmount);

        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2103), DMY2Date(31, 12, 2103), Threshold);

        Assert.AreEqual(0, Result.Count(),
            StrSubstNo('Expected a customer whose window entries net to exactly the threshold to stay out — the rule is strictly greater; got: %1', ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreditMemoDragsTheCustomerBackUnderTheThreshold()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        CustomerNo: Code[20];
        InvoiceAmount: Decimal;
        CreditAmount: Decimal;
        Threshold: Decimal;
    begin
        CustomerNo := CreateCustomer();
        InvoiceAmount := Any.DecimalInRange(500, 900, 2);
        CreditAmount := Any.DecimalInRange(100, 400, 2);
        // threshold sits between the netted sum and the invoice alone, so
        // skipping the credit memo wrongly promotes the customer
        Threshold := InvoiceAmount - CreditAmount + Any.DecimalInRange(10, 50, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(10, 2, 2104), InvoiceAmount);
        MockLedgerEntry(CustomerNo, DMY2Date(20, 2, 2104), -CreditAmount);

        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2104), DMY2Date(31, 12, 2104), Threshold);

        Assert.AreEqual(0, Result.Count(),
            StrSubstNo('Expected the credit memo to drag the customer back under the threshold — negative entries must reduce the sum, not be skipped; got: %1', ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesOutsideTheWindowNeverCount()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer();
        MockLedgerEntry(CustomerNo, DMY2Date(31, 5, 2105), Any.DecimalInRange(5000, 9000, 2));
        MockLedgerEntry(CustomerNo, DMY2Date(1, 7, 2105), Any.DecimalInRange(5000, 9000, 2));

        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 6, 2105), DMY2Date(30, 6, 2105), Any.DecimalInRange(50, 200, 2));

        Assert.AreEqual(0, Result.Count(),
            StrSubstNo('Expected an empty list — the customer''s postings sit one day before and one day after the window, and entries outside the window never count; got: %1', ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesOnBothBoundaryDatesCount()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        CustomerNo: Code[20];
        FromAmount: Decimal;
        ToAmount: Decimal;
        Threshold: Decimal;
    begin
        CustomerNo := CreateCustomer();
        FromAmount := Any.DecimalInRange(300, 600, 2);
        ToAmount := Any.DecimalInRange(300, 600, 2);
        // over the threshold only if the entries on BOTH boundary dates count
        Threshold := FromAmount + ToAmount - Any.DecimalInRange(10, 90, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(1, 6, 2106), FromAmount);
        MockLedgerEntry(CustomerNo, DMY2Date(30, 6, 2106), ToAmount);

        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 6, 2106), DMY2Date(30, 6, 2106), Threshold);

        Assert.IsTrue(Result.Contains(CustomerNo),
            StrSubstNo('Expected customer %1 in the list — both boundary dates are inclusive, and only the two boundary-date entries together clear the threshold; got: %2', CustomerNo, ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsACustomerNumberThatHasNoCustomerCard()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        OrphanedNo: Code[20];
        Threshold: Decimal;
    begin
        OrphanedNo := UnknownCustomerNo();
        Threshold := Any.DecimalInRange(100, 400, 2);
        MockLedgerEntry(OrphanedNo, DMY2Date(10, 7, 2107), Threshold);
        MockLedgerEntry(OrphanedNo, DMY2Date(11, 7, 2107), Any.DecimalInRange(50, 200, 2));

        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2107), DMY2Date(31, 12, 2107), Threshold);

        Assert.IsTrue(Result.Contains(OrphanedNo),
            StrSubstNo('Expected customer number %1 in the list even though no Customer card carries it — the ledger is the source of truth, and an answer built by walking the customer list cannot see a number that only lives on ledger entries; got: %2', OrphanedNo, ListAsText(Result)));
        Assert.AreEqual(1, Result.Count(),
            StrSubstNo('Expected exactly one qualifying customer number in this window, got: %1', ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListsEachQualifyingCustomerExactlyOnce()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        ExpectedOver: List of [Code[20]];
        CustomerNo: Code[20];
        Threshold: Decimal;
        CustomerCount: Integer;
        i: Integer;
    begin
        Threshold := Any.DecimalInRange(500, 900, 2);
        CustomerCount := Any.IntegerInRange(5, 9);
        for i := 1 to CustomerCount do begin
            CustomerNo := CreateCustomer();
            if i mod 2 = 1 then begin
                // two entries above the threshold together — a per-entry check
                // would either miss them or list the customer twice
                MockLedgerEntry(CustomerNo, DMY2Date(10, 4, 2108), Threshold);
                MockLedgerEntry(CustomerNo, DMY2Date(10, 8, 2108), Any.DecimalInRange(50, 200, 2));
                ExpectedOver.Add(CustomerNo);
            end else
                MockLedgerEntry(CustomerNo, DMY2Date(10, 6, 2108), Threshold - Any.DecimalInRange(50, 200, 2));
        end;

        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2108), DMY2Date(31, 12, 2108), Threshold);

        Assert.AreEqual(ExpectedOver.Count(), Result.Count(),
            StrSubstNo('Expected exactly the %1 over-threshold customers, each exactly once; got: %2', ExpectedOver.Count(), ListAsText(Result)));
        foreach CustomerNo in ExpectedOver do
            Assert.IsTrue(Result.Contains(CustomerNo),
                StrSubstNo('Expected customer %1 in the list — their window sales exceed the threshold; got: %2', CustomerNo, ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsEmptyListForAWindowWithNoPostings()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
    begin
        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2109), DMY2Date(31, 12, 2109), Any.DecimalInRange(10, 500, 2));

        Assert.AreEqual(0, Result.Count(),
            StrSubstNo('Expected an empty list for a window with no postings at all — and no error; got: %1', ListAsText(Result)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheSqlStatementBudget()
    var
        TopCustomerFinder: Codeunit "Top Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Result: List of [Code[20]];
        CustomerNo: Code[20];
        LastOverNo: Code[20];
        CustomerCount: Integer;
        ExpectedOver: Integer;
        MaxStatements: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        MaxStatements := 8;
        CustomerCount := Any.IntegerInRange(25, 35);
        for i := 1 to CustomerCount do begin
            CustomerNo := CreateCustomer();
            if i mod 2 = 1 then begin
                MockLedgerEntry(CustomerNo, DMY2Date(10, 5, 2110), 700);
                MockLedgerEntry(CustomerNo, DMY2Date(10, 9, 2110), 700);
                ExpectedOver += 1;
                LastOverNo := CustomerNo;
            end else
                MockLedgerEntry(CustomerNo, DMY2Date(10, 7, 2110), 300);
        end;

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2110), DMY2Date(31, 12, 2110), 1000);
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Result := TopCustomerFinder.CustomersOverThreshold(DMY2Date(1, 1, 2110), DMY2Date(31, 12, 2110), 1000);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        Assert.AreEqual(ExpectedOver, Result.Count(),
            StrSubstNo('Expected the cheap call to still find all %1 over-threshold customers before judging the budget; got: %2', ExpectedOver, ListAsText(Result)));
        Assert.IsTrue(Result.Contains(LastOverNo),
            StrSubstNo('Expected customer %1 (window sales 1400 against a threshold of 1000) in the list before judging the budget; got: %2', LastOverNo, ListAsText(Result)));
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the whole extract to cost at most %1 SQL statements no matter how many customers post in the window, but this call executed %2 for %3 posting customers — one conversation with the database per customer does not scale', MaxStatements, StatementsUsed, CustomerCount));
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

    local procedure MockLedgerEntry(CustomerNo: Code[20]; PostingDate: Date; SalesLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then;
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." += 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := PostingDate;
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
        // nothing and per-customer chatter would sail under the budget. A write
        // bumps each table's version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has
        // locked. The decoy entry is posted far outside every window the tests
        // use, so no graded result changes.
        LibrarySales.CreateCustomer(DecoyCustomer);
        MockLedgerEntry(DecoyCustomer."No.", DMY2Date(1, 1, 2000), 1);
        SelectLatestVersion();
    end;

    local procedure ListAsText(Result: List of [Code[20]]): Text
    var
        CustomerNo: Code[20];
        Builder: TextBuilder;
    begin
        foreach CustomerNo in Result do begin
            if Builder.Length() > 0 then
                Builder.Append(', ');
            Builder.Append(CustomerNo);
        end;
        if Builder.Length() = 0 then
            exit('(empty)');
        exit(Builder.ToText());
    end;
}
