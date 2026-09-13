codeunit 50100 "Dimension Set Totals"
{
    procedure NetChangeByDimensionValue(GLAccountNo: Code[20]; DimensionCode: Code[20]): Dictionary of [Code[20], Decimal]
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        GLEntry: Record "G/L Entry";
        Totals: Dictionary of [Code[20], Decimal];
    begin
        // TODO: the numbers below are right — the cost is not. One round trip
        // for the entries, then a Get into Dimension Set Entry per entry: even
        // with the server deduplicating identical reads, dozens of distinct sets
        // cost dozens of statements and the grading budget allows 15.
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        if GLEntry.FindSet() then
            repeat
                if DimensionSetEntry.Get(GLEntry."Dimension Set ID", DimensionCode) then
                    if Totals.ContainsKey(DimensionSetEntry."Dimension Value Code") then
                        Totals.Set(DimensionSetEntry."Dimension Value Code", Totals.Get(DimensionSetEntry."Dimension Value Code") + GLEntry.Amount)
                    else
                        Totals.Add(DimensionSetEntry."Dimension Value Code", GLEntry.Amount);
            until GLEntry.Next() = 0;
        exit(Totals);
    end;
}
