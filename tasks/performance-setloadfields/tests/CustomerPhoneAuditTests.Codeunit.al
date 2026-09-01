codeunit 50900 "Customer Phone Audit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectoryHoldsOneExactLinePerCustomerInNoOrder()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Directory: List of [Text];
        Name1: Text[100];
        Name2: Text[100];
        Name3: Text[100];
        Phone1: Text[30];
        Phone2: Text[30];
        Phone3: Text[30];
    begin
        Name1 := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(Name1));
        Name2 := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(Name2));
        Name3 := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(Name3));
        Phone1 := CopyStr(Format(Any.IntegerInRange(100000, 999999)), 1, MaxStrLen(Phone1));
        Phone2 := CopyStr(Format(Any.IntegerInRange(100000, 999999)), 1, MaxStrLen(Phone2));
        Phone3 := CopyStr(Format(Any.IntegerInRange(100000, 999999)), 1, MaxStrLen(Phone3));
        // seeded out of order on purpose — the promised order comes from the key, not from insertion
        CreateAuditCustomer('TRYAL-D1-3', Name3, Phone3, RandomEmail());
        CreateAuditCustomer('TRYAL-D1-1', Name1, Phone1, RandomEmail());
        CreateAuditCustomer('TRYAL-D1-2', Name2, Phone2, RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-D1-*');

        Directory := CustomerPhoneAudit.BuildDirectory(Customer);

        Assert.AreEqual(3, Directory.Count(),
            'Expected exactly one directory line per customer inside the filter');
        Assert.AreEqual(StrSubstNo('%1|%2|%3', 'TRYAL-D1-1', Name1, Phone1), Directory.Get(1),
            'Expected the first line to be the lowest No., built as No.|Name|Phone No. with pipes and no extra spaces');
        Assert.AreEqual(StrSubstNo('%1|%2|%3', 'TRYAL-D1-2', Name2, Phone2), Directory.Get(2),
            'Expected the second line to follow ascending No. order, built as No.|Name|Phone No.');
        Assert.AreEqual(StrSubstNo('%1|%2|%3', 'TRYAL-D1-3', Name3, Phone3), Directory.Get(3),
            'Expected the third line to follow ascending No. order, built as No.|Name|Phone No.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectoryRespectsTheCallersFilters()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Directory: List of [Text];
        InFilterName: Text[100];
        InFilterPhone: Text[30];
    begin
        InFilterName := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(InFilterName));
        InFilterPhone := CopyStr(Format(Any.IntegerInRange(100000, 999999)), 1, MaxStrLen(InFilterPhone));
        CreateAuditCustomer('TRYAL-D2A-1', InFilterName, InFilterPhone, RandomEmail());
        CreateAuditCustomer('TRYAL-D2B-1', CopyStr(Any.AlphabeticText(20), 1, 100), '555-0000', RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-D2A-*');

        Directory := CustomerPhoneAudit.BuildDirectory(Customer);

        Assert.AreEqual(1, Directory.Count(),
            'Expected only the customer matching the caller''s filter in the directory');
        Assert.AreEqual(StrSubstNo('%1|%2|%3', 'TRYAL-D2A-1', InFilterName, InFilterPhone), Directory.Get(1),
            'Expected the directory line to belong to the customer inside the filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankPhoneNumberStillGetsItsLine()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Directory: List of [Text];
        CustomerName: Text[100];
    begin
        CustomerName := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(CustomerName));
        CreateAuditCustomer('TRYAL-D3-1', CustomerName, '', RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-D3-*');

        Directory := CustomerPhoneAudit.BuildDirectory(Customer);

        Assert.AreEqual(1, Directory.Count(),
            'Expected the customer with a blank phone number to keep their directory line');
        Assert.AreEqual(StrSubstNo('%1|%2|', 'TRYAL-D3-1', CustomerName), Directory.Get(1),
            'Expected the blank-phone line to end with the pipe: No.|Name|');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyFilterReturnsAnEmptyDirectory()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Directory: List of [Text];
    begin
        Customer.SetFilter("No.", 'TRYAL-D4-*');

        Directory := CustomerPhoneAudit.BuildDirectory(Customer);

        Assert.AreEqual(0, Directory.Count(),
            'Expected an empty directory (and no error) when no customer matches the filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectoryPassLoadsOnlyTheFieldsItReads()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        CreateAuditCustomer('TRYAL-D5-1', CopyStr(Any.AlphabeticText(20), 1, 100), '555-0101', RandomEmail());
        CreateAuditCustomer('TRYAL-D5-2', CopyStr(Any.AlphabeticText(20), 1, 100), '555-0102', RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-D5-*');

        CustomerPhoneAudit.BuildDirectory(Customer);

        Assert.IsTrue(Customer.AreFieldsLoaded(Customer.Name, Customer."Phone No."),
            'Expected Name and Phone No. to be loaded on the record instance after the pass — the directory must be built on the very record the caller handed in');
        Assert.IsFalse(Customer.AreFieldsLoaded(Customer.Address),
            'Expected Address to stay unloaded: the pass reads only No., Name and Phone No., but this record came back carrying fields it never looked at');
        Assert.IsFalse(Customer.AreFieldsLoaded(Customer."E-Mail"),
            'Expected E-Mail to stay unloaded: the pass reads only No., Name and Phone No., but this record came back carrying fields it never looked at');
        Assert.IsFalse(Customer.AreFieldsLoaded(Customer."Phone Review Needed"),
            'Expected the extension field Phone Review Needed to stay unloaded — loading it forces the companion-table join the whole exercise is about skipping');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectoryPassStaysWithinTheStatementBudget()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Directory: List of [Text];
        CustomerCount: Integer;
        MaxStatements: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        MaxStatements := 5;
        CustomerCount := Any.IntegerInRange(30, 40);
        for i := 1 to CustomerCount do
            CreateAuditCustomer(CopyStr(StrSubstNo('TRYAL-D6-%1', i), 1, 20),
                CopyStr(Any.AlphabeticText(20), 1, 100), '555-0100', RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-D6-*');

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        CustomerPhoneAudit.BuildDirectory(Customer);
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Directory := CustomerPhoneAudit.BuildDirectory(Customer);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        Assert.AreEqual(CustomerCount, Directory.Count(),
            StrSubstNo('Expected all %1 customers in the directory before judging the budget', CustomerCount));
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the directory pass to cost at most %1 SQL statements no matter how many customers match, but this call executed %2 for %3 customers — going back to the database once per customer does not scale', MaxStatements, StatementsUsed, CustomerCount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectoryPassStaysWithinTheRowBudget()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Directory: List of [Text];
        CustomerCount: Integer;
        MaxRows: Integer;
        i: Integer;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        CustomerCount := Any.IntegerInRange(30, 40);
        MaxRows := CustomerCount + 10;
        for i := 1 to CustomerCount do
            CreateAuditCustomer(CopyStr(StrSubstNo('TRYAL-D7-%1', i), 1, 20),
                CopyStr(Any.AlphabeticText(20), 1, 100), '555-0100', RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-D7-*');

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        CustomerPhoneAudit.BuildDirectory(Customer);
        InvalidateDataCache();
        RowsBefore := SessionInformation.SqlRowsRead();
        Directory := CustomerPhoneAudit.BuildDirectory(Customer);
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(CustomerCount, Directory.Count(),
            StrSubstNo('Expected all %1 customers in the directory before judging the row budget', CustomerCount));
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected the directory pass to read at most %1 rows for %2 matching customers, but this call read %3 — fetching rows a second time to pick up fields the first read skipped doubles the traffic', MaxRows, CustomerCount, RowsUsed));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactSheetPrefersThePhoneNumber()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Sheet: List of [Text];
        CustomerName: Text[100];
        Phone: Text[30];
    begin
        CustomerName := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(CustomerName));
        Phone := CopyStr(Format(Any.IntegerInRange(100000, 999999)), 1, MaxStrLen(Phone));
        CreateAuditCustomer('TRYAL-C1-1', CustomerName, Phone, RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-C1-*');

        Sheet := CustomerPhoneAudit.BuildContactSheet(Customer);

        Assert.AreEqual(1, Sheet.Count(),
            'Expected exactly one contact line for the one customer inside the filter');
        Assert.AreEqual(StrSubstNo('%1|%2|%3', 'TRYAL-C1-1', CustomerName, Phone), Sheet.Get(1),
            'Expected the line to carry the phone number when one is on file — the e-mail steps in only for a blank phone');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactSheetFallsBackToTheEmailWhenThePhoneIsBlank()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Sheet: List of [Text];
        CustomerName: Text[100];
        Email: Text[80];
    begin
        CustomerName := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(CustomerName));
        Email := RandomEmail();
        CreateAuditCustomer('TRYAL-C2-1', CustomerName, '', Email);
        Customer.SetFilter("No.", 'TRYAL-C2-*');

        Sheet := CustomerPhoneAudit.BuildContactSheet(Customer);

        Assert.AreEqual(1, Sheet.Count(),
            'Expected exactly one contact line for the one customer inside the filter');
        Assert.AreEqual(StrSubstNo('%1|%2|%3', 'TRYAL-C2-1', CustomerName, Email), Sheet.Get(1),
            'Expected the e-mail address in the third column when the phone number is blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactSheetEndsWithThePipeWhenPhoneAndEmailAreBothBlank()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Sheet: List of [Text];
        CustomerName: Text[100];
    begin
        CustomerName := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(CustomerName));
        CreateAuditCustomer('TRYAL-C3-1', CustomerName, '', '');
        Customer.SetFilter("No.", 'TRYAL-C3-*');

        Sheet := CustomerPhoneAudit.BuildContactSheet(Customer);

        Assert.AreEqual(1, Sheet.Count(),
            'Expected the customer with neither phone nor e-mail to keep their contact line');
        Assert.AreEqual(StrSubstNo('%1|%2|', 'TRYAL-C3-1', CustomerName), Sheet.Get(1),
            'Expected the line to end with the pipe when both the phone number and the e-mail are blank: No.|Name|');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactSheetFollowsAscendingNoOrderInsideTheFilter()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Sheet: List of [Text];
        Name1: Text[100];
        Name2: Text[100];
        Phone1: Text[30];
        Email2: Text[80];
    begin
        Name1 := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(Name1));
        Name2 := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(Name2));
        Phone1 := CopyStr(Format(Any.IntegerInRange(100000, 999999)), 1, MaxStrLen(Phone1));
        Email2 := RandomEmail();
        // seeded out of order on purpose, with a decoy outside the filter
        CreateAuditCustomer('TRYAL-C4-2', Name2, '', Email2);
        CreateAuditCustomer('TRYAL-C4-1', Name1, Phone1, RandomEmail());
        CreateAuditCustomer('TRYAL-C4X-1', CopyStr(Any.AlphabeticText(20), 1, 100), '', RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-C4-*');

        Sheet := CustomerPhoneAudit.BuildContactSheet(Customer);

        Assert.AreEqual(2, Sheet.Count(),
            'Expected one contact line per customer inside the filter — the customer outside the filter must stay off the sheet');
        Assert.AreEqual(StrSubstNo('%1|%2|%3', 'TRYAL-C4-1', Name1, Phone1), Sheet.Get(1),
            'Expected the first line to be the lowest No., whatever order the customers were created in');
        Assert.AreEqual(StrSubstNo('%1|%2|%3', 'TRYAL-C4-2', Name2, Email2), Sheet.Get(2),
            'Expected the second line to follow ascending No. order, with the e-mail fallback for its blank phone');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactSheetIsEmptyWhenNoCustomerMatches()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Sheet: List of [Text];
    begin
        Customer.SetFilter("No.", 'TRYAL-C5-*');

        Sheet := CustomerPhoneAudit.BuildContactSheet(Customer);

        Assert.AreEqual(0, Sheet.Count(),
            'Expected an empty contact sheet (and no error) when no customer matches the filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactSheetLeavesTheWideFieldsUnloaded()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // the blank-phone customer sorts last on purpose: a pass that re-fetches
        // fallback rows just in time hands back an instance carrying the full row
        CreateAuditCustomer('TRYAL-C6-1', CopyStr(Any.AlphabeticText(20), 1, 100), '555-0101', RandomEmail());
        CreateAuditCustomer('TRYAL-C6-2', CopyStr(Any.AlphabeticText(20), 1, 100), '', RandomEmail());
        Customer.SetFilter("No.", 'TRYAL-C6-*');

        CustomerPhoneAudit.BuildContactSheet(Customer);

        Assert.IsFalse(Customer.AreFieldsLoaded(Customer.Address),
            'Expected Address to stay unloaded: the sheet reads only No., Name, Phone No. and the e-mail fallback, but this record came back carrying fields it never looked at');
        Assert.IsFalse(Customer.AreFieldsLoaded(Customer."Phone Review Needed"),
            'Expected the extension field Phone Review Needed to stay unloaded — loading it forces the companion-table join the whole exercise is about skipping');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactSheetStaysWithinTheStatementBudget()
    var
        Customer: Record Customer;
        CustomerPhoneAudit: Codeunit "Customer Phone Audit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Sheet: List of [Text];
        CustomerCount: Integer;
        BlankCount: Integer;
        MaxStatements: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        // The JIT trap costs 3 statements on the graded BC version (initial read +
        // just-in-time re-fetch + re-read of the remainder with the wider shape),
        // not one per fallback row — the budget must sit below 3 to catch it.
        // 2 still admits an honest two-statement design (a second filtered pass).
        MaxStatements := 2;
        CustomerCount := Any.IntegerInRange(30, 40);
        for i := 1 to CustomerCount do
            if i mod 2 = 0 then
                CreateAuditCustomer(CopyStr(StrSubstNo('TRYAL-C7-%1', i), 1, 20),
                    CopyStr(Any.AlphabeticText(20), 1, 100), '', RandomEmail())
            else
                CreateAuditCustomer(CopyStr(StrSubstNo('TRYAL-C7-%1', i), 1, 20),
                    CopyStr(Any.AlphabeticText(20), 1, 100), '555-0100', RandomEmail());
        BlankCount := CustomerCount div 2;
        Customer.SetFilter("No.", 'TRYAL-C7-*');

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        CustomerPhoneAudit.BuildContactSheet(Customer);
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Sheet := CustomerPhoneAudit.BuildContactSheet(Customer);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        Assert.AreEqual(CustomerCount, Sheet.Count(),
            StrSubstNo('Expected all %1 customers on the contact sheet before judging the budget', CustomerCount));
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the contact sheet to cost at most %1 SQL statements no matter how many phones are blank, but this call executed %2 for %3 customers of which %4 needed the e-mail fallback — the output text can be right while the pass quietly goes back to the database for a field it never announced it would read', MaxStatements, StatementsUsed, CustomerCount, BlankCount));
    end;

    local procedure CreateAuditCustomer(CustomerNo: Code[20]; CustomerName: Text[100]; PhoneNo: Text[30]; Email: Text[80])
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Name := CustomerName;
        Customer."Phone No." := PhoneNo;
        Customer."E-Mail" := Email;
        // wide fields get content so an unloaded probe proves something real was skipped
        Customer.Address := 'TRYAL Wide Street 1';
        Customer.City := 'TRYAL City';
        Customer.Insert();
    end;

    local procedure RandomEmail(): Text[80]
    var
        Any: Codeunit Any;
    begin
        exit(CopyStr(StrSubstNo('%1@tryal.example', Any.AlphabeticText(12)), 1, 80));
    end;

    local procedure InvalidateDataCache()
    var
        DecoyCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // The warm-up call leaves the Customer result sets in the server data cache,
        // and a cached read costs zero SQL — the graded call would measure nothing.
        // A write bumps the table's version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has locked.
        // The decoy customer's No. comes from the number series, so no TRYAL-* filter sees it.
        LibrarySales.CreateCustomer(DecoyCustomer);
        SelectLatestVersion();
    end;

}
