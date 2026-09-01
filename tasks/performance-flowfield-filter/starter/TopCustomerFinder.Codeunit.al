codeunit 50100 "Top Customer Finder"
{
    procedure CustomersOverThreshold(FromDate: Date; ToDate: Date; ThresholdLCY: Decimal): List of [Code[20]]
    var
        Customer: Record Customer;
        Result: List of [Code[20]];
    begin
        // TODO: the answer below is almost right — and pays too much for it.
        // Every CalcFields is its own SQL statement, one per customer, and the
        // grading budget allows 8 for the whole call. Worse: a customer number
        // whose card is gone never enters this loop at all, however large its
        // posted sales in the window are.
        Customer.SetRange("Date Filter", FromDate, ToDate);
        if Customer.FindSet() then
            repeat
                Customer.CalcFields("Sales (LCY)");
                if Customer."Sales (LCY)" > ThresholdLCY then
                    Result.Add(Customer."No.");
            until Customer.Next() = 0;
        exit(Result);
    end;
}
