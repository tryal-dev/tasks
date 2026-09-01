codeunit 50100 "Depot Hours"
{
    procedure IsOpen(At: Time; OpensAt: Time; ClosesAt: Time): Boolean
    begin
        // TODO: this is the daytime-shop check — it says 01:00 is outside 22:00–06:00
        // and never refuses 0T.
        exit((At >= OpensAt) and (At < ClosesAt));
    end;

    procedure ShiftMinutes(StartTime: Time; EndTime: Time): Integer
    begin
        // TODO: same bug — 22:00 to 06:00 comes out as minus sixteen hours.
        exit((EndTime - StartTime) div 60000);
    end;

    procedure MinutesUntilClose(At: Time; OpensAt: Time; ClosesAt: Time): Integer
    begin
        // TODO: 0 when closed, otherwise whole minutes until the clock next reads ClosesAt.
    end;
}
