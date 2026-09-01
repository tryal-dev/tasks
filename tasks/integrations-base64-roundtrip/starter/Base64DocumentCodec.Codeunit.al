codeunit 50100 "Base64 Document Codec"
{
    procedure EncodeDocument(var TempBlob: Codeunit "Temp Blob"): Text
    begin
        // TODO: return the bytes stored in TempBlob as a single-line Base64 string.
    end;

    procedure DecodeDocument(Base64Payload: Text; var TempBlob: Codeunit "Temp Blob")
    begin
        // TODO: write the bytes encoded in Base64Payload into TempBlob.
    end;
}
