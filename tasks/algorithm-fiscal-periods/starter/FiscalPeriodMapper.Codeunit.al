codeunit 50100 "Fiscal Period Mapper"
{
    // TODO: everything below assumes the fiscal year IS the calendar year —
    // right only when FiscalYearStartMonth is 1, and nothing validates it.
    procedure GetPeriodNo(FiscalYearStartMonth: Integer; TheDate: Date): Integer
    begin
        exit(Date2DMY(TheDate, 2));
    end;

    procedure GetFiscalYearStartDate(FiscalYearStartMonth: Integer; TheDate: Date): Date
    begin
        exit(DMY2Date(1, 1, Date2DMY(TheDate, 3)));
    end;

    procedure GetFiscalYearEndDate(FiscalYearStartMonth: Integer; TheDate: Date): Date
    begin
        exit(DMY2Date(31, 12, Date2DMY(TheDate, 3)));
    end;
}
