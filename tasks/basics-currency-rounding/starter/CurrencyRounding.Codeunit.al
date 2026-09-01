codeunit 50100 "Currency Rounding"
{
    procedure RoundInvoiceTotal(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    begin
        // TODO: the precision and the direction belong to the currency
        // (or to General Ledger Setup when CurrencyCode is blank), not here.
        exit(Round(Amount, 0.01));
    end;

    procedure RoundUnitPrice(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    begin
        // TODO: round to the nearest multiple of the currency's
        // Unit-Amount Rounding Precision.
        exit(Round(Amount, 0.01));
    end;
}
