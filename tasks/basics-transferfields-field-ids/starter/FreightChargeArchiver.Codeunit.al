codeunit 50102 "Freight Charge Archiver"
{
    procedure Archive(EntryNo: Integer; ArchivedOn: Date)
    begin
        // TODO: map the freight charge onto a "Carrier Charge Archive" row
        // field by field, refuse to archive the same charge twice, then flag
        // the freight charge as archived.
    end;
}
