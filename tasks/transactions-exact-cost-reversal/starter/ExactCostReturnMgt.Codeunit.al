codeunit 50100 "Exact Cost Return Mgt."
{
    procedure FindSaleEntryNo(PostedShipmentNo: Code[20]): Integer
    begin
        // TODO: return the "Entry No." of the item ledger entry the posted sales shipment created
        exit(0);
    end;

    procedure PostExactCostReturn(PostedShipmentNo: Code[20]; ReturnQty: Decimal): Code[20]
    begin
        // TODO: reject a return bigger than the shipment, then build and post a sales credit
        // memo that puts the goods back into inventory at the cost they were sold at, and
        // return the posted credit memo no.
        exit('');
    end;
}
