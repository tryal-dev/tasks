codeunit 50100 "Penny Allocator"
{
    procedure Allocate(TotalAmount: Decimal; Weights: List of [Decimal]): List of [Decimal]
    var
        Amounts: List of [Decimal];
        Weight: Decimal;
        WeightSum: Decimal;
    begin
        foreach Weight in Weights do
            WeightSum += Weight;
        // TODO: rounding every line on its own invents or loses pennies —
        // these amounts do not always sum back to TotalAmount.
        foreach Weight in Weights do
            Amounts.Add(Round(TotalAmount * Weight / WeightSum, 0.01));
        exit(Amounts);
    end;
}
