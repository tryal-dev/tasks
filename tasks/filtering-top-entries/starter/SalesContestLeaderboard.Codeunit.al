codeunit 50101 "Sales Contest Leaderboard"
{
    procedure GetTopFiveEntryNos(): List of [Integer]
    var
        SalesContestEntry: Record "Sales Contest Entry";
        TopEntryNos: List of [Integer];
    begin
        // TODO: this walks the table in "Entry No." order, so the tile shows
        // the five OLDEST deals — rank by Amount instead, per the task rules.
        if SalesContestEntry.FindSet() then
            repeat
                TopEntryNos.Add(SalesContestEntry."Entry No.");
            until (TopEntryNos.Count() = 5) or (SalesContestEntry.Next() = 0);
        exit(TopEntryNos);
    end;
}
