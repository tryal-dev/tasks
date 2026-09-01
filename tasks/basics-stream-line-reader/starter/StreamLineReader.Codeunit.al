codeunit 50100 "Stream Line Reader"
{
    procedure ReadLines(LineStream: InStream) Lines: List of [Text]
    begin
        // TODO: split the stream into logical lines per the task statement and fill Lines.
        exit(Lines);
    end;
}
