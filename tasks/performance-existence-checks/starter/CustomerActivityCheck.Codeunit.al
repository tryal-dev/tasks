codeunit 50100 "Customer Activity Check"
{
    // TODO: the answers below are right — the price is not. Every procedure
    // fetches the customer's ledger entries into AL to look at them one by one,
    // so a 200-entry customer costs 200 rows for a yes/no. The grading budget
    // allows 5 SQL statements and 10 rows per call.

    procedure HasOpenEntries(CustomerNo: Code[20]): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if CustLedgerEntry.FindSet() then
            repeat
                if CustLedgerEntry.Open then
                    exit(true);
            until CustLedgerEntry.Next() = 0;
        exit(false);
    end;

    procedure IsDormant(CustomerNo: Code[20]): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryCount: Integer;
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if CustLedgerEntry.FindSet() then
            repeat
                EntryCount += 1;
            until CustLedgerEntry.Next() = 0;
        exit(EntryCount = 0);
    end;

    procedure OpenEntryCount(CustomerNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Result: Integer;
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if CustLedgerEntry.FindSet() then
            repeat
                if CustLedgerEntry.Open then
                    Result += 1;
            until CustLedgerEntry.Next() = 0;
        exit(Result);
    end;
}
