codeunit 50100 "Payment Run Scheduler"
{
    procedure NthWeekdayOfMonth(Year: Integer; Month: Integer; WeekdayNumber: Integer; Occurrence: Integer): Date
    begin
        // TODO: return the date of the Occurrence-th WeekdayNumber (1 = Monday .. 7 = Sunday)
        // in the given month. Note the error rule when the fifth occurrence does not exist.
    end;

    procedure LastWeekdayOfMonth(Year: Integer; Month: Integer; WeekdayNumber: Integer): Date
    begin
        // TODO: return the date of the last WeekdayNumber in the given month — the fifth
        // occurrence when the month has five, otherwise the fourth. February's length
        // depends on the year.
    end;

    procedure FirstWorkdayOnOrAfter(StartingDate: Date): Date
    begin
        // TODO: return StartingDate itself when it is a Monday-to-Friday workday, otherwise
        // the first workday after it — possibly in a later month or year.
    end;

    procedure PaymentRunDates(StartYear: Integer; StartMonth: Integer; MonthCount: Integer; WeekdayNumber: Integer; Occurrence: Integer): List of [Date]
    begin
        // TODO: return one run date per month for MonthCount months starting at
        // StartMonth/StartYear, in chronological order, continuing past December into the
        // next year. Note the error rule for a month count below 1.
    end;
}
