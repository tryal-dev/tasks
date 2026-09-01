codeunit 50100 "Pick Validator"
{
    procedure ValidatePick(ItemCode: Code[20]; RequestedQty: Integer; AvailableQty: Integer)
    begin
        // TODO: the guard rule below is right, but this one-string error is a
        // dead end — no detail for troubleshooters, no data for telemetry,
        // and an error-collection scope cannot gather it.
        if RequestedQty > AvailableQty then
            Error('Cannot pick %1 units of item %2.', RequestedQty, ItemCode);
    end;
}
