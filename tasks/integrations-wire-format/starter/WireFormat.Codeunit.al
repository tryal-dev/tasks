codeunit 50100 "Wire Format"
{
    procedure ToWireDecimal(Value: Decimal): Text
    begin
        // TODO: this follows the session's regional settings — on many
        // servers it writes group separators or a comma decimal point.
        exit(Format(Value));
    end;

    procedure ToWireDate(Value: Date): Text
    begin
        // TODO: same trap — the shape of this text changes per server.
        exit(Format(Value));
    end;

    procedure FromWireDecimal(WireText: Text; var Value: Decimal): Boolean
    begin
        // TODO: this parses by regional settings too — it happily accepts
        // locale text like 1,5 that is not in wire format at all.
        exit(Evaluate(Value, WireText));
    end;

    procedure FromWireDate(WireText: Text; var Value: Date): Boolean
    begin
        // TODO: same trap in the date direction.
        exit(Evaluate(Value, WireText));
    end;
}
