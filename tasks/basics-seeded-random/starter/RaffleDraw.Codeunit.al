codeunit 50100 "Raffle Draw"
{
    procedure DrawWinners(Seed: Integer; Entrants: List of [Code[20]]; Count: Integer): List of [Code[20]]
    begin
        // TODO: seed the generator once, then draw Count winners from a working
        // copy of Entrants, one Random(pool size) position at a time.
    end;
}
