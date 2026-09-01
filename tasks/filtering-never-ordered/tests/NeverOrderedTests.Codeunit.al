codeunit 50900 "Never Ordered Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerWithNoEntriesAtAllHasNeverOrdered()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);

        Assert.IsTrue(NeverOrderedCustomers.NeverOrderedInPeriod(Customer."No.", FromDate, ToDate),
            StrSubstNo('Expected customer %1, who has no ledger entries at all, to be reported as never ordered in the period %2..%3, got false', Customer."No.", FromDate, ToDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryInsideThePeriodMeansTheCustomerOrdered()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        FromDate: Date;
        ToDate: Date;
        EntryDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        EntryDate := FromDate + (ToDate - FromDate) div 2;
        AddLedgerEntry(Customer."No.", EntryDate);

        Assert.IsFalse(NeverOrderedCustomers.NeverOrderedInPeriod(Customer."No.", FromDate, ToDate),
            StrSubstNo('Expected customer %1 with an entry posted %2, inside the period %3..%4, to be reported as ordered, got never ordered', Customer."No.", EntryDate, FromDate, ToDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryOnTheFirstDayOfThePeriodCounts()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        AddLedgerEntry(Customer."No.", FromDate);

        Assert.IsFalse(NeverOrderedCustomers.NeverOrderedInPeriod(Customer."No.", FromDate, ToDate),
            StrSubstNo('Expected customer %1 with an entry posted exactly on FromDate (%2) to be reported as ordered — the period is inclusive at both ends, got never ordered', Customer."No.", FromDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryOnTheLastDayOfThePeriodCounts()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        AddLedgerEntry(Customer."No.", ToDate);

        Assert.IsFalse(NeverOrderedCustomers.NeverOrderedInPeriod(Customer."No.", FromDate, ToDate),
            StrSubstNo('Expected customer %1 with an entry posted exactly on ToDate (%2) to be reported as ordered — the period is inclusive at both ends, got never ordered', Customer."No.", ToDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryTheDayBeforeThePeriodDoesNotCount()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        AddLedgerEntry(Customer."No.", FromDate - 1);

        Assert.IsTrue(NeverOrderedCustomers.NeverOrderedInPeriod(Customer."No.", FromDate, ToDate),
            StrSubstNo('Expected customer %1, whose only entry was posted %2, the day before FromDate, to be reported as never ordered in the period %3..%4, got ordered', Customer."No.", FromDate - 1, FromDate, ToDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryTheDayAfterThePeriodDoesNotCount()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        AddLedgerEntry(Customer."No.", ToDate + 1);

        Assert.IsTrue(NeverOrderedCustomers.NeverOrderedInPeriod(Customer."No.", FromDate, ToDate),
            StrSubstNo('Expected customer %1, whose only entry was posted %2, the day after ToDate, to be reported as never ordered in the period %3..%4, got ordered', Customer."No.", ToDate + 1, FromDate, ToDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnotherCustomersEntryDoesNotCount()
    var
        QuietCustomer: Record Customer;
        BusyCustomer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(QuietCustomer);
        CreateCustomer(BusyCustomer);
        AddLedgerEntry(BusyCustomer."No.", FromDate + (ToDate - FromDate) div 2);

        Assert.IsTrue(NeverOrderedCustomers.NeverOrderedInPeriod(QuietCustomer."No.", FromDate, ToDate),
            StrSubstNo('Expected customer %1 to be reported as never ordered — the in-period entry belongs to customer %2, not to them', QuietCustomer."No.", BusyCustomer."No."));
        Assert.IsFalse(NeverOrderedCustomers.NeverOrderedInPeriod(BusyCustomer."No.", FromDate, ToDate),
            StrSubstNo('Expected customer %1, who owns the in-period entry, to be reported as ordered in the same period %2..%3, got never ordered', BusyCustomer."No.", FromDate, ToDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListContainsTheCustomerWithoutEntriesInThePeriod()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        NeverOrderedList: List of [Code[20]];
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);

        NeverOrderedList := NeverOrderedCustomers.GetNeverOrderedCustomers(FromDate, ToDate);

        Assert.IsTrue(NeverOrderedList.Contains(Customer."No."),
            StrSubstNo('Expected the returned list to contain customer %1, who has no ledger entries in the period, but the list left them out', Customer."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListLeavesOutTheCustomerWhoOrderedInThePeriod()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        NeverOrderedList: List of [Code[20]];
        FromDate: Date;
        ToDate: Date;
        EntryDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        EntryDate := FromDate + (ToDate - FromDate) div 2;
        AddLedgerEntry(Customer."No.", EntryDate);

        NeverOrderedList := NeverOrderedCustomers.GetNeverOrderedCustomers(FromDate, ToDate);

        Assert.IsFalse(NeverOrderedList.Contains(Customer."No."),
            StrSubstNo('Expected the returned list to leave out customer %1, who has an entry posted %2 inside the period %3..%4, but the list contains them', Customer."No.", EntryDate, FromDate, ToDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListLeavesOutTheCustomerWhoseOnlyEntryIsOnFromDate()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        NeverOrderedList: List of [Code[20]];
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        AddLedgerEntry(Customer."No.", FromDate);

        NeverOrderedList := NeverOrderedCustomers.GetNeverOrderedCustomers(FromDate, ToDate);

        Assert.IsFalse(NeverOrderedList.Contains(Customer."No."),
            StrSubstNo('Expected the returned list to leave out customer %1, whose entry falls exactly on FromDate (%2) — the period is inclusive at both ends, but the list contains them', Customer."No.", FromDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListLeavesOutTheCustomerWhoseOnlyEntryIsOnToDate()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        NeverOrderedList: List of [Code[20]];
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        AddLedgerEntry(Customer."No.", ToDate);

        NeverOrderedList := NeverOrderedCustomers.GetNeverOrderedCustomers(FromDate, ToDate);

        Assert.IsFalse(NeverOrderedList.Contains(Customer."No."),
            StrSubstNo('Expected the returned list to leave out customer %1, whose entry falls exactly on ToDate (%2) — the period is inclusive at both ends, but the list contains them', Customer."No.", ToDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListContainsTheCustomerWhoseEntriesAllFallOutsideThePeriod()
    var
        Customer: Record Customer;
        NeverOrderedCustomers: Codeunit "Never Ordered Customers";
        Assert: Codeunit Assert;
        NeverOrderedList: List of [Code[20]];
        FromDate: Date;
        ToDate: Date;
    begin
        PickPeriod(FromDate, ToDate);
        CreateCustomer(Customer);
        AddLedgerEntry(Customer."No.", FromDate - 1);
        AddLedgerEntry(Customer."No.", ToDate + 1);

        NeverOrderedList := NeverOrderedCustomers.GetNeverOrderedCustomers(FromDate, ToDate);

        Assert.IsTrue(NeverOrderedList.Contains(Customer."No."),
            StrSubstNo('Expected the returned list to contain customer %1 — they have ledger entries, but all of them fall outside the period %2..%3, so in this period they never ordered', Customer."No.", FromDate, ToDate));
    end;

    local procedure PickPeriod(var FromDate: Date; var ToDate: Date)
    var
        Any: Codeunit Any;
    begin
        FromDate := Any.DateInRange(20200101D, 1, 2000);
        ToDate := Any.DateInRange(FromDate, 5, 60);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    local procedure AddLedgerEntry(CustomerNo: Code[20]; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NextEntryNo: Integer;
    begin
        if CustLedgerEntry.FindLast() then
            NextEntryNo := CustLedgerEntry."Entry No." + 1
        else
            NextEntryNo := 1;
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := NextEntryNo;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry.Insert();
    end;
}
