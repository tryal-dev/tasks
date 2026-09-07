codeunit 50100 "Release Checklist"
{
    var
        ShipToCodeMissingErr: Label 'Ship-to code missing';
        NotReleasedErr: Label 'Document is not released';
        ShipmentDateInPastErr: Label 'Shipment date is in the past';

    procedure CheckReadyToShip(var SalesHeader: Record "Sales Header")
    begin
        // TODO: keep the three checks and their order, but let the platform word each refusal
        // (field caption, table caption and primary key included) instead of these hand-written texts.
        if SalesHeader."Ship-to Code" = '' then
            Error(ShipToCodeMissingErr);
        if SalesHeader.Status <> SalesHeader.Status::Released then
            Error(NotReleasedErr);
        if SalesHeader."Shipment Date" < WorkDate() then
            Error(ShipmentDateInPastErr);
    end;
}
