codeunit 50100 "Sales Order Xml Export"
{
    procedure ExportOrder(OrderNo: Code[20]; ExportStream: OutStream)
    begin
        // TODO: Build the <SalesOrder> document described in the task —
        // root attributes, the Customer/Name element, one Line element per
        // sales line with a No. — and write it, declaration included, to ExportStream.
    end;
}
