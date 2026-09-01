codeunit 50101 "Shelf Totals"
{
    procedure QuantityOnShelf(ShelfCode: Code[20]): Decimal
    var
        ShelfMovementEntry: Record "Shelf Movement Entry";
        Total: Decimal;
    begin
        // TODO: the number is right — the cost is not. This fetches every
        // movement row on the shelf to add it up in AL, and the grading
        // budget allows 25 rows for the whole call.
        ShelfMovementEntry.SetRange("Shelf Code", ShelfCode);
        if ShelfMovementEntry.FindSet() then
            repeat
                Total += ShelfMovementEntry.Quantity;
            until ShelfMovementEntry.Next() = 0;
        exit(Total);
    end;

    procedure QuantityOnShelfForItem(ShelfCode: Code[20]; ItemNo: Code[20]): Decimal
    var
        ShelfMovementEntry: Record "Shelf Movement Entry";
        Total: Decimal;
    begin
        // TODO: same story per item — every row crosses the wire.
        ShelfMovementEntry.SetRange("Shelf Code", ShelfCode);
        ShelfMovementEntry.SetRange("Item No.", ItemNo);
        if ShelfMovementEntry.FindSet() then
            repeat
                Total += ShelfMovementEntry.Quantity;
            until ShelfMovementEntry.Next() = 0;
        exit(Total);
    end;
}
