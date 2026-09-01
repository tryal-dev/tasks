codeunit 50100 "Ship Then Invoice"
{
    procedure PostShipment(OrderNo: Code[20]): Code[20]
    begin
        // TODO: post sales order OrderNo shipping only, and return the "No." of the shipment
        // this call posted. Return '' when no such sales order exists.
    end;

    procedure PostInvoice(OrderNo: Code[20]): Code[20]
    begin
        // TODO: post sales order OrderNo invoicing only, and return the "No." of the invoice
        // this call posted. Return '' when no such sales order exists.
    end;
}
