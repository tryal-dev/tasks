codeunit 50101 "Ledger Entry Reversal"
{
    procedure ReverseEntry(EntryNo: Integer): Integer
    begin
        // TODO: refuse the entries that must not be reversed, then write the
        // offsetting entry and cross-reference both sides.
    end;

    procedure ReverseDocument(DocumentNo: Code[20]): Integer
    begin
        // TODO: reverse every entry of the document that is not itself a
        // reversal — all of them, or none at all.
    end;
}
