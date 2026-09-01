codeunit 50100 "Bank Statement Matcher"
{
    procedure MatchStatement(LineAmounts: List of [Decimal]; LineDates: List of [Date]; EntryAmounts: List of [Decimal]; EntryDates: List of [Date]; ToleranceDays: Integer; var UnmatchedEntries: List of [Integer]): List of [Integer]
    var
        Matches: List of [Integer];
    begin
        // TODO: for each statement line, in order, pick the best available
        // candidate entry (exact amount, dates within ToleranceDays), consume
        // it, and report the never-matched entries in UnmatchedEntries.
        exit(Matches);
    end;
}
