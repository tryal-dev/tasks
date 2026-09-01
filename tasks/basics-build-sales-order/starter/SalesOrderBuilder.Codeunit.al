codeunit 50100 "Sales Order Builder"
{
    procedure CreateOrder(CustomerNo: Code[20]): Code[20]
    begin
        // TODO: create and store a sales order for the customer, filled in the way
        // the Sales Order page fills it in, and return its "No.".
    end;

    procedure AddLine(OrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal): Integer
    begin
        // TODO: add an item line to the order and return its "Line No.".
    end;

    procedure AddNegotiatedLine(OrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal; LineDiscountPct: Decimal): Integer
    begin
        // TODO: same as AddLine, but with the negotiated price and discount on the line.
    end;
}
