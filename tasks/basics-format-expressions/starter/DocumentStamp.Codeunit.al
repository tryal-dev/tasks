// TODO: every face below still uses the one-argument Format, whose output
// follows the session's regional settings (2/3/2026 here, 03-02-2026 in
// Copenhagen). Compose each face with Format(Value, 0, FormatString) instead.
codeunit 50100 "Document Stamp"
{
    procedure IsoDate(Value: Date): Text
    begin
        exit(Format(Value));
    end;

    procedure PrintedDate(Value: Date): Text
    begin
        exit(Format(Value));
    end;

    procedure WeekdayName(Value: Date): Text
    begin
        exit(Format(Value));
    end;

    procedure IsoWeekKey(Value: Date): Text
    begin
        exit(Format(Value));
    end;

    procedure ClockTime(Value: Time): Text
    begin
        exit(Format(Value));
    end;

    procedure FileStamp(Value: Date): Text
    begin
        exit(Format(Value));
    end;
}
