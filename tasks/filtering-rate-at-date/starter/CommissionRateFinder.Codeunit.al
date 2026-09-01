codeunit 50101 "Commission Rate Finder"
{
    procedure FindRateAt(SalespersonCode: Code[20]; AtDate: Date; var RatePct: Decimal): Boolean
    var
        CommissionRate: Record "Commission Rate";
    begin
        RatePct := 0;
        // TODO: this only finds a rate whose "Starting Date" is exactly AtDate —
        // a rate that took effect earlier and is still in force is never found.
        CommissionRate.SetRange("Salesperson Code", SalespersonCode);
        CommissionRate.SetRange("Starting Date", AtDate);
        if not CommissionRate.FindFirst() then
            exit(false);
        RatePct := CommissionRate."Rate %";
        exit(true);
    end;

    procedure GetRateAt(SalespersonCode: Code[20]; AtDate: Date): Decimal
    var
        RatePct: Decimal;
    begin
        if FindRateAt(SalespersonCode, AtDate, RatePct) then
            exit(RatePct);
        exit(0);
    end;
}
