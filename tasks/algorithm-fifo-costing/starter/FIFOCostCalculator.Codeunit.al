codeunit 50100 "FIFO Cost Calculator"
{
    procedure ComputeShipmentCosts(Quantities: List of [Decimal]; UnitCosts: List of [Decimal]): List of [Decimal]
    var
        Costs: List of [Decimal];
        Qty: Decimal;
        ReceivedQty: Decimal;
        ReceivedValue: Decimal;
        i: Integer;
    begin
        // TODO: this is the shortcut from the support ticket — it prices every shipment
        // at the running average cost of everything received so far, never tracks the
        // layers, and never checks what is actually on hand. Replace it with real FIFO.
        for i := 1 to Quantities.Count() do begin
            Qty := Quantities.Get(i);
            if Qty > 0 then begin
                ReceivedQty += Qty;
                ReceivedValue += Qty * UnitCosts.Get(i);
            end else
                Costs.Add(Round(-Qty * ReceivedValue / ReceivedQty, 0.01));
        end;
        exit(Costs);
    end;
}
