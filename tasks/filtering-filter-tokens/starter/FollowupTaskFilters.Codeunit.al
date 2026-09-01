codeunit 50101 "Follow-up Task Filters"
{
    procedure ApplyDueDateFilter(var FollowupTask: Record "Follow-up Task"; DateInput: Text)
    begin
        // TODO: 'today' reaches SetFilter as literal text — not a date the filter can parse.
        FollowupTask.SetFilter("Due Date", DateInput);
    end;

    procedure ApplyAssignedToFilter(var FollowupTask: Record "Follow-up Task"; AssignedToInput: Text)
    begin
        // TODO: 'me' is filtered as the literal word me, which matches nobody.
        FollowupTask.SetFilter("Assigned To", AssignedToInput);
    end;

    procedure ApplyCreatedAtFilter(var FollowupTask: Record "Follow-up Task"; DateTimeInput: Text)
    begin
        // TODO: same trap — 'today' is not a DateTime the filter can parse.
        FollowupTask.SetFilter("Created At", DateTimeInput);
    end;
}
