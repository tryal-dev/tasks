codeunit 50120 "Transfer Flow"
{
    procedure CreateOrder(ItemNo: Code[20]; FromLocation: Code[10]; InTransitLocation: Code[10]; ToLocation: Code[10]; Quantity: Decimal): Code[20]
    begin
        // TODO: create an unposted transfer order (header + one line) and return its number
    end;

    procedure Ship(OrderNo: Code[20]; QtyToShip: Decimal)
    begin
        // TODO: post a transfer shipment of exactly QtyToShip
    end;

    procedure Receive(OrderNo: Code[20]; QtyToReceive: Decimal)
    begin
        // TODO: post a transfer receipt of exactly QtyToReceive; over-receiving must error and post nothing
    end;

    procedure DirectTransfer(ItemNo: Code[20]; FromLocation: Code[10]; ToLocation: Code[10]; Quantity: Decimal)
    begin
        // TODO: move the quantity between the two locations in a single step
    end;

    procedure OnHand(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    begin
        // TODO: report the item's net posted quantity at the location
    end;
}
