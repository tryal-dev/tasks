codeunit 50900 "Customer View Reporter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInViewCountsExactlyTheCallersView()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ViewCity: Text[30];
        OtherCity: Text[30];
    begin
        ViewCity := CopyStr('TRYAL-PF1 ' + Any.AlphabeticText(10), 1, MaxStrLen(ViewCity));
        OtherCity := CopyStr('TRYAL-PF1X ' + Any.AlphabeticText(10), 1, MaxStrLen(OtherCity));
        CreateCustomerInCity(ViewCity);
        CreateCustomerInCity(ViewCity);
        CreateCustomerInCity(ViewCity);
        CreateCustomerInCity(OtherCity);
        CreateCustomerInCity(OtherCity);

        FilteredCustomer.SetRange(City, ViewCity);

        Assert.AreEqual(3, CustomerViewReporter.CountInView(FilteredCustomer),
            'Expected exactly the three customers inside the caller''s city filter — customers outside the view must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInViewSeesEveryCustomerWhenNoFilterIsApplied()
    var
        Customer: Record Customer;
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        CreateCustomerInCity(CopyStr('TRYAL-PF2 ' + Any.AlphabeticText(10), 1, 30));
        CreateCustomerInCity(CopyStr('TRYAL-PF2 ' + Any.AlphabeticText(10), 1, 30));

        Assert.AreEqual(Customer.Count(), CustomerViewReporter.CountInView(FilteredCustomer),
            'Expected a record with no filters applied to report the company''s full customer count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInViewLeavesTheCallersRecordUntouched()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ViewCity: Text[30];
        FiltersBefore: Text;
        PositionBefore: Code[20];
    begin
        ViewCity := CopyStr('TRYAL-PF3 ' + Any.AlphabeticText(10), 1, MaxStrLen(ViewCity));
        CreateCustomerInCity(ViewCity);
        CreateCustomerInCity(ViewCity);
        CreateCustomerInCity(ViewCity);
        FilteredCustomer.SetRange(City, ViewCity);
        FilteredCustomer.FindFirst();
        FiltersBefore := FilteredCustomer.GetFilters();
        PositionBefore := FilteredCustomer."No.";

        CustomerViewReporter.CountInView(FilteredCustomer);

        Assert.AreEqual(FiltersBefore, FilteredCustomer.GetFilters(),
            'Expected the caller''s filters to be exactly as they were before CountInView — the caller''s record must come back untouched');
        Assert.AreEqual(PositionBefore, FilteredCustomer."No.",
            'Expected the caller''s record to still be positioned on the same customer after CountInView');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountBlockedInViewCountsOnlyBlockedCustomersInsideTheView()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ViewCity: Text[30];
        OtherCity: Text[30];
    begin
        ViewCity := CopyStr('TRYAL-PF4 ' + Any.AlphabeticText(10), 1, MaxStrLen(ViewCity));
        OtherCity := CopyStr('TRYAL-PF4X ' + Any.AlphabeticText(10), 1, MaxStrLen(OtherCity));
        CreateBlockedCustomerInCity(ViewCity, "Customer Blocked"::All);
        CreateBlockedCustomerInCity(ViewCity, "Customer Blocked"::Ship);
        CreateCustomerInCity(ViewCity);
        CreateCustomerInCity(ViewCity);
        CreateBlockedCustomerInCity(OtherCity, "Customer Blocked"::All);

        FilteredCustomer.SetRange(City, ViewCity);

        Assert.AreEqual(2, CustomerViewReporter.CountBlockedInView(FilteredCustomer),
            'Expected the two blocked customers inside the view — unblocked customers and blocked customers outside the view must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountBlockedInViewIsZeroWhenTheViewHasNoBlockedCustomers()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ViewCity: Text[30];
        OtherCity: Text[30];
    begin
        ViewCity := CopyStr('TRYAL-PF5 ' + Any.AlphabeticText(10), 1, MaxStrLen(ViewCity));
        OtherCity := CopyStr('TRYAL-PF5X ' + Any.AlphabeticText(10), 1, MaxStrLen(OtherCity));
        CreateCustomerInCity(ViewCity);
        CreateCustomerInCity(ViewCity);
        CreateBlockedCustomerInCity(OtherCity, "Customer Blocked"::All);

        FilteredCustomer.SetRange(City, ViewCity);

        Assert.AreEqual(0, CustomerViewReporter.CountBlockedInView(FilteredCustomer),
            'Expected 0 for a view that contains customers but no blocked ones — the blocked decoy outside the view must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountBlockedInViewLeavesTheCallersFiltersUntouched()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ViewCity: Text[30];
        FiltersBefore: Text;
    begin
        ViewCity := CopyStr('TRYAL-PF6 ' + Any.AlphabeticText(10), 1, MaxStrLen(ViewCity));
        CreateBlockedCustomerInCity(ViewCity, "Customer Blocked"::Invoice);
        CreateCustomerInCity(ViewCity);
        CreateCustomerInCity(ViewCity);
        FilteredCustomer.SetRange(City, ViewCity);
        FiltersBefore := FilteredCustomer.GetFilters();

        CustomerViewReporter.CountBlockedInView(FilteredCustomer);

        Assert.AreEqual(FiltersBefore, FilteredCustomer.GetFilters(),
            'Expected the caller''s filters to be exactly as they were before CountBlockedInView — no extra filter may be left behind and none may be removed');
        Assert.AreEqual(3, FilteredCustomer.Count(),
            'Expected the caller''s record to still see its full three-customer view after CountBlockedInView — the caller''s view was narrowed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountBlockedInViewDoesNotMoveTheCallersPosition()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ViewCity: Text[30];
        PositionBefore: Code[20];
    begin
        ViewCity := CopyStr('TRYAL-PF7 ' + Any.AlphabeticText(10), 1, MaxStrLen(ViewCity));
        CreateCustomerInCity(ViewCity);
        CreateBlockedCustomerInCity(ViewCity, "Customer Blocked"::All);
        CreateCustomerInCity(ViewCity);
        FilteredCustomer.SetRange(City, ViewCity);
        FilteredCustomer.FindFirst();
        PositionBefore := FilteredCustomer."No.";

        CustomerViewReporter.CountBlockedInView(FilteredCustomer);

        Assert.AreEqual(PositionBefore, FilteredCustomer."No.",
            'Expected the caller''s record to still be positioned on the same customer after CountBlockedInView');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountBlockedInViewPreservesTheCallersOwnBlockedFilter()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ViewCity: Text[30];
        FiltersBefore: Text;
        CountBefore: Integer;
    begin
        ViewCity := CopyStr('TRYAL-PF9 ' + Any.AlphabeticText(10), 1, MaxStrLen(ViewCity));
        CreateBlockedCustomerInCity(ViewCity, "Customer Blocked"::Ship);
        CreateBlockedCustomerInCity(ViewCity, "Customer Blocked"::All);
        CreateCustomerInCity(ViewCity);
        FilteredCustomer.SetRange(City, ViewCity);
        FilteredCustomer.SetRange(Blocked, "Customer Blocked"::Ship);
        FiltersBefore := FilteredCustomer.GetFilters();
        CountBefore := FilteredCustomer.Count();

        Assert.AreEqual(2, CustomerViewReporter.CountBlockedInView(FilteredCustomer),
            'Expected both blocked customers in the city — the count replaces the caller''s own Blocked filter with "any blocked state" instead of intersecting with it');

        Assert.AreEqual(FiltersBefore, FilteredCustomer.GetFilters(),
            'Expected the caller''s own Blocked filter to survive CountBlockedInView — clearing the field''s filter afterwards wipes a filter the caller had set itself');
        Assert.AreEqual(CountBefore, FilteredCustomer.Count(),
            'Expected the caller''s record to still see exactly its own view after CountBlockedInView — the caller''s Blocked filter was lost or replaced');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DescribeViewRendersEveryAppliedFilter()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ViewCity: Text[30];
        ExpectedView: Text;
    begin
        ViewCity := CopyStr('TRYAL-PF8 ' + Any.AlphabeticText(10), 1, MaxStrLen(ViewCity));
        FilteredCustomer.SetRange(City, ViewCity);
        FilteredCustomer.SetFilter("Credit Limit (LCY)", '>%1', 1000);
        ExpectedView := FilteredCustomer.GetFilters();

        Assert.AreEqual(ExpectedView, CustomerViewReporter.DescribeView(FilteredCustomer),
            'Expected the reported view to match the platform''s own rendering of the caller''s filters, character for character');
        Assert.AreEqual(ExpectedView, FilteredCustomer.GetFilters(),
            'Expected the caller''s filters to be exactly as they were before DescribeView — the caller''s record must come back untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DescribeViewIsEmptyForAnUnfilteredRecord()
    var
        FilteredCustomer: Record Customer;
        CustomerViewReporter: Codeunit "Customer View Reporter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', CustomerViewReporter.DescribeView(FilteredCustomer),
            'Expected empty text for a record with no filters applied');
    end;

    local procedure CreateCustomerInCity(CityName: Text[30])
    begin
        CreateBlockedCustomerInCity(CityName, "Customer Blocked"::" ");
    end;

    local procedure CreateBlockedCustomerInCity(CityName: Text[30]; BlockedValue: Enum "Customer Blocked")
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(City, CityName);
        Customer.Validate(Blocked, BlockedValue);
        Customer.Modify(true);
    end;
}
