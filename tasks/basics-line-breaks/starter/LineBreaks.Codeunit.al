codeunit 50100 "Line Breaks"
{
    procedure JoinLines(Lines: List of [Text]): Text
    var
        Body: TextBuilder;
        Index: Integer;
    begin
        // TODO: '\n' is the two characters \ and n in AL - nothing here emits a real line ending.
        for Index := 1 to Lines.Count() do begin
            if Index > 1 then
                Body.Append('\n');
            Body.Append(Lines.Get(Index));
        end;
        exit(Body.ToText());
    end;

    procedure SplitLines(Body: Text): List of [Text]
    begin
        // TODO: same misconception - this splits on a backslash followed by n, never on a line ending.
        exit(Body.Split('\n'));
    end;
}
