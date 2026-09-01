codeunit 50100 "DateTime Change Detector"
{
    procedure IsSameMoment(First: DateTime; Second: DateTime): Boolean
    begin
        // TODO: a strict = randomly fails once one side has been through
        // the database — SQL rounding can move a stored value by a few ms.
        exit(First = Second);
    end;

    procedure ShouldResync(CurrentModifiedAt: DateTime; LastSyncedModifiedAt: DateTime): Boolean
    begin
        // TODO: same trap — <> re-emits records whose timestamp only
        // drifted in storage, and a never-synced record needs its own rule.
        exit(CurrentModifiedAt <> LastSyncedModifiedAt);
    end;
}
