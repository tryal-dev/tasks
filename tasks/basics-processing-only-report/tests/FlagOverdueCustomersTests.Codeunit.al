codeunit 50900 "Flag Overdue Customers Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsAnUnblockedCustomerWithABalanceDue()
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        AmountDue: Decimal;
    begin
        // [SCENARIO] An unblocked customer with a positive balance due gets the follow-up flag
        AmountDue := Any.DecimalInRange(100, 900, 2);
        CustomerNo := CreateCustomer("Customer Blocked"::" ");
        AddOpenInvoice(CustomerNo, AmountDue, WorkDate() - 10);

        RunReportOn(Customer, CustomerNo);

        AssertFlagged(CustomerNo, StrSubstNo('it is not blocked and has %1 due on or before the work date', AmountDue));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsACustomerWithNothingDue()
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] A customer without any ledger entries has a balance due of 0 and is skipped
        CustomerNo := CreateCustomer("Customer Blocked"::" ");

        RunReportOn(Customer, CustomerNo);

        AssertNotFlagged(CustomerNo, 'it has no ledger entries, so its Balance Due (LCY) is 0 and the report must skip it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsACustomerWithACreditBalance()
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] A negative balance due (the customer is owed money) is not a reason for follow-up
        CustomerNo := CreateCustomer("Customer Blocked"::" ");
        AddOpenInvoice(CustomerNo, -Any.DecimalInRange(100, 900, 2), WorkDate() - 10);

        RunReportOn(Customer, CustomerNo);

        AssertNotFlagged(CustomerNo, 'its Balance Due (LCY) is negative — only a balance due greater than zero earns the flag');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsACustomerWhoseInvoicesAreNotYetDue()
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] An invoice that falls due after the Date Filter's end does not count as due
        CustomerNo := CreateCustomer("Customer Blocked"::" ");
        AddOpenInvoice(CustomerNo, Any.DecimalInRange(100, 900, 2), WorkDate() + 30);

        RunReportOn(Customer, CustomerNo);

        AssertNotFlagged(CustomerNo, 'its only invoice falls due after the work date, so under a Date Filter ending on the work date its Balance Due (LCY) is 0 — the report must decide on "Balance Due (LCY)", not on "Balance (LCY)"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsBlockedCustomersWhateverTheirBalance()
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        ShipBlockedNo: Code[20];
        InvoiceBlockedNo: Code[20];
        AllBlockedNo: Code[20];
        OpenNo: Code[20];
    begin
        // [SCENARIO] Customers blocked as Ship, Invoice or All are outside the report's scope even with a balance due
        ShipBlockedNo := CreateCustomer("Customer Blocked"::Ship);
        InvoiceBlockedNo := CreateCustomer("Customer Blocked"::Invoice);
        AllBlockedNo := CreateCustomer("Customer Blocked"::All);
        OpenNo := CreateCustomer("Customer Blocked"::" ");
        AddOpenInvoice(ShipBlockedNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);
        AddOpenInvoice(InvoiceBlockedNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);
        AddOpenInvoice(AllBlockedNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);
        AddOpenInvoice(OpenNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);

        RunReportOn(Customer, StrSubstNo('%1|%2|%3|%4', ShipBlockedNo, InvoiceBlockedNo, AllBlockedNo, OpenNo));

        AssertNotFlagged(ShipBlockedNo, 'it is blocked as Ship — the report must narrow the selection to customers whose Blocked field is blank');
        AssertNotFlagged(InvoiceBlockedNo, 'it is blocked as Invoice — the report must narrow the selection to customers whose Blocked field is blank');
        AssertNotFlagged(AllBlockedNo, 'it is blocked as All — the report must narrow the selection to customers whose Blocked field is blank');
        AssertFlagged(OpenNo, 'it is the one customer in the selection that is not blocked and has a balance due');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RespectsTheCallersFilter()
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        InsideNo: Code[20];
        OutsideNo: Code[20];
    begin
        // [SCENARIO] Only customers inside the caller's No. filter are processed
        InsideNo := CreateCustomer("Customer Blocked"::" ");
        OutsideNo := CreateCustomer("Customer Blocked"::" ");
        AddOpenInvoice(InsideNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);
        AddOpenInvoice(OutsideNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);

        RunReportOn(Customer, InsideNo);

        AssertFlagged(InsideNo, 'it is inside the caller''s No. filter, not blocked, and has a balance due');
        AssertNotFlagged(OutsideNo, 'it lies outside the No. filter the caller passed — the report must narrow the caller''s filters, never reset or replace them');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesSkippedCustomersUntouched()
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] A skipped customer that already carries the flag keeps it
        CustomerNo := CreateCustomer("Customer Blocked"::" ");
        Customer.Get(CustomerNo);
        Customer."Follow-Up Required" := true;
        Customer.Modify();

        RunReportOn(Customer, CustomerNo);

        AssertFlagged(CustomerNo, 'it had nothing due and was already flagged, so the report must skip it and leave the flag alone — the report only ever sets the flag, never clears it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsTheCustomersItFlagged()
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        NoFilter: Text;
        ExpectedCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] GetFlaggedCount reports how many customers the run flagged, skipped ones excluded
        ExpectedCount := Any.IntegerInRange(2, 4);
        for i := 1 to ExpectedCount do begin
            CustomerNo := CreateCustomer("Customer Blocked"::" ");
            AddOpenInvoice(CustomerNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);
            NoFilter := AppendToFilter(NoFilter, CustomerNo);
        end;
        NoFilter := AppendToFilter(NoFilter, CreateCustomer("Customer Blocked"::" "));
        CustomerNo := CreateCustomer("Customer Blocked"::All);
        AddOpenInvoice(CustomerNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);
        NoFilter := AppendToFilter(NoFilter, CustomerNo);

        Assert.AreEqual(ExpectedCount, RunReportAndCount(Customer, NoFilter),
            'Expected GetFlaggedCount() to return the number of customers this run flagged — the unblocked ones with a balance due, not the customer with nothing due and not the blocked one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountIsZeroWhenEveryCustomerIsSkipped()
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        NoFilter: Text;
    begin
        // [SCENARIO] Customers that are skipped or filtered out are not counted
        NoFilter := AppendToFilter(NoFilter, CreateCustomer("Customer Blocked"::" "));
        CustomerNo := CreateCustomer("Customer Blocked"::" ");
        AddOpenInvoice(CustomerNo, Any.DecimalInRange(100, 900, 2), WorkDate() + 30);
        NoFilter := AppendToFilter(NoFilter, CustomerNo);
        CustomerNo := CreateCustomer("Customer Blocked"::All);
        AddOpenInvoice(CustomerNo, Any.DecimalInRange(100, 900, 2), WorkDate() - 10);
        NoFilter := AppendToFilter(NoFilter, CustomerNo);

        Assert.AreEqual(0, RunReportAndCount(Customer, NoFilter),
            'Expected GetFlaggedCount() to be 0 when every customer in the selection is skipped or blocked — processed records are not the same as flagged ones');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsDeclaredProcessingOnly()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        // [SCENARIO] The report declares itself as processing-only
        ReportMetadata.Get(Report::"Flag Overdue Customers");

        Assert.IsTrue(ReportMetadata.ProcessingOnly,
            'Expected report "Flag Overdue Customers" to declare ProcessingOnly = true — it changes data and prints nothing, so it must not need a layout');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunsWithoutARequestPage()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        // [SCENARIO] The report declares that it has no request page
        ReportMetadata.Get(Report::"Flag Overdue Customers");

        Assert.IsFalse(ReportMetadata.UseRequestPage,
            'Expected report "Flag Overdue Customers" to declare UseRequestPage = false, so a job queue entry or an action can run it without anyone answering a request page');
    end;

    local procedure RunReportOn(var Customer: Record Customer; NoFilter: Text)
    begin
        ApplyCallerView(Customer, NoFilter);
        Report.Run(Report::"Flag Overdue Customers", false, false, Customer);
    end;

    local procedure RunReportAndCount(var Customer: Record Customer; NoFilter: Text): Integer
    var
        FlagOverdueCustomers: Report "Flag Overdue Customers";
    begin
        ApplyCallerView(Customer, NoFilter);
        FlagOverdueCustomers.SetTableView(Customer);
        FlagOverdueCustomers.UseRequestPage(false);
        // RunModal, not Run: Run clears the report variable afterwards, and the count with it.
        FlagOverdueCustomers.RunModal();
        exit(FlagOverdueCustomers.GetFlaggedCount());
    end;

    local procedure ApplyCallerView(var Customer: Record Customer; NoFilter: Text)
    begin
        Customer.Reset();
        Customer.SetFilter("No.", NoFilter);
        Customer.SetRange("Date Filter", 0D, WorkDate());
    end;

    local procedure AppendToFilter(NoFilter: Text; CustomerNo: Code[20]): Text
    begin
        if NoFilter = '' then
            exit(CustomerNo);
        exit(NoFilter + '|' + CustomerNo);
    end;

    local procedure AssertFlagged(CustomerNo: Code[20]; Why: Text)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Assert.IsTrue(Customer."Follow-Up Required",
            StrSubstNo('Expected customer %1 to be flagged (Follow-Up Required = true): %2', CustomerNo, Why));
    end;

    local procedure AssertNotFlagged(CustomerNo: Code[20]; Why: Text)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Assert.IsFalse(Customer."Follow-Up Required",
            StrSubstNo('Expected customer %1 NOT to be flagged (Follow-Up Required = false): %2', CustomerNo, Why));
    end;

    local procedure CreateCustomer(BlockedAs: Enum "Customer Blocked"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Blocked := BlockedAs;
        Customer.Modify();
        exit(Customer."No.");
    end;

    // "Balance Due (LCY)" sums Detailed Cust. Ledg. Entry amounts by customer and
    // "Initial Entry Due Date"; a ledger entry pair inserted directly is all the
    // FlowField needs, with no posting (and no commit) involved.
    local procedure AddOpenInvoice(CustomerNo: Code[20]; AmountLCY: Decimal; DueDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := NextCustLedgerEntryNo();
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := DueDate - 30;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := StrSubstNo('TRYAL-%1', CustLedgerEntry."Entry No.");
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Positive := AmountLCY > 0;
        CustLedgerEntry.Insert();

        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := NextDetailedCustLedgEntryNo();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry."Posting Date" := CustLedgerEntry."Posting Date";
        DetailedCustLedgEntry."Document Type" := DetailedCustLedgEntry."Document Type"::Invoice;
        DetailedCustLedgEntry."Document No." := CustLedgerEntry."Document No.";
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry.Amount := AmountLCY;
        DetailedCustLedgEntry."Amount (LCY)" := AmountLCY;
        DetailedCustLedgEntry."Initial Entry Due Date" := DueDate;
        DetailedCustLedgEntry."Initial Document Type" := DetailedCustLedgEntry."Initial Document Type"::Invoice;
        DetailedCustLedgEntry."Ledger Entry Amount" := true;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure NextCustLedgerEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then
            exit(CustLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure NextDetailedCustLedgEntryNo(): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DetailedCustLedgEntry.FindLast() then
            exit(DetailedCustLedgEntry."Entry No." + 1);
        exit(1);
    end;
}
