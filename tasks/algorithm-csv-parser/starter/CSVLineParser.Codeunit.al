codeunit 50100 "CSV Line Parser"
{
    procedure ParseLine(Line: Text): List of [Text]
    begin
        // TODO: this is the import's original bug — a comma inside a quoted
        // field splits the field in two, and quotes are never stripped or
        // unescaped.
        exit(Line.Split(','));
    end;
}
