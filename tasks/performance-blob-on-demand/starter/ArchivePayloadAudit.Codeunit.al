codeunit 50101 "Archive Payload Audit"
{
    procedure TotalPayloadBytes(var ArchivedDocument: Record "Archived Document"; DepartmentCode: Code[20]): Integer
    var
        TotalBytes: Integer;
    begin
        // TODO: two things are wrong with this pass. Documents that carry a
        // Recorded Size get measured instead of trusted, and every payload in
        // the archive is hauled across the wire whether it was needed or not.
        ArchivedDocument.SetAutoCalcFields(Content);
        if ArchivedDocument.FindSet() then
            repeat
                if ArchivedDocument."Department Code" = DepartmentCode then
                    TotalBytes += ArchivedDocument.Content.Length;
            until ArchivedDocument.Next() = 0;
        exit(TotalBytes);
    end;
}
