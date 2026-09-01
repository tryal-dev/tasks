codeunit 50100 "Record Note Manager"
{
    procedure AddNote(Customer: Record Customer; NoteText: Text): BigInteger
    begin
        // TODO: insert a "Record Link" note attached to the customer and return its "Link ID"
    end;

    procedure ReadNote(LinkID: BigInteger): Text
    begin
        // TODO: return the decoded note text, or an empty text when the link does not exist
    end;

    procedure CountNotes(Customer: Record Customer): Integer
    begin
        // TODO: count only the customer's links of type Note
    end;

    procedure CopyLinks(FromCustomer: Record Customer; ToCustomer: Record Customer)
    begin
        // TODO: give the target customer its own copies of every link of the source
    end;

    procedure DeleteDanglingLinks()
    begin
        // TODO: delete links whose record no longer exists (current company or empty Company only)
    end;
}
