codeunit 50101 "Sync Activity Logger"
{
    procedure Log(var ActivityLog: Record "Sync Activity Log"; MessageText: Text[250]): Integer
    begin
        // TODO: refuse a temporary record with the error from the statement, insert the
        // message with "Entry No." left at 0, and return the number the database assigned.
    end;
}
