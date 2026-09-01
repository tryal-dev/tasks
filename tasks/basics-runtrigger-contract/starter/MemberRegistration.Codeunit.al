codeunit 50101 "Member Registration"
{
    procedure RegisterMember(var Member: Record "Loyalty Member")
    begin
        // TODO: insert so that the OnInsert trigger runs.
    end;

    procedure MigrateMember(var Member: Record "Loyalty Member")
    begin
        // TODO: insert so that the OnInsert trigger does NOT run.
    end;

    procedure UpdateMember(var Member: Record "Loyalty Member")
    begin
        // TODO: modify so that the OnModify trigger runs.
    end;

    procedure PatchMigratedMember(var Member: Record "Loyalty Member")
    begin
        // TODO: modify so that the OnModify trigger does NOT run.
    end;
}
