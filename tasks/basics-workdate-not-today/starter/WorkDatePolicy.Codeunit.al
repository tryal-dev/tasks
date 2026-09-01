codeunit 50100 "Work Date Policy"
{
    procedure DefaultPostingDate(): Date
    begin
        // TODO: Today is the calendar clock — a user who moved the work
        // date on My Settings still gets today's date here.
        exit(Today());
    end;

    procedure IsBackdated(PostingDate: Date): Boolean
    begin
        // TODO: same clock — and a blank posting date currently counts as
        // backdated.
        exit(PostingDate < Today());
    end;

    procedure DaysOverdue(DueDate: Date): Integer
    begin
        // TODO: same clock — and a blank or future due date must give 0,
        // never a negative or absurd number.
        exit(Today() - DueDate);
    end;
}
