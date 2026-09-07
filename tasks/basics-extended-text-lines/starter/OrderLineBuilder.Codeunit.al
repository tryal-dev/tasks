codeunit 50100 "Order Line Builder"
{
    procedure AddItemLineWithText(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal): Integer
    begin
        // TODO: store an item line for ItemNo and Quantity on the order, let codeunit
        // "Transfer Extended Text" put the item's extended text under it, and return
        // the item line's "Line No.".
    end;

    procedure RemoveItemLine(var SalesHeader: Record "Sales Header"; LineNo: Integer)
    begin
        // TODO: delete item line LineNo together with the text lines attached to it.
    end;
}
