codeunit 50100 "Downtime Analyzer"
{
    procedure TotalDowntimeMinutes(LogLines: List of [Text]; WorkCenterNo: Code[20]): Integer
    begin
        // TODO: sum the minutes the given work center was down across all its stops.
        exit(0);
    end;

    procedure MostFrequentDownMinute(LogLines: List of [Text]; WorkCenterNo: Code[20]): Integer
    begin
        // TODO: return the minute of day (0..1439) most often covered by the given
        // work center's stops, or -1 when it has no downtime at all.
        exit(-1);
    end;
}
