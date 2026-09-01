codeunit 50900 "Monthly Buckets Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthlySalesSumsEachPostingMonthIntoItsBucket()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        CustomerNo: Code[20];
        Year: Integer;
        MidMonth: Integer;
        Month: Integer;
        JanuaryAmount: Decimal;
        FirstMidAmount: Decimal;
        SecondMidAmount: Decimal;
        DecemberAmount: Decimal;
    begin
        // [SCENARIO] Every entry lands in the bucket of its posting month and months without entries stay at zero
        // [GIVEN] a customer with an entry on 1 January, two in one mid-year month and one on 31 December of the year
        CustomerNo := CreateCustomer();
        Year := Any.IntegerInRange(2010, 2040);
        MidMonth := Any.IntegerInRange(3, 10);
        JanuaryAmount := Any.DecimalInRange(100, 900, 2);
        FirstMidAmount := Any.DecimalInRange(100, 900, 2);
        SecondMidAmount := Any.DecimalInRange(100, 900, 2);
        DecemberAmount := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(1, 1, Year), JanuaryAmount);
        MockLedgerEntry(CustomerNo, DMY2Date(3, MidMonth, Year), FirstMidAmount);
        MockLedgerEntry(CustomerNo, DMY2Date(28, MidMonth, Year), SecondMidAmount);
        MockLedgerEntry(CustomerNo, DMY2Date(31, 12, Year), DecemberAmount);

        // [WHEN] collecting the monthly sales of that year
        MonthlyBuckets.MonthlySales(CustomerNo, Year, Buckets);

        // [THEN] the three months carry their sums and the other nine are exactly zero
        Assert.AreEqual(JanuaryAmount, Buckets[1], 'Expected the entry posted on 1 January to land in bucket 1');
        Assert.AreEqual(FirstMidAmount + SecondMidAmount, Buckets[MidMonth],
            StrSubstNo('Expected the two entries posted in month %1 to be added up in bucket %1', MidMonth));
        Assert.AreEqual(DecemberAmount, Buckets[12], 'Expected the entry posted on 31 December to land in bucket 12');
        for Month := 1 to 12 do
            if not (Month in [1, MidMonth, 12]) then
                Assert.AreEqual(0.0, Buckets[Month], StrSubstNo('Expected bucket %1 to be exactly 0 — no entry was posted in that month', Month));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthlySalesIgnoresTheNeighbouringYears()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        CustomerNo: Code[20];
        Year: Integer;
        MidMonth: Integer;
        Amount: Decimal;
    begin
        // [SCENARIO] Entries posted one day before and one day after the year are not counted
        // [GIVEN] a customer with one entry inside the year, one on 31 December of the year before and one on 1 January of the year after
        CustomerNo := CreateCustomer();
        Year := Any.IntegerInRange(2010, 2040);
        MidMonth := Any.IntegerInRange(3, 10);
        Amount := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(15, MidMonth, Year), Amount);
        MockLedgerEntry(CustomerNo, DMY2Date(31, 12, Year - 1), Any.DecimalInRange(1000, 2000, 2));
        MockLedgerEntry(CustomerNo, DMY2Date(1, 1, Year + 1), Any.DecimalInRange(1000, 2000, 2));

        // [WHEN] collecting the monthly sales of the year in the middle
        MonthlyBuckets.MonthlySales(CustomerNo, Year, Buckets);

        // [THEN] only the entry inside the year is counted
        Assert.AreEqual(Amount, Buckets[MidMonth], StrSubstNo('Expected the entry posted in month %1 of %2 in bucket %1', MidMonth, Year));
        Assert.AreEqual(0.0, Buckets[12], StrSubstNo('Expected bucket 12 to be 0 — the entry posted on 31 December %1 belongs to that year, not to %2', Year - 1, Year));
        Assert.AreEqual(0.0, Buckets[1], StrSubstNo('Expected bucket 1 to be 0 — the entry posted on 1 January %1 belongs to that year, not to %2', Year + 1, Year));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthlySalesCountsOnlyTheGivenCustomer()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        CustomerNo: Code[20];
        OtherCustomerNo: Code[20];
        Year: Integer;
        MidMonth: Integer;
        Amount: Decimal;
    begin
        // [SCENARIO] Another customer's entry in the same month does not leak into the buckets
        // [GIVEN] two customers with an entry each in the same month of the same year
        CustomerNo := CreateCustomer();
        OtherCustomerNo := CreateCustomer();
        Year := Any.IntegerInRange(2010, 2040);
        MidMonth := Any.IntegerInRange(1, 12);
        Amount := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(10, MidMonth, Year), Amount);
        MockLedgerEntry(OtherCustomerNo, DMY2Date(20, MidMonth, Year), Any.DecimalInRange(1000, 2000, 2));

        // [WHEN] collecting the monthly sales of the first customer
        MonthlyBuckets.MonthlySales(CustomerNo, Year, Buckets);

        // [THEN] the bucket holds only the first customer's amount
        Assert.AreEqual(Amount, Buckets[MidMonth],
            StrSubstNo('Expected bucket %1 to hold only the given customer''s entry — another customer''s entry in the same month leaked in', MidMonth));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthlySalesOverwritesWhateverTheBucketsHeldBefore()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        CustomerNo: Code[20];
        Year: Integer;
        MidMonth: Integer;
        Month: Integer;
        Amount: Decimal;
    begin
        // [SCENARIO] Leftover numbers in the caller's array do not survive the call
        // [GIVEN] an array holding 999 in every slot and a customer with a single entry in the year
        for Month := 1 to 12 do
            Buckets[Month] := 999;
        CustomerNo := CreateCustomer();
        Year := Any.IntegerInRange(2010, 2040);
        MidMonth := Any.IntegerInRange(1, 12);
        Amount := Any.DecimalInRange(100, 900, 2);
        MockLedgerEntry(CustomerNo, DMY2Date(5, MidMonth, Year), Amount);

        // [WHEN] collecting the monthly sales into the pre-filled array
        MonthlyBuckets.MonthlySales(CustomerNo, Year, Buckets);

        // [THEN] the entry's bucket holds exactly the amount and every other bucket is zero
        Assert.AreEqual(Amount, Buckets[MidMonth],
            StrSubstNo('Expected bucket %1 to hold exactly the entry''s amount — the 999 left in the array from before the call must not be added to it', MidMonth));
        for Month := 1 to 12 do
            if Month <> MidMonth then
                Assert.AreEqual(0.0, Buckets[Month],
                    StrSubstNo('Expected bucket %1 to be 0 — the 999 left in the array from before the call must be cleared', Month));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddToMonthAddsTheAmountOnTopOfTheBucket()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        TargetMonth: Integer;
        Month: Integer;
        Amount: Decimal;
    begin
        // [SCENARIO] The amount is added to the chosen bucket and the other eleven keep their values
        // [GIVEN] an array where slot n holds n * 10
        for Month := 1 to 12 do
            Buckets[Month] := Month * 10;
        TargetMonth := Any.IntegerInRange(1, 12);
        Amount := Any.DecimalInRange(100, 900, 2);

        // [WHEN] adding an amount to one month
        MonthlyBuckets.AddToMonth(Buckets, TargetMonth, Amount);

        // [THEN] that bucket grew by the amount and no other bucket changed
        Assert.AreEqual(TargetMonth * 10 + Amount, Buckets[TargetMonth],
            StrSubstNo('Expected bucket %1 to hold its previous value plus the amount — AddToMonth adds, it does not replace', TargetMonth));
        for Month := 1 to 12 do
            if Month <> TargetMonth then
                Assert.AreEqual(Month * 10.0, Buckets[Month],
                    StrSubstNo('Expected bucket %1 to keep its value when month %2 was the target', Month, TargetMonth));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddToMonthPutsJanuaryInSlotOne()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Amount: Decimal;
    begin
        // [SCENARIO] Month 1 is the first slot of the array — AL arrays start at 1, not 0
        // [GIVEN] an empty array and an amount
        Amount := Any.DecimalInRange(100, 900, 2);

        // [WHEN] adding the amount to month 1
        MonthlyBuckets.AddToMonth(Buckets, 1, Amount);

        // [THEN] slot 1 holds the amount
        Assert.AreEqual(Amount, Buckets[1], 'Expected month 1 to land in slot 1 — the first slot of an AL array is 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddToMonthRefusesMonthThirteen()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Month: Integer;
    begin
        // [SCENARIO] A thirteenth month does not exist and must be rejected without touching the array
        // [GIVEN] an array where slot n holds n * 10
        for Month := 1 to 12 do
            Buckets[Month] := Month * 10;

        // [WHEN] adding an amount to month 13
        asserterror MonthlyBuckets.AddToMonth(Buckets, 13, Any.DecimalInRange(100, 900, 2));

        // [THEN] the promised error is raised and every bucket is untouched
        Assert.ExpectedError('must be between 1 and 12');
        for Month := 1 to 12 do
            Assert.AreEqual(Month * 10.0, Buckets[Month],
                StrSubstNo('Expected bucket %1 to be untouched after month 13 was refused', Month));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddToMonthRefusesMonthZero()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
    begin
        // [SCENARIO] Month 0 is below the first slot and must be rejected
        // [WHEN] adding an amount to month 0
        asserterror MonthlyBuckets.AddToMonth(Buckets, 0, Any.DecimalInRange(100, 900, 2));

        // [THEN] the promised error is raised
        Assert.ExpectedError('must be between 1 and 12');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuarterTotalsFoldsThreeMonthsIntoEachQuarter()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Quarters: array[4] of Decimal;
        Month: Integer;
    begin
        // [SCENARIO] Each quarter is the sum of its three months
        // [GIVEN] twelve generated monthly totals
        for Month := 1 to 12 do
            Buckets[Month] := Any.DecimalInRange(1, 1000, 2);

        // [WHEN] folding them into quarters
        MonthlyBuckets.QuarterTotals(Buckets, Quarters);

        // [THEN] every quarter equals the sum of its three months
        Assert.AreEqual(Buckets[1] + Buckets[2] + Buckets[3], Quarters[1], 'Expected quarter 1 to be the sum of months 1 to 3');
        Assert.AreEqual(Buckets[4] + Buckets[5] + Buckets[6], Quarters[2], 'Expected quarter 2 to be the sum of months 4 to 6');
        Assert.AreEqual(Buckets[7] + Buckets[8] + Buckets[9], Quarters[3], 'Expected quarter 3 to be the sum of months 7 to 9');
        Assert.AreEqual(Buckets[10] + Buckets[11] + Buckets[12], Quarters[4], 'Expected quarter 4 to be the sum of months 10 to 12');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuarterTotalsOverwritesWhateverTheQuartersHeldBefore()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Quarters: array[4] of Decimal;
        Quarter: Integer;
        Amount: Decimal;
    begin
        // [SCENARIO] Leftover numbers in the caller's quarters array do not survive the call
        // [GIVEN] a quarters array holding 999 everywhere and buckets with a single amount in May
        for Quarter := 1 to 4 do
            Quarters[Quarter] := 999;
        Amount := Any.DecimalInRange(100, 900, 2);
        Buckets[5] := Amount;

        // [WHEN] folding the buckets into the pre-filled quarters array
        MonthlyBuckets.QuarterTotals(Buckets, Quarters);

        // [THEN] quarter 2 holds exactly the May amount and the other quarters are zero
        Assert.AreEqual(0.0, Quarters[1], 'Expected quarter 1 to be 0 — the 999 left in the array from before the call must be cleared');
        Assert.AreEqual(Amount, Quarters[2], 'Expected quarter 2 to hold exactly the May amount — the 999 left in the array from before the call must not be added to it');
        Assert.AreEqual(0.0, Quarters[3], 'Expected quarter 3 to be 0 — the 999 left in the array from before the call must be cleared');
        Assert.AreEqual(0.0, Quarters[4], 'Expected quarter 4 to be 0 — the 999 left in the array from before the call must be cleared');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShiftWindowDropsTheOldestMonthAndAppendsTheNewest()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Original: array[12] of Decimal;
        Month: Integer;
        NewMonthTotal: Decimal;
    begin
        // [SCENARIO] The window moves forward by one month
        // [GIVEN] twelve generated monthly totals and a total for the month that just closed
        for Month := 1 to 12 do begin
            Original[Month] := Any.DecimalInRange(1, 1000, 2);
            Buckets[Month] := Original[Month];
        end;
        NewMonthTotal := Any.DecimalInRange(1001, 2000, 2);

        // [WHEN] shifting the window
        MonthlyBuckets.ShiftWindow(Buckets, NewMonthTotal);

        // [THEN] slots 1 to 11 hold the old slots 2 to 12 and slot 12 holds the new month
        for Month := 1 to 11 do
            Assert.AreEqual(Original[Month + 1], Buckets[Month],
                StrSubstNo('Expected slot %1 to hold what slot %2 held before the shift', Month, Month + 1));
        Assert.AreEqual(NewMonthTotal, Buckets[12], 'Expected slot 12 to hold the new month''s total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonEmptyMonthLabelsPacksTheLabelsToTheFront()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Labels: array[12] of Text;
        Slot: Integer;
        LabelCount: Integer;
    begin
        // [SCENARIO] Only the months with sales get a label, in calendar order, with no gaps
        // [GIVEN] sales in February, July and November
        Buckets[2] := Any.DecimalInRange(100, 900, 2);
        Buckets[7] := Any.DecimalInRange(100, 900, 2);
        Buckets[11] := Any.DecimalInRange(100, 900, 2);

        // [WHEN] building the labels
        LabelCount := MonthlyBuckets.NonEmptyMonthLabels(Buckets, Labels);

        // [THEN] the three labels fill slots 1 to 3, the rest are empty, and 3 is returned
        Assert.AreEqual(3, LabelCount, 'Expected the number of non-empty months to be returned');
        Assert.AreEqual('Feb', Labels[1], 'Expected the first label to be Feb — the earliest month with sales moves to slot 1');
        Assert.AreEqual('Jul', Labels[2], 'Expected the second label to be Jul — labels are packed with no gap between them');
        Assert.AreEqual('Nov', Labels[3], 'Expected the third label to be Nov');
        for Slot := 4 to 12 do
            Assert.AreEqual('', Labels[Slot], StrSubstNo('Expected label slot %1 to be empty — only three months had sales', Slot));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonEmptyMonthLabelsTreatsANegativeMonthAsNonEmpty()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Labels: array[12] of Text;
        LabelCount: Integer;
    begin
        // [SCENARIO] A month whose total is negative is still a month with activity
        // [GIVEN] a negative total in April and a positive one in September
        Buckets[4] := -Any.DecimalInRange(100, 900, 2);
        Buckets[9] := Any.DecimalInRange(100, 900, 2);

        // [WHEN] building the labels
        LabelCount := MonthlyBuckets.NonEmptyMonthLabels(Buckets, Labels);

        // [THEN] April is labelled like any other non-empty month
        Assert.AreEqual(2, LabelCount, 'Expected 2 labels — a negative month counts as non-empty, only an exact 0 is empty');
        Assert.AreEqual('Apr', Labels[1], 'Expected the negative April to be labelled in slot 1 — only an exact 0 is an empty month');
        Assert.AreEqual('Sep', Labels[2], 'Expected Sep in slot 2, right after Apr');
        Assert.AreEqual('', Labels[3], 'Expected label slot 3 to be empty — only two months had activity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonEmptyMonthLabelsOverwritesWhateverTheLabelsHeldBefore()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Labels: array[12] of Text;
        Slot: Integer;
        LabelCount: Integer;
    begin
        // [SCENARIO] Stale labels in the caller's array do not survive the call
        // [GIVEN] a label array holding a stale text in every slot and sales in May only
        for Slot := 1 to 12 do
            Labels[Slot] := 'stale';
        Buckets[5] := Any.DecimalInRange(100, 900, 2);

        // [WHEN] building the labels into the pre-filled array
        LabelCount := MonthlyBuckets.NonEmptyMonthLabels(Buckets, Labels);

        // [THEN] May is the only label and every other slot is empty
        Assert.AreEqual(1, LabelCount, 'Expected 1 label — only May had sales');
        Assert.AreEqual('May', Labels[1], 'Expected May in slot 1 — the stale texts left in the array from before the call must be cleared, not compressed in');
        for Slot := 2 to 12 do
            Assert.AreEqual('', Labels[Slot], StrSubstNo('Expected label slot %1 to be empty — the stale text left there from before the call must be cleared', Slot));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonEmptyMonthLabelsLabelsEveryMonthWhenAllTwelveHaveSales()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Buckets: array[12] of Decimal;
        Labels: array[12] of Text;
        ExpectedLabels: Text;
        Month: Integer;
        LabelCount: Integer;
    begin
        // [SCENARIO] A year with sales in every month yields all twelve abbreviations in calendar order with no empty slot left
        // [GIVEN] a generated amount in each of the twelve buckets
        for Month := 1 to 12 do
            Buckets[Month] := Any.DecimalInRange(100, 900, 2);
        ExpectedLabels := 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

        // [WHEN] building the labels
        LabelCount := MonthlyBuckets.NonEmptyMonthLabels(Buckets, Labels);

        // [THEN] twelve labels are returned and slot n holds the abbreviation of month n
        Assert.AreEqual(12, LabelCount, 'Expected 12 labels when every month had sales');
        for Month := 1 to 12 do
            Assert.AreEqual(SelectStr(Month, ExpectedLabels), Labels[Month],
                StrSubstNo('Expected label slot %1 to hold the English three-letter abbreviation of month %1 — mind the exact spelling', Month));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonEmptyMonthLabelsReturnsZeroForAYearWithoutSales()
    var
        MonthlyBuckets: Codeunit "Monthly Buckets";
        Assert: Codeunit Assert;
        Buckets: array[12] of Decimal;
        Labels: array[12] of Text;
        Slot: Integer;
        LabelCount: Integer;
    begin
        // [SCENARIO] Twelve empty months give twelve empty labels and a count of zero
        // [WHEN] building the labels for an all-zero year
        LabelCount := MonthlyBuckets.NonEmptyMonthLabels(Buckets, Labels);

        // [THEN] nothing is labelled
        Assert.AreEqual(0, LabelCount, 'Expected 0 labels for a year without a single non-empty month');
        for Slot := 1 to 12 do
            Assert.AreEqual('', Labels[Slot], StrSubstNo('Expected label slot %1 to be empty for a year without sales', Slot));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
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
}
