codeunit 50100 "Period Helper"
{
    var
        WeekKeyLbl: Label '%1-W%2', Locked = true, Comment = '%1 = ISO week-numbering year, %2 = two-digit ISO week number';

    procedure IsoWeekKey(TheDate: Date): Text
    begin
        // TODO: this is right for most of the year and wrong at the year boundary —
        // the key needs the ISO week-numbering year and a two-digit week number.
        exit(StrSubstNo(WeekKeyLbl, Date2DMY(TheDate, 3), Date2DWY(TheDate, 2)));
    end;

    procedure WeekMonday(TheDate: Date): Date
    begin
        // TODO: return the Monday that starts the date's week.
    end;

    procedure EndOfMonth(TheDate: Date): Date
    begin
        // TODO: return the last day of the date's month.
    end;

    procedure DaysInMonth(TheDate: Date): Integer
    begin
        // TODO: return how many days the date's month has.
    end;

    procedure IsLeapYear(Year: Integer): Boolean
    begin
        // TODO: return whether the year is a leap year under the Gregorian rules.
    end;

    procedure QuarterOf(TheDate: Date): Integer
    begin
        // TODO: return the calendar quarter, 1 to 4.
    end;
}
