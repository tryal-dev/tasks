codeunit 50100 "Zip Archive Manager"
{
    procedure BuildArchive(Documents: Dictionary of [Text, Text]; var ArchiveBlob: Codeunit "Temp Blob")
    begin
        // TODO: write a zip archive into ArchiveBlob — one entry per document, key = full path, value = UTF-8 content.
    end;

    procedure ListEntries(var ArchiveBlob: Codeunit "Temp Blob"): List of [Text]
    begin
        // TODO: return the full entry paths of the archive, in archive order.
    end;

    procedure ExtractDocument(var ArchiveBlob: Codeunit "Temp Blob"; EntryPath: Text; var DocumentBlob: Codeunit "Temp Blob"): Integer
    begin
        // TODO: write the entry's uncompressed bytes into DocumentBlob and return the exact byte count.
    end;

    procedure GetDocumentText(var PayloadBlob: Codeunit "Temp Blob"): Text
    begin
        // TODO: detect zip / gzip / plain text from the payload bytes and return the document text.
    end;
}
