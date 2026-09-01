codeunit 50100 "Item Totals"
{
    procedure TotalsByItem(ItemNos: List of [Text]; Quantities: List of [Decimal]) Totals: Dictionary of [Code[20], Decimal]
    var
        RawTotals: Dictionary of [Text, Decimal];
        RawItemNo: Text;
        i: Integer;
    begin
        // TODO: Text keys are case-sensitive and keep their spaces, so
        // 'abc-1', 'ABC-1' and 'ABC-1 ' become three buckets - and Add
        // raises the moment an item number repeats exactly.
        for i := 1 to ItemNos.Count() do
            RawTotals.Add(ItemNos.Get(i), Quantities.Get(i));

        foreach RawItemNo in RawTotals.Keys() do
            Totals.Add(RawItemNo, RawTotals.Get(RawItemNo));
    end;
}
