codeunit 50100 "Recurrence Planner"
{
    procedure CreateWeekly(StartDate: Date; StartTime: Time; Weekdays: List of [Integer]; EndDate: Date)
    begin
        // TODO: remember this weekly schedule on the instance. Occurrences fall at
        // StartTime on every date from StartDate onward whose weekday number
        // (1 = Monday .. 7 = Sunday) is in Weekdays, up to and including EndDate
        // (0D = no end). A Create call replaces any earlier schedule.
    end;

    procedure CreateMonthlyByDayOfWeek(StartDate: Date; StartTime: Time; Ordinal: Enum "Recurrence Ordinal"; Weekday: Integer; EndDate: Date)
    begin
        // TODO: remember this monthly schedule on the instance. Each month's single
        // candidate is the first/second/third/fourth or last date with that weekday;
        // candidates on or after StartDate are occurrences, up to and including
        // EndDate (0D = no end). A Create call replaces any earlier schedule.
    end;

    procedure CalculateNextOccurrence(LastOccurrence: DateTime): DateTime
    begin
        // TODO: return the earliest occurrence DateTime strictly later than
        // LastOccurrence (0DT asks for the very first one), or 0DT when the
        // schedule has nothing left before EndDate. Note the error rule when no
        // schedule has been created yet, and the same-day case where StartTime
        // is still ahead of LastOccurrence.
    end;

    procedure NextOccurrences(FromDateTime: DateTime; MaxCount: Integer): List of [DateTime]
    begin
        // TODO: return up to MaxCount occurrences strictly later than FromDateTime,
        // ascending, stopping early when the schedule ends. Note the error rule
        // for a MaxCount below 1.
    end;
}
