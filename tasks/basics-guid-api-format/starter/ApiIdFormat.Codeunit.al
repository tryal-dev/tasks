codeunit 50100 "Api Id Format"
{
    procedure ToApiId(Id: Guid): Text
    begin
        // TODO: a Guid is not text — this is not how "no id" is detected.
        if Id = '' then
            exit('');
        // TODO: this is the braced, uppercase display form — not what the API wants.
        exit(Format(Id));
    end;

    procedure TryParseId(Input: Text; var Id: Guid): Boolean
    begin
        // TODO: as a statement, Evaluate raises on text that is not a GUID — the API contract wants false.
        Evaluate(Id, Input);
        exit(true);
    end;
}
