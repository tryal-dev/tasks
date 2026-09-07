codeunit 50101 "Customer Notes"
{
    procedure AddNote(CustomerNo: Code[20]; NoteText: Text[250])
    begin
        // TODO: insert one "Customer Note" row - validate the number against the relation,
        // keep a copy of it in "Legacy Customer No.", store the text.
    end;

    procedure NotesFor(CustomerNo: Code[20]): Integer
    begin
        // TODO: count the notes whose "Customer No." is CustomerNo.
    end;
}
