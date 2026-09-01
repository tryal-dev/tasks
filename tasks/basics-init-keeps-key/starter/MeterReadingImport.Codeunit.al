codeunit 50102 "Meter Reading Import"
{
    var
        SuspectReadingLbl: Label 'Suspect reading';

    procedure Import(Values: List of [Decimal]; ReadOn: Date)
    var
        MeterReading: Record "Meter Reading";
        Value: Decimal;
        NextEntryNo: Integer;
    begin
        // TODO: ticket two — the second upload of the day dies with "already exists".
        NextEntryNo := 1;

        foreach Value in Values do begin
            // TODO: ticket one — a remark set on one row shows up on the rows after it.
            MeterReading."Entry No." := NextEntryNo;
            MeterReading."Reading Value" := Value;
            MeterReading."Read On" := ReadOn;
            if Value <= 0 then
                MeterReading.Remark := SuspectReadingLbl;
            MeterReading.Insert();
            NextEntryNo += 1;
        end;
    end;
}
