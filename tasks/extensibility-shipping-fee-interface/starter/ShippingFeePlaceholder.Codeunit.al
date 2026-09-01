codeunit 50101 "Shipping Fee Placeholder" implements "Shipping Fee Calculator"
{
    var
        NotWiredErr: Label 'No shipping fee calculator is wired to this Shipping Fee Method yet';

    procedure CalculateFee(ParcelWeightKg: Decimal; OrderAmount: Decimal): Decimal
    begin
        Error(NotWiredErr);
    end;
}
