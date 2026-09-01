codeunit 50100 "Stock By Location"
{
    procedure OnHandByLocation(ItemNo: Code[20]) OnHand: Dictionary of [Code[10], Decimal]
    begin
        // TODO: fill OnHand from the item's ledger entries — one key per
        // location the item has moved through, net quantity as the value.
        exit(OnHand);
    end;
}
