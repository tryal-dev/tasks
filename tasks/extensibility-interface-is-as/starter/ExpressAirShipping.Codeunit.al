// TODO: Express Air tracks parcels — this codeunit must implement ITrackable as well.
codeunit 50102 "Express Air Shipping" implements "IShipping Carrier"
{
    procedure Quote(Weight: Decimal): Decimal
    begin
        exit(Round(12 + 2.4 * Weight, 0.01));
    end;
}
