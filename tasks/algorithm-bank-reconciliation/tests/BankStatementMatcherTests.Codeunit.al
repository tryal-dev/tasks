codeunit 50900 "Bank Stmt. Matcher Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactMatchWithZeroToleranceIsFound()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] A line and an entry with the same amount on the same day match even at tolerance 0
        LineAmounts.Add(1250.00);
        LineDates.Add(20260310D);
        EntryAmounts.Add(1250.00);
        EntryDates.Add(20260310D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 0, UnmatchedEntries);

        Assert.AreEqual(1, Matches.Count(), 'Expected exactly one result for a one-line statement');
        Assert.AreEqual(1, Matches.Get(1), 'Expected the line to match entry 1 — same amount, same date, so tolerance 0 is enough (the boundary is inclusive)');
        Assert.AreEqual(0, UnmatchedEntries.Count(), 'Expected no unmatched entries when the only entry was matched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ToleranceBoundaryMatchesInBothDirections()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] Entries exactly ToleranceDays after and before the line date are still candidates
        LineAmounts.Add(100.00);
        LineDates.Add(20260310D);
        LineAmounts.Add(200.00);
        LineDates.Add(20260310D);
        EntryAmounts.Add(100.00);
        EntryDates.Add(20260313D);
        EntryAmounts.Add(200.00);
        EntryDates.Add(20260307D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 3, UnmatchedEntries);

        Assert.AreEqual(2, Matches.Count(), 'Expected exactly one result per statement line');
        Assert.AreEqual(1, Matches.Get(1), 'Expected line 1 to match entry 1, dated exactly 3 days later — the tolerance boundary is inclusive');
        Assert.AreEqual(2, Matches.Get(2), 'Expected line 2 to match entry 2, dated exactly 3 days earlier — the tolerance works in both directions');
        Assert.AreEqual(0, UnmatchedEntries.Count(), 'Expected no unmatched entries when both entries were matched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneDayBeyondToleranceDoesNotMatch()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] An entry dated ToleranceDays + 1 away is not a candidate
        LineAmounts.Add(100.00);
        LineDates.Add(20260310D);
        EntryAmounts.Add(100.00);
        EntryDates.Add(20260314D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 3, UnmatchedEntries);

        Assert.AreEqual(1, Matches.Count(), 'Expected exactly one result for a one-line statement');
        Assert.AreEqual(0, Matches.Get(1), 'Expected no match: the entry is dated 4 days after the line but the tolerance is 3');
        Assert.AreEqual(1, UnmatchedEntries.Count(), 'Expected the out-of-tolerance entry to be reported as unmatched');
        Assert.AreEqual(1, UnmatchedEntries.Get(1), 'Expected entry 1 in the unmatched list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmountsMustMatchToTheCent()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] A one-cent amount difference disqualifies an entry even on the same date
        LineAmounts.Add(100.00);
        LineDates.Add(20260310D);
        EntryAmounts.Add(100.01);
        EntryDates.Add(20260310D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 5, UnmatchedEntries);

        Assert.AreEqual(1, Matches.Count(), 'Expected exactly one result for a one-line statement');
        Assert.AreEqual(0, Matches.Get(1), 'Expected no match: 100.00 and 100.01 differ by a cent, and amount comparison is exact');
        Assert.AreEqual(1, UnmatchedEntries.Count(), 'Expected the near-miss entry to be reported as unmatched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OppositeSignsNeverMatch()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] An outgoing payment of -250.00 never matches a deposit of 250.00
        LineAmounts.Add(-250.00);
        LineDates.Add(20260310D);
        EntryAmounts.Add(250.00);
        EntryDates.Add(20260310D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 5, UnmatchedEntries);

        Assert.AreEqual(1, Matches.Count(), 'Expected exactly one result for a one-line statement');
        Assert.AreEqual(0, Matches.Get(1), 'Expected no match: -250.00 and 250.00 have opposite signs, and the sign is part of the amount');
        Assert.AreEqual(1, UnmatchedEntries.Count(), 'Expected the opposite-sign entry to be reported as unmatched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnEntryIsConsumedByOneLineOnly()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] Two identical lines compete for one entry; only the first gets it
        LineAmounts.Add(75.25);
        LineDates.Add(20260310D);
        LineAmounts.Add(75.25);
        LineDates.Add(20260310D);
        EntryAmounts.Add(75.25);
        EntryDates.Add(20260310D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 2, UnmatchedEntries);

        Assert.AreEqual(2, Matches.Count(), 'Expected exactly one result per statement line');
        Assert.AreEqual(1, Matches.Get(1), 'Expected line 1 to take entry 1 — lines are processed in statement order');
        Assert.AreEqual(0, Matches.Get(2), 'Expected line 2 to stay unmatched: entry 1 was already consumed by line 1 and matching is one-to-one');
        Assert.AreEqual(0, UnmatchedEntries.Count(), 'Expected no unmatched entries when the only entry was matched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NearestDatedEntryWins()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] With two candidates, the smaller date distance wins even at a higher entry number
        LineAmounts.Add(300.00);
        LineDates.Add(20260310D);
        EntryAmounts.Add(300.00);
        EntryDates.Add(20260313D);
        EntryAmounts.Add(300.00);
        EntryDates.Add(20260309D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 5, UnmatchedEntries);

        Assert.AreEqual(1, Matches.Count(), 'Expected exactly one result for a one-line statement');
        Assert.AreEqual(2, Matches.Get(1), 'Expected entry 2 to win: it is 1 day away while entry 1 is 3 days away — the smallest date distance decides, not the entry order');
        Assert.AreEqual(1, UnmatchedEntries.Count(), 'Expected the losing candidate to be reported as unmatched');
        Assert.AreEqual(1, UnmatchedEntries.Get(1), 'Expected entry 1 in the unmatched list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DistanceTiePrefersEarlierEntryDate()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] Candidates 2 days after and 2 days before tie on distance; the earlier date wins
        LineAmounts.Add(400.00);
        LineDates.Add(20260310D);
        EntryAmounts.Add(400.00);
        EntryDates.Add(20260312D);
        EntryAmounts.Add(400.00);
        EntryDates.Add(20260308D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 5, UnmatchedEntries);

        Assert.AreEqual(1, Matches.Count(), 'Expected exactly one result for a one-line statement');
        Assert.AreEqual(2, Matches.Get(1), 'Expected entry 2 to win the distance tie: both entries are 2 days away, and on a tie the earlier entry date is preferred');
        Assert.AreEqual(1, UnmatchedEntries.Count(), 'Expected the losing candidate to be reported as unmatched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FullTiePrefersLowestEntryNumber()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] Two entries identical in amount and date; the lowest entry number wins
        LineAmounts.Add(500.00);
        LineDates.Add(20260310D);
        EntryAmounts.Add(500.00);
        EntryDates.Add(20260311D);
        EntryAmounts.Add(500.00);
        EntryDates.Add(20260311D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 5, UnmatchedEntries);

        Assert.AreEqual(1, Matches.Count(), 'Expected exactly one result for a one-line statement');
        Assert.AreEqual(1, Matches.Get(1), 'Expected entry 1 to win the full tie: same amount, same date, so the lowest entry number is preferred');
        Assert.AreEqual(1, UnmatchedEntries.Count(), 'Expected the losing twin entry to be reported as unmatched');
        Assert.AreEqual(2, UnmatchedEntries.Get(1), 'Expected entry 2 in the unmatched list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LinesMatchInStatementOrderNotGlobally()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] Line 1 greedily takes the entry line 2 needed; a globally optimal pairing would be wrong
        // Line 1 (Mar 10) can reach entry 1 (Mar 11, 1 day) and entry 2 (Mar 12, 2 days).
        // Line 2 (Mar 9) can only reach entry 1 (2 days; entry 2 is 3 days away, beyond tolerance 2).
        LineAmounts.Add(1200.00);
        LineDates.Add(20260310D);
        LineAmounts.Add(1200.00);
        LineDates.Add(20260309D);
        EntryAmounts.Add(1200.00);
        EntryDates.Add(20260311D);
        EntryAmounts.Add(1200.00);
        EntryDates.Add(20260312D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 2, UnmatchedEntries);

        Assert.AreEqual(2, Matches.Count(), 'Expected exactly one result per statement line');
        Assert.AreEqual(1, Matches.Get(1), 'Expected line 1 to take entry 1, its nearest candidate — each line matches immediately in statement order');
        Assert.AreEqual(0, Matches.Get(2), 'Expected line 2 to stay unmatched: its only candidate was consumed by line 1, and the contract forbids re-planning to maximize matches');
        Assert.AreEqual(1, UnmatchedEntries.Count(), 'Expected exactly one unmatched entry');
        Assert.AreEqual(2, UnmatchedEntries.Get(1), 'Expected entry 2 in the unmatched list — line 1 preferred the nearer entry 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnmatchedEntriesAreClearedAndAscending()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] A mixed statement reports its leftover entries ascending, replacing caller garbage
        LineAmounts.Add(500.00);
        LineDates.Add(20260310D);
        LineAmounts.Add(750.00);
        LineDates.Add(20260310D);
        LineAmounts.Add(20.05);
        LineDates.Add(20260310D);
        EntryAmounts.Add(500.00);
        EntryDates.Add(20260310D);
        EntryAmounts.Add(999.99);
        EntryDates.Add(20260310D);
        EntryAmounts.Add(20.05);
        EntryDates.Add(20260311D);
        EntryAmounts.Add(-35.00);
        EntryDates.Add(20260310D);
        UnmatchedEntries.Add(99);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 2, UnmatchedEntries);

        Assert.AreEqual(3, Matches.Count(), 'Expected exactly one result per statement line');
        Assert.AreEqual(1, Matches.Get(1), 'Expected line 1 (500.00) to match entry 1');
        Assert.AreEqual(0, Matches.Get(2), 'Expected line 2 (750.00) to stay unmatched — no entry carries that amount');
        Assert.AreEqual(3, Matches.Get(3), 'Expected line 3 (20.05) to match entry 3, dated one day later within tolerance');
        Assert.AreEqual(2, UnmatchedEntries.Count(), StrSubstNo('Expected exactly 2 unmatched entries — the list must be cleared of what the caller passed in before filling, got %1 element(s)', UnmatchedEntries.Count()));
        Assert.AreEqual(2, UnmatchedEntries.Get(1), 'Expected entry 2 first in the unmatched list — unmatched entry numbers come back in ascending order');
        Assert.AreEqual(4, UnmatchedEntries.Get(2), 'Expected entry 4 second in the unmatched list — unmatched entry numbers come back in ascending order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoLedgerEntriesLeavesEveryLineUnmatched()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] With no ledger entries at all, every line comes back as 0
        LineAmounts.Add(10.00);
        LineDates.Add(20260310D);
        LineAmounts.Add(-20.00);
        LineDates.Add(20260311D);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 3, UnmatchedEntries);

        Assert.AreEqual(2, Matches.Count(), 'Expected exactly one result per statement line even when there are no entries');
        Assert.AreEqual(0, Matches.Get(1), 'Expected line 1 to be unmatched — there are no ledger entries');
        Assert.AreEqual(0, Matches.Get(2), 'Expected line 2 to be unmatched — there are no ledger entries');
        Assert.AreEqual(0, UnmatchedEntries.Count(), 'Expected an empty unmatched list when there are no entries to report');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyStatementReportsEveryEntryUnmatched()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
    begin
        // [SCENARIO] With no statement lines at all, every entry is reported unmatched and caller garbage is cleared
        EntryAmounts.Add(60.00);
        EntryDates.Add(20260310D);
        EntryAmounts.Add(-15.50);
        EntryDates.Add(20260311D);
        EntryAmounts.Add(320.00);
        EntryDates.Add(20260312D);
        UnmatchedEntries.Add(99);

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 3, UnmatchedEntries);

        Assert.AreEqual(0, Matches.Count(), 'Expected an empty result for an empty statement — one integer per statement line means none at all');
        Assert.AreEqual(3, UnmatchedEntries.Count(), StrSubstNo('Expected all 3 entries reported unmatched — the list must be cleared of what the caller passed in before filling, got %1 element(s)', UnmatchedEntries.Count()));
        Assert.AreEqual(1, UnmatchedEntries.Get(1), 'Expected entry 1 first in the unmatched list — unmatched entry numbers come back in ascending order');
        Assert.AreEqual(2, UnmatchedEntries.Get(2), 'Expected entry 2 second in the unmatched list — unmatched entry numbers come back in ascending order');
        Assert.AreEqual(3, UnmatchedEntries.Get(3), 'Expected entry 3 third in the unmatched list — unmatched entry numbers come back in ascending order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShuffledStatementMatchesEveryEntry()
    var
        Matcher: Codeunit "Bank Statement Matcher";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineAmounts: List of [Decimal];
        LineDates: List of [Date];
        EntryAmounts: List of [Decimal];
        EntryDates: List of [Date];
        UnmatchedEntries: List of [Integer];
        Matches: List of [Integer];
        BaseDate: Date;
        i: Integer;
    begin
        // [SCENARIO] A randomized statement listing the entries in reverse order matches all of them
        // Integer parts 100..600 keep the six amounts distinct, so each line
        // has exactly one candidate by amount and the pairing is forced.
        BaseDate := 20260401D;
        for i := 1 to 6 do begin
            EntryAmounts.Add(100 * i + Any.IntegerInRange(0, 99) / 100);
            EntryDates.Add(BaseDate + Any.IntegerInRange(0, 10));
        end;
        for i := 6 downto 1 do begin
            LineAmounts.Add(EntryAmounts.Get(i));
            LineDates.Add(EntryDates.Get(i) - 3 + Any.IntegerInRange(0, 6));
        end;

        Matches := Matcher.MatchStatement(LineAmounts, LineDates, EntryAmounts, EntryDates, 3, UnmatchedEntries);

        Assert.AreEqual(6, Matches.Count(), 'Expected exactly one result per statement line');
        for i := 1 to 6 do
            Assert.AreEqual(7 - i, Matches.Get(i), StrSubstNo('Expected statement line %1 (amount %2) to match entry %3 — the only entry carrying that amount, dated within tolerance', i, LineAmounts.Get(i), 7 - i));
        Assert.AreEqual(0, UnmatchedEntries.Count(), 'Expected no unmatched entries when every entry has a matching line');
    end;
}
