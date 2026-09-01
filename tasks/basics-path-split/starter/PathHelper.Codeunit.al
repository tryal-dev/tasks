codeunit 50100 "Path Helper"
{
    procedure FileNameOf(Path: Text): Text
    var
        Parts: List of [Text];
    begin
        Parts := Path.Split('/', '\');
        // TODO: this returns the second-to-last segment, and crashes on a bare
        // file name — AL lists do not start at 0.
        exit(Parts.Get(Parts.Count() - 1));
    end;

    procedure ExtensionOf(Path: Text): Text
    var
        FileName: Text;
        DotPos: Integer;
    begin
        FileName := FileNameOf(Path);
        DotPos := FileName.LastIndexOf('.');
        // TODO: a file name without a dot comes back whole instead of empty —
        // LastIndexOf never returns a negative number.
        if DotPos < 0 then
            exit('');
        exit(FileName.Substring(DotPos + 1));
    end;
}
