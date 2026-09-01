codeunit 50900 "Dynamic Filter Engine Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualsOnTextFieldCountsOnlyTheExactValue()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] An Equals row on a text field counts only the record whose field is exactly the value
        CreateCustomerNamed('TRYAL-A1 Alpha Trading');
        CreateCustomerNamed('TRYAL-A1 Alpha Trading Co');
        AddFilterLine(10, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, 'TRYAL-A1 Alpha Trading');

        Assert.AreEqual(1, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected exactly one customer named TRYAL-A1 Alpha Trading — a name that merely starts the same way must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualsTakesPipeLiterally()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] A | inside the configured value matches the character, it does not become either/or
        CreateCustomerNamed('TRYAL-A2 Import|TRYAL-A2 Export');
        CreateCustomerNamed('TRYAL-A2 Import');
        CreateCustomerNamed('TRYAL-A2 Export');
        AddFilterLine(20, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, 'TRYAL-A2 Import|TRYAL-A2 Export');

        Assert.AreEqual(1, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected only the customer whose name literally contains the | character — a pipe in the configured value must not turn into an either/or filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualsTakesAsteriskLiterally()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] A * inside the configured value matches the character, it does not become a wildcard
        CreateCustomerNamed('TRYAL-A3 Star* Retail');
        CreateCustomerNamed('TRYAL-A3 Starfish Retail');
        AddFilterLine(30, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, 'TRYAL-A3 Star* Retail');

        Assert.AreEqual(1, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected only the customer whose name literally contains the * character — a star in the configured value must not act as a wildcard');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualsTakesRangeDotsLiterally()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] .. inside the configured value matches the characters, it does not become a range
        CreateCustomerNamed('TRYAL-A4 10..20 Storage');
        CreateCustomerNamed('TRYAL-A4 15 Storage');
        AddFilterLine(40, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, 'TRYAL-A4 10..20 Storage');

        Assert.AreEqual(1, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected only the customer whose name literally contains .. — two dots in the configured value must not turn into a range filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualsTakesAmpersandLiterally()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] An & inside the configured value matches the character, it does not become an AND of two criteria
        CreateCustomerNamed('TRYAL-A5 Smith & Jones Ltd');
        CreateCustomerNamed('TRYAL-A5 Smith Jones Ltd');
        AddFilterLine(50, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, 'TRYAL-A5 Smith & Jones Ltd');

        Assert.AreEqual(1, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected the customer named TRYAL-A5 Smith & Jones Ltd to be found — an & in the configured value must be matched literally, not parsed as filter syntax');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AtLeastOnDecimalKeepsTheBoundaryAndAbove()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SharedName: Text[100];
        BaseLimit: Decimal;
        AppliedFilters: Text;
    begin
        // [SCENARIO] An At Least row on a decimal field keeps the record exactly at the boundary and the one above
        SharedName := CopyStr('TRYAL-D6 ' + Any.AlphabeticText(10), 1, MaxStrLen(SharedName));
        BaseLimit := Any.DecimalInRange(100, 500, 2);
        CreateCustomerWithCreditLimit(SharedName, BaseLimit);
        CreateCustomerWithCreditLimit(SharedName, BaseLimit + 50);
        CreateCustomerWithCreditLimit(SharedName, BaseLimit + 100);
        AddFilterLine(60, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, SharedName);
        AddFilterLine(61, Database::Customer, Customer.FieldNo("Credit Limit (LCY)"), "Dynamic Filter Operator"::"At Least", Format(BaseLimit + 50));

        Assert.AreEqual(2, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected the two customers whose credit limit is at or above the configured value — At Least includes the boundary, and both configured rows must apply together');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AtMostOnDateKeepsTheBoundaryAndEarlier()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] An At Most row on a date field keeps the entries posted on or before the boundary date
        InsertItemLedgerEntry(1900070001, 'TRYAL-T7', DMY2Date(10, 3, 2026));
        InsertItemLedgerEntry(1900070002, 'TRYAL-T7', DMY2Date(15, 3, 2026));
        InsertItemLedgerEntry(1900070003, 'TRYAL-T7', DMY2Date(20, 3, 2026));
        AddFilterLine(70, Database::"Item Ledger Entry", ItemLedgerEntry.FieldNo("Entry No."), "Dynamic Filter Operator"::"At Least", Format(1900070001));
        AddFilterLine(71, Database::"Item Ledger Entry", ItemLedgerEntry.FieldNo("Posting Date"), "Dynamic Filter Operator"::"At Most", Format(DMY2Date(15, 3, 2026)));

        Assert.AreEqual(2, DynamicFilterEngine.CountWithConfiguredFilters(Database::"Item Ledger Entry", AppliedFilters),
            'Expected the two entries posted on or before the boundary date — At Most includes the boundary, and the date value must filter as a date, not as text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualsOnCodeFieldWorksOnASecondTable()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] The engine serves a structurally different table: Equals on a code field of Item Ledger Entry
        InsertItemLedgerEntry(1900080001, 'TRYAL-T8A', DMY2Date(1, 2, 2026));
        InsertItemLedgerEntry(1900080002, 'TRYAL-T8A', DMY2Date(2, 2, 2026));
        InsertItemLedgerEntry(1900080003, 'TRYAL-T8B', DMY2Date(3, 2, 2026));
        AddFilterLine(80, Database::"Item Ledger Entry", ItemLedgerEntry.FieldNo("Entry No."), "Dynamic Filter Operator"::"At Least", Format(1900080001));
        AddFilterLine(81, Database::"Item Ledger Entry", ItemLedgerEntry.FieldNo("Item No."), "Dynamic Filter Operator"::Equals, 'TRYAL-T8A');

        Assert.AreEqual(2, DynamicFilterEngine.CountWithConfiguredFilters(Database::"Item Ledger Entry", AppliedFilters),
            'Expected the two item ledger entries carrying the configured item number — the engine must work against any table, not only Customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RowsForOtherTablesAreIgnored()
    var
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] A row configured for Item Ledger Entry must not filter a Customer run
        CreateCustomerNamed('TRYAL-G1 Lone Trader');
        AddFilterLine(90, Database::"Item Ledger Entry", ItemLedgerEntry.FieldNo("Entry No."), "Dynamic Filter Operator"::Equals, Format(999999999));
        AddFilterLine(91, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, 'TRYAL-G1 Lone Trader');

        Assert.AreEqual(1, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected the row configured for Item Ledger Entry to be ignored while counting customers — only rows whose Table ID matches may apply');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyConfigurationReturnsTheUnfilteredCount()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] With no configuration rows for the table the engine counts every record
        Assert.AreEqual(Customer.Count(), DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected the unfiltered customer count when no Dynamic Filter Line row is configured for the table');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsTheAppliedFiltersText()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] AppliedFilters carries the record's own filter description naming fields and values
        CreateCustomerWithCreditLimit('TRYAL-F1 Plain Freight', 250);
        AddFilterLine(110, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, 'TRYAL-F1 Plain Freight');
        AddFilterLine(111, Database::Customer, Customer.FieldNo("Credit Limit (LCY)"), "Dynamic Filter Operator"::"At Least", Format(100));

        Assert.AreEqual(1, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected exactly the one seeded customer to satisfy both configured rows');
        Assert.IsTrue(AppliedFilters.Contains('Name'), StrSubstNo('Expected the applied-filters text to name the Name field, got: %1', AppliedFilters));
        Assert.IsTrue(AppliedFilters.Contains('TRYAL-F1 Plain Freight'), StrSubstNo('Expected the applied-filters text to carry the configured name value, got: %1', AppliedFilters));
        Assert.IsTrue(AppliedFilters.Contains('Credit Limit'), StrSubstNo('Expected the applied-filters text to name the Credit Limit (LCY) field, got: %1', AppliedFilters));
        Assert.IsTrue(AppliedFilters.Contains('100'), StrSubstNo('Expected the applied-filters text to carry the configured credit limit value, got: %1', AppliedFilters));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualsOnDecimalFieldCountsOnlyTheExactValue()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SharedName: Text[100];
        ExactLimit: Decimal;
        AppliedFilters: Text;
    begin
        // [SCENARIO] An Equals row on a decimal field counts only the record holding exactly that value
        SharedName := CopyStr('TRYAL-D9 ' + Any.AlphabeticText(10), 1, MaxStrLen(SharedName));
        ExactLimit := Any.DecimalInRange(100, 500, 2);
        CreateCustomerWithCreditLimit(SharedName, ExactLimit);
        CreateCustomerWithCreditLimit(SharedName, ExactLimit + 25);
        AddFilterLine(140, Database::Customer, Customer.FieldNo(Name), "Dynamic Filter Operator"::Equals, SharedName);
        AddFilterLine(141, Database::Customer, Customer.FieldNo("Credit Limit (LCY)"), "Dynamic Filter Operator"::Equals, Format(ExactLimit));

        Assert.AreEqual(1, DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters),
            'Expected exactly one customer at the exact credit limit — Equals on a decimal field must turn the configured text back into a decimal and match the value exactly');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownFieldNumberRaisesTheNamedError()
    var
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        RecRef: RecordRef;
        MissingFieldNo: Integer;
        AppliedFilters: Text;
    begin
        // [SCENARIO] A row pointing at a field number the table does not have raises the promised error
        MissingFieldNo := 99999;
        RecRef.Open(Database::Customer);
        while RecRef.FieldExist(MissingFieldNo) do
            MissingFieldNo += 1;
        RecRef.Close();
        AddFilterLine(120, Database::Customer, MissingFieldNo, "Dynamic Filter Operator"::Equals, 'anything');

        asserterror DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters);

        Assert.ExpectedError(StrSubstNo('Field %1 does not exist in table Customer.', MissingFieldNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WrongTypedValueRaisesTheNamedError()
    var
        Customer: Record Customer;
        DynamicFilterEngine: Codeunit "Dynamic Filter Engine";
        Assert: Codeunit Assert;
        AppliedFilters: Text;
    begin
        // [SCENARIO] A value that cannot become the decimal the field holds raises the promised error
        AddFilterLine(130, Database::Customer, Customer.FieldNo("Credit Limit (LCY)"), "Dynamic Filter Operator"::"At Least", 'lots');

        asserterror DynamicFilterEngine.CountWithConfiguredFilters(Database::Customer, AppliedFilters);

        Assert.ExpectedError('Value ''lots'' is not valid for field Credit Limit (LCY).');
    end;

    local procedure AddFilterLine(EntryNo: Integer; TableId: Integer; FieldNumber: Integer; FilterOperator: Enum "Dynamic Filter Operator"; ValueText: Text)
    var
        DynamicFilterLine: Record "Dynamic Filter Line";
    begin
        DynamicFilterLine.Init();
        DynamicFilterLine."Entry No." := EntryNo;
        DynamicFilterLine."Table ID" := TableId;
        DynamicFilterLine."Field No." := FieldNumber;
        DynamicFilterLine.Operator := FilterOperator;
        DynamicFilterLine."Filter Value" := CopyStr(ValueText, 1, MaxStrLen(DynamicFilterLine."Filter Value"));
        DynamicFilterLine.Insert();
    end;

    local procedure CreateCustomerNamed(NewName: Text[100])
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, NewName);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithCreditLimit(NewName: Text[100]; CreditLimit: Decimal)
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, NewName);
        Customer.Validate("Credit Limit (LCY)", CreditLimit);
        Customer.Modify(true);
    end;

    local procedure InsertItemLedgerEntry(EntryNo: Integer; ItemNo: Code[20]; PostingDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := EntryNo;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry.Insert();
    end;
}
