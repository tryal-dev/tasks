codeunit 50100 "Checkout Pricing"
{
    var
        UnitPrices: Dictionary of [Code[20], Decimal];
        ScannedQuantities: Dictionary of [Code[20], Integer];

    procedure SetUnitPrice(ItemCode: Code[20]; UnitPrice: Decimal)
    begin
        UnitPrices.Set(ItemCode, UnitPrice);
    end;

    procedure SetMultibuyOffer(ItemCode: Code[20]; OfferQuantity: Integer; OfferPrice: Decimal)
    begin
        // TODO: remember the offer so Total can charge every complete group
        // of OfferQuantity units at OfferPrice, leftovers at the unit price.
    end;

    procedure SetBulkPrice(ItemCode: Code[20]; MinimumQuantity: Integer; DiscountedUnitPrice: Decimal)
    begin
        // TODO: remember the bulk break so Total can reprice every unit —
        // including the first — once the quantity reaches MinimumQuantity.
    end;

    procedure Scan(ItemCode: Code[20])
    begin
        // TODO: scanning an item with no configured unit price must raise an
        // error containing the item code and the text 'no price'.
        if ScannedQuantities.ContainsKey(ItemCode) then
            ScannedQuantities.Set(ItemCode, ScannedQuantities.Get(ItemCode) + 1)
        else
            ScannedQuantities.Set(ItemCode, 1);
    end;

    procedure Total() Basket: Decimal
    var
        ItemCode: Code[20];
    begin
        // TODO: deals — this first firmware only knows plain unit prices.
        foreach ItemCode in ScannedQuantities.Keys() do
            Basket += ScannedQuantities.Get(ItemCode) * UnitPrices.Get(ItemCode);
    end;
}
