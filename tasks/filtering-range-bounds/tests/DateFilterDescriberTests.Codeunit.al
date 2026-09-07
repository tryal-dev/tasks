codeunit 50900 "Date Filter Describer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoFilterIsReportedAsAllDates()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A record with no filter on Posting Date is described as covering all dates
        Assert.AreEqual('all dates', DateFilterDescriber.DescribeDateFilter(CustLedgerEntry),
            'Expected a record with no filter on "Posting Date" to be described as all dates');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FiltersOnOtherFieldsStillMeanAllDates()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Filters on fields other than Posting Date do not count as a date filter
        CustLedgerEntry.SetRange("Customer No.", 'TRYAL-RB2');
        CustLedgerEntry.SetRange(Open, true);

        Assert.AreEqual('all dates', DateFilterDescriber.DescribeDateFilter(CustLedgerEntry),
            'Expected all dates when only "Customer No." and Open are filtered — a filter on another field says nothing about "Posting Date"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleDateIsReportedAsOn()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
    begin
        // [SCENARIO] A SetRange on one date is described as "on yyyy-mm-dd"
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 3000);
        CustLedgerEntry.SetRange("Posting Date", TheDate);

        Assert.AreEqual('on ' + Format(TheDate, 0, 9), DateFilterDescriber.DescribeDateFilter(CustLedgerEntry),
            'Expected a filter on a single date to be described as on yyyy-mm-dd');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClosedRangeIsReportedAsFromTo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FromDate: Date;
        ToDate: Date;
    begin
        // [SCENARIO] A SetRange between two dates is described as "from yyyy-mm-dd to yyyy-mm-dd"
        FromDate := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 2000);
        ToDate := FromDate + Any.IntegerInRange(1, 400);
        CustLedgerEntry.SetRange("Posting Date", FromDate, ToDate);

        Assert.AreEqual(StrSubstNo('from %1 to %2', Format(FromDate, 0, 9), Format(ToDate, 0, 9)),
            DateFilterDescriber.DescribeDateFilter(CustLedgerEntry),
            'Expected a two-date range to be described as from yyyy-mm-dd to yyyy-mm-dd');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RangeWithEqualBoundsIsReportedAsOn()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
    begin
        // [SCENARIO] A range written as date..date with both bounds the same day covers a single day
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 3000);
        CustLedgerEntry.SetFilter("Posting Date", '%1..%2', TheDate, TheDate);

        Assert.AreEqual('on ' + Format(TheDate, 0, 9), DateFilterDescriber.DescribeDateFilter(CustLedgerEntry),
            StrSubstNo('Expected the range "%1", whose two bounds are the same day, to be described as on yyyy-mm-dd rather than from ... to',
                CustLedgerEntry.GetFilter("Posting Date")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EitherOrListIsReportedVerbatim()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstDate: Date;
        SecondDate: Date;
        FilterText: Text;
    begin
        // [SCENARIO] A | list of two dates is not a range and is reported exactly as GetFilter renders it
        FirstDate := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 2000);
        SecondDate := FirstDate + Any.IntegerInRange(1, 400);
        CustLedgerEntry.SetFilter("Posting Date", '%1|%2', FirstDate, SecondDate);
        FilterText := CustLedgerEntry.GetFilter("Posting Date");

        Assert.AreEqual(FilterText, DateFilterDescriber.DescribeDateFilter(CustLedgerEntry),
            'Expected an either/or list of dates to be reported exactly as GetFilter renders it — a | list is not a range, so it has no bounds to read');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ComparisonFilterIsReportedVerbatim()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
        FilterText: Text;
    begin
        // [SCENARIO] A >= comparison is not a range and is reported exactly as GetFilter renders it
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 3000);
        CustLedgerEntry.SetFilter("Posting Date", '>=%1', TheDate);
        FilterText := CustLedgerEntry.GetFilter("Posting Date");

        Assert.AreEqual(FilterText, DateFilterDescriber.DescribeDateFilter(CustLedgerEntry),
            'Expected a >= comparison to be reported exactly as GetFilter renders it — an open-ended comparison is not a range with two bounds');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExclusionFilterIsReportedVerbatim()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
        FilterText: Text;
    begin
        // [SCENARIO] A <> exclusion is not a range and is reported exactly as GetFilter renders it
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 3000);
        CustLedgerEntry.SetFilter("Posting Date", '<>%1', TheDate);
        FilterText := CustLedgerEntry.GetFilter("Posting Date");

        Assert.AreEqual(FilterText, DateFilterDescriber.DescribeDateFilter(CustLedgerEntry),
            'Expected a <> exclusion to be reported exactly as GetFilter renders it — an exclusion is not a range');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesTheCallersFiltersUntouched()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstDate: Date;
        SecondDate: Date;
        FiltersBefore: Text;
    begin
        // [SCENARIO] Describing the filter changes nothing on the caller's record
        FirstDate := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 2000);
        SecondDate := FirstDate + Any.IntegerInRange(1, 400);
        CustLedgerEntry.SetRange("Customer No.", 'TRYAL-RB9');
        CustLedgerEntry.SetFilter("Posting Date", '%1|%2', FirstDate, SecondDate);
        FiltersBefore := CustLedgerEntry.GetFilters();

        DateFilterDescriber.DescribeDateFilter(CustLedgerEntry);

        Assert.AreEqual(FiltersBefore, CustLedgerEntry.GetFilters(),
            'Expected the caller''s filters to be exactly as they were before DescribeDateFilter — describing a filter must not add, change or remove any');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesTheCallersRangeFilterUntouched()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateFilterDescriber: Codeunit "Date Filter Describer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
        FiltersBefore: Text;
    begin
        // [SCENARIO] Reading a range's bounds changes nothing on the caller's record — not even a date..date range with equal bounds
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 3000);
        CustLedgerEntry.SetRange("Customer No.", 'TRYAL-RB10');
        CustLedgerEntry.SetFilter("Posting Date", '%1..%2', TheDate, TheDate);
        FiltersBefore := CustLedgerEntry.GetFilters();

        DateFilterDescriber.DescribeDateFilter(CustLedgerEntry);

        Assert.AreEqual(FiltersBefore, CustLedgerEntry.GetFilters(),
            'Expected the caller''s filters to be exactly as they were before DescribeDateFilter — reading a range''s bounds must not rewrite the "Posting Date" filter, not even to an equivalent one');
    end;
}
