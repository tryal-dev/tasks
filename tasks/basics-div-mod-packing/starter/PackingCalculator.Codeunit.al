codeunit 50101 "Packing Calculator"
{
    procedure SplitQuantity(ItemNo: Code[20]; Quantity: Decimal; var Pallets: Integer; var Boxes: Integer; var Loose: Integer)
    var
        Item: Record Item;
        UnitsPerPallet: Integer;
    begin
        Item.Get(ItemNo);
        UnitsPerPallet := Item."Boxes per Pallet" * Item."Units per Box";
        // TODO: `/` yields a Decimal that is rounded on assignment to an Integer,
        // so 7 units in boxes of 2 come out as 4 boxes and a negative remainder.
        // Split in whole numbers instead, and add the checks from rules 3 and 4.
        Pallets := Quantity / UnitsPerPallet;
        Boxes := (Quantity - Pallets * UnitsPerPallet) / Item."Units per Box";
        Loose := Quantity - Pallets * UnitsPerPallet - Boxes * Item."Units per Box";
    end;

    procedure PalletsNeeded(ItemNo: Code[20]; Quantity: Decimal): Integer
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        // TODO: this rounds to the nearest pallet instead of up — one unit reports 0 pallets.
        exit(Quantity / (Item."Boxes per Pallet" * Item."Units per Box"));
    end;
}
