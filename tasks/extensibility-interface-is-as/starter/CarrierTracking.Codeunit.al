codeunit 50103 "Carrier Tracking"
{
    procedure IsTrackable(Carrier: Enum Carrier): Boolean
    begin
        // TODO: true exactly when the codeunit behind this carrier implements ITrackable.
    end;

    procedure TrackingLink(Carrier: Enum Carrier; TrackingNo: Text): Text
    begin
        // TODO: the carrier's TrackingUrl when it tracks parcels, otherwise an empty text.
    end;
}
