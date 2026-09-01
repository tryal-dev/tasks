codeunit 50100 "Blanket Call Off"
{
    procedure CallOff(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer; QuantityToCallOff: Decimal): Code[20]
    begin
        // TODO: reject a non-positive quantity and a quantity above what
        // remains, then create the sales order for this one tranche —
        // attached to the blanket line — and return its "No.".
    end;

    procedure RemainingOnBlanket(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer): Decimal
    begin
        // TODO: agreed quantity, minus what has been shipped, minus what is
        // committed on call-off orders that have not been posted yet.
    end;
}
