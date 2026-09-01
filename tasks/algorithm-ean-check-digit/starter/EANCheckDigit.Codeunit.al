codeunit 50100 "EAN Check Digit"
{
    procedure CalculateCheckDigit(FirstTwelve: Text): Integer
    begin
        // TODO: reject anything that is not exactly 12 digits, then apply the 1-3-1-3 weighting.
        exit(0);
    end;

    procedure IsValid(Barcode: Text): Boolean
    begin
        // TODO: exactly 13 digits, and the last one matches the check digit of the first twelve.
        exit(false);
    end;
}
