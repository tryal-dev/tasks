codeunit 50100 "Customer Balance Window"
{
    procedure BalanceAsOf(CustomerNo: Code[20]; AsOfDate: Date): Decimal
    var
        Customer: Record Customer;
    begin
        // TODO: entries posted after AsOfDate must not count — this is
        // the all-time balance no matter what date is passed in.
        Customer.Get(CustomerNo);
        Customer.CalcFields("Balance (LCY)");
        exit(Customer."Balance (LCY)");
    end;

    procedure BalanceChangeBetween(CustomerNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        Customer: Record Customer;
    begin
        // TODO: only entries posted from FromDate through ToDate may count —
        // this ignores the window completely.
        Customer.Get(CustomerNo);
        Customer.CalcFields("Balance (LCY)");
        exit(Customer."Balance (LCY)");
    end;
}
