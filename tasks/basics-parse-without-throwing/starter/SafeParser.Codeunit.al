codeunit 50100 "Safe Parser"
{
    procedure TryParseReference(Ref: Text; var Prefix: Text; var Year: Integer; var Seq: Integer): Boolean
    var
        Parts: List of [Text];
    begin
        // TODO: every line below turns bad input into a runtime error —
        // a missing segment, a decimal, an oversized number all kill the batch.
        Parts := Ref.Split('-');
        Prefix := Parts.Get(1);
        Evaluate(Year, Parts.Get(2));
        Evaluate(Seq, Parts.Get(3));
        exit(true);
    end;

    procedure TryParseLead(Input: Text; var Lead: Duration): Boolean
    begin
        // TODO: same trap — the Boolean that Evaluate returns is thrown away.
        Evaluate(Lead, Input);
        exit(true);
    end;
}
