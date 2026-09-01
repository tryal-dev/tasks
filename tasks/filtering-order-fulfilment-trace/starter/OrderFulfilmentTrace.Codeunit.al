codeunit 50100 "Order Fulfilment Trace"
{
    procedure ShippedQuantityByDocument(OrderNo: Code[20]; OrderLineNo: Integer; var QtyByDocument: Dictionary of [Code[20], Decimal])
    begin
        // TODO: one entry per posted shipment of this order line — document no. -> quantity shipped on it.
    end;

    procedure InvoicedQuantityByDocument(OrderNo: Code[20]; OrderLineNo: Integer; var QtyByDocument: Dictionary of [Code[20], Decimal])
    begin
        // TODO: one entry per posted invoice against this order line — several lines on one invoice sum up.
    end;

    procedure InvoicedQuantityForShipmentLine(ShipmentNo: Code[20]; ShipmentLineNo: Integer): Decimal
    begin
        // TODO: total quantity invoiced against this one posted shipment line.
    end;

    procedure OutstandingQuantity(OrderNo: Code[20]; OrderLineNo: Integer): Decimal
    begin
        // TODO: the part of the order line's quantity not shipped yet.
    end;
}
