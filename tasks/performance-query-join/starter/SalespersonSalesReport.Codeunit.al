codeunit 50100 "Salesperson Sales Report"
{
    procedure TotalSalesBySalesperson(SalespersonFilter: Text): Dictionary of [Code[20], Decimal]
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Totals: Dictionary of [Code[20], Decimal];
        Total: Decimal;
    begin
        // TODO: the numbers below are right — the cost is not. One round trip
        // for the customers, then one MORE round trip per customer: the report
        // spends 1 + N SQL statements and the grading budget allows 4.
        Customer.SetFilter("Salesperson Code", SalespersonFilter);
        if Customer.FindSet() then
            repeat
                Total := 0;
                CustLedgerEntry.SetRange("Customer No.", Customer."No.");
                if CustLedgerEntry.FindSet() then
                    repeat
                        Total += CustLedgerEntry."Sales (LCY)";
                    until CustLedgerEntry.Next() = 0;
                if Totals.ContainsKey(Customer."Salesperson Code") then
                    Totals.Set(Customer."Salesperson Code", Totals.Get(Customer."Salesperson Code") + Total)
                else
                    Totals.Add(Customer."Salesperson Code", Total);
            until Customer.Next() = 0;
        exit(Totals);
    end;
}
