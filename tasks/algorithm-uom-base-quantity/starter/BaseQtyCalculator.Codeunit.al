codeunit 50100 "Base Qty Calculator"
{
    procedure CalcBaseQty(Qty: Decimal; QtyPerUnitOfMeasure: Decimal; QtyRoundingPrecision: Decimal): Decimal
    begin
        // TODO: the raw product can carry up to ten decimals, and QtyRoundingPrecision
        // is ignored — BC never stores a base quantity this precise.
        exit(Qty * QtyPerUnitOfMeasure);
    end;

    procedure CalcBaseQtyToPost(QtyToPost: Decimal; QtyPostedSoFar: Decimal; QtyPerUnitOfMeasure: Decimal; QtyRoundingPrecision: Decimal): Decimal
    begin
        // TODO: converting each posting on its own drifts away from the ordered base
        // quantity — the splits must always sum to CalcBaseQty of the total posted.
        exit(QtyToPost * QtyPerUnitOfMeasure);
    end;
}
