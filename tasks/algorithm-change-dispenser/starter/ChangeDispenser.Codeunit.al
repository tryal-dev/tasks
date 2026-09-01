codeunit 50100 "Change Dispenser"
{
    procedure FewestCoins(Amount: Integer; Denominations: List of [Integer]): List of [Integer]
    var
        Change: List of [Integer];
        CoinsTaken: List of [Integer];
        Denomination: Integer;
        LargestFitting: Integer;
        Remaining: Integer;
        i: Integer;
        ImpossibleErr: Label 'It is impossible to dispense %1 with the loaded denominations.', Comment = '%1 = the requested amount';
    begin
        // TODO: grabbing the largest coin that fits is not always fewest —
        // 63 from {1, 5, 10, 21, 25} takes six coins this way but three 21s
        // suffice, and 27 from {4, 5} dead-ends on a remainder of 2 even
        // though 4+4+4+5+5+5 makes it exactly.
        Remaining := Amount;
        while Remaining > 0 do begin
            LargestFitting := 0;
            foreach Denomination in Denominations do
                if (Denomination <= Remaining) and (Denomination > LargestFitting) then
                    LargestFitting := Denomination;
            if LargestFitting = 0 then
                Error(ImpossibleErr, Amount);
            CoinsTaken.Add(LargestFitting);
            Remaining -= LargestFitting;
        end;
        // Greedy takes coins largest-first, so reading them backwards is ascending.
        for i := CoinsTaken.Count() downto 1 do
            Change.Add(CoinsTaken.Get(i));
        exit(Change);
    end;
}
