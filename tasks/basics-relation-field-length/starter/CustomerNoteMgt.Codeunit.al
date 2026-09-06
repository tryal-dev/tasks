codeunit 50101 "Customer Note Mgt."
{
    procedure AddNote(CustomerNo: Code[20]; NoteText: Text[250])
    var
        CustomerNote: Record "Customer Note";
    begin
        CustomerNote.Init();
        CustomerNote.Validate("Customer No.", CustomerNo);
        CustomerNote.Note := NoteText;
        CustomerNote.Insert(true);
    end;
}
