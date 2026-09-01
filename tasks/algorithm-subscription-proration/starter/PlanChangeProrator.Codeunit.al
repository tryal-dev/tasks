codeunit 50100 "Plan Change Prorator"
{
    procedure ProrateChange(PeriodStart: Date; PeriodEnd: Date; ChangeDate: Date; OldPrice: Decimal; NewPrice: Decimal; var CreditAmount: Decimal; var ChargeAmount: Decimal)
    begin
        // TODO: credit the remaining days at the old price and charge them at the
        // new price, prorated over the actual calendar days of the period —
        // remember that both the period and the remaining window include their
        // boundary days, and that February is never 30 days long.
    end;
}
