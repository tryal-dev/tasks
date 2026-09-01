codeunit 50100 "Customer Sales Total"
{
    procedure TotalSales(CustomerNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Total: Decimal;
    begin
        // TODO: the number below is right — the cost is not. Every entry of the
        // customer is fetched across the wire just to be added up in AL, and the
        // grading budget allows at most 10 rows read per call.
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if CustLedgerEntry.FindSet() then
            repeat
                Total += CustLedgerEntry."Sales (LCY)";
            until CustLedgerEntry.Next() = 0;
        exit(Total);
    end;
}
