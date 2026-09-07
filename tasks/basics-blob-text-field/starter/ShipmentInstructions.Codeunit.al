codeunit 50101 "Shipment Instructions"
{
    procedure SetInstructions(NoteNo: Code[20]; Instructions: Text)
    begin
        // TODO: store Instructions in the note's "Delivery Instructions" Blob and save the record.
    end;

    procedure GetInstructions(NoteNo: Code[20]): Text
    begin
        // TODO: return the text stored in the note's "Delivery Instructions" Blob, character for character.
    end;

    procedure HasInstructions(NoteNo: Code[20]): Boolean
    begin
        // TODO: return whether the note's "Delivery Instructions" Blob holds a value.
    end;
}
