codeunit 50902 "Test Barge Carrier" implements "IShipping Carrier"
{
    procedure Quote(Weight: Decimal): Decimal
    begin
        exit(Round(1.5 * Weight, 0.01));
    end;
}
