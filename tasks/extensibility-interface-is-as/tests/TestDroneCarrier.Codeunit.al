codeunit 50901 "Test Drone Carrier" implements "IShipping Carrier", ITrackable
{
    procedure Quote(Weight: Decimal): Decimal
    begin
        exit(Round(20 + 3 * Weight, 0.01));
    end;

    procedure TrackingUrl(TrackingNo: Text): Text
    begin
        exit('https://drone.tryal.test/track/' + TrackingNo);
    end;
}
