codeunit 50101 "Ground Post Shipping" implements "IShipping Carrier"
{
    procedure Quote(Weight: Decimal): Decimal
    begin
        exit(Round(3.5 + 0.8 * Weight, 0.01));
    end;
}
