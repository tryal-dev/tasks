codeunit 50100 "Freight Charge Calculator"
{
    procedure CalculateFreight(Amount: Decimal): Decimal
    begin
        // TODO: raise OnBeforeCalculateFreight first and let a subscriber
        // take over; only when nothing handled it, apply the default charge.
        exit(0);
    end;

    // The publisher is declared for you — the grading tests subscribe to this exact
    // signature. Keep it as is; CalculateFreight has to raise it.
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateFreight(Amount: Decimal; var Freight: Decimal; var IsHandled: Boolean)
    begin
    end;
}
