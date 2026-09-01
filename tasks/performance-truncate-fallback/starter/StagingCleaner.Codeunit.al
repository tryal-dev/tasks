codeunit 50101 "Staging Cleaner"
{
    procedure ClearStaging(var StagingEntry: Record "Staging Entry"; ResetNumbering: Boolean)
    begin
        // TODO: this is the one-stroke wipe, and it is fast — but it dies with a
        // runtime error wherever the platform does not support it (temporary
        // instances, delete-event subscribers, ...). The rows must still be
        // removed there, without an error.
        StagingEntry.Truncate(ResetNumbering);
    end;
}
