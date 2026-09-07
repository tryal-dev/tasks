codeunit 50100 "LCY Converter"
{
    procedure ToLCY(Amount: Decimal; CurrencyCode: Code[10]; OnDate: Date): Decimal
    begin
        // TODO: convert with the rate in force on OnDate the way posting does,
        // then round the result to the LCY precision.
        exit(Amount);
    end;
}
