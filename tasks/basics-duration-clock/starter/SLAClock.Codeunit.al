codeunit 50100 "SLA Clock"
{
    procedure Elapsed(StartDT: DateTime; EndDT: DateTime): Text
    begin
        // TODO: this prints "1 day 2 hours 5 minutes 9 seconds", not 26:05:09 —
        // split the millisecond count into hours, minutes and seconds yourself.
        exit(Format(EndDT - StartDT));
    end;

    procedure Deadline(ReportedAt: DateTime; SlaHours: Integer): DateTime
    begin
        // TODO: move ReportedAt forward by SlaHours hours.
    end;

    procedure RemainingText(DeadlineAt: DateTime; AsOf: DateTime): Text
    begin
        // TODO: '2h 05m' before the deadline, 'overdue by 1h 10m' after it.
    end;

    procedure BillableHours(StartDT: DateTime; EndDT: DateTime): Decimal
    begin
        // TODO: decimal hours rounded up to the next quarter hour.
    end;
}
