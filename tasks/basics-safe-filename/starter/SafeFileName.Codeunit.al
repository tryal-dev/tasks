codeunit 50100 "Safe File Name"
{
    procedure ToSafeFileName(Proposed: Text; Extension: Text; MaxLength: Integer): Text
    begin
        // TODO: this passes the name through untouched — a / or : in Proposed
        // still reaches the file system. Replace the illegal characters, normalize
        // whitespace, strip the edges, fall back to 'document', then cap the length.
        exit(Proposed + '.' + Extension);
    end;
}
