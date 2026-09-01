codeunit 50100 "Never Ordered Customers"
{
    procedure NeverOrderedInPeriod(CustomerNo: Code[20]; FromDate: Date; ToDate: Date): Boolean
    begin
        // TODO: true when no "Cust. Ledger Entry" for CustomerNo has a "Posting Date" from FromDate to ToDate, both inclusive.
    end;

    procedure GetNeverOrderedCustomers(FromDate: Date; ToDate: Date): List of [Code[20]]
    begin
        // TODO: collect the "No." of every Customer record that never ordered in the period.
    end;
}
