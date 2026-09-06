codeunit 50100 "Line Totaler"
{
    var
        RunningTotal: Decimal;

    procedure Total(Amounts: List of [Decimal]): Decimal
    var
        Amount: Decimal;
    begin
        // TODO: RunningTotal lives as long as this codeunit instance, so a second
        // call on the same instance starts from the first call's total.
        foreach Amount in Amounts do
            RunningTotal += Amount;
        exit(RunningTotal);
    end;
}
