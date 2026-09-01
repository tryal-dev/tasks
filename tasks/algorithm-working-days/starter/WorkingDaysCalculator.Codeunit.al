codeunit 50100 "Working Days Calculator"
{
    procedure WorkingDaysBetween(FromDate: Date; ToDate: Date; WeekendDays: List of [Integer]; Holidays: List of [Date]): Integer
    begin
        // TODO: count the working days from FromDate to ToDate, both endpoints included.
        // A working day is neither a weekend day (weekday number in WeekendDays,
        // 1 = Monday .. 7 = Sunday) nor a holiday. Note the error rule for a
        // range whose end is earlier than its start.
    end;

    procedure PromiseShipmentDate(OrderDate: Date; LeadTimeWorkingDays: Integer; WeekendDays: List of [Integer]; Holidays: List of [Date]): Date
    begin
        // TODO: return the date reached by counting LeadTimeWorkingDays working
        // days strictly after OrderDate. Note the error rule for a lead time
        // below 1.
    end;
}
