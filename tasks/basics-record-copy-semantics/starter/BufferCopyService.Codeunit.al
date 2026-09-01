codeunit 50100 "Buffer Copy Service"
{
    procedure TakeSnapshot(var Source: Record "Name/Value Buffer" temporary; var Snapshot: Record "Name/Value Buffer" temporary)
    begin
        // TODO: this "snapshot" is not frozen — ShareTable makes Snapshot a
        // second handle on the SAME data set, following every later change.
        Snapshot.Copy(Source, true);
    end;

    procedure AttachSharedView(var Source: Record "Name/Value Buffer" temporary; var SharedView: Record "Name/Value Buffer" temporary)
    begin
        SharedView.Copy(Source, true);
    end;
}
