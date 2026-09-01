codeunit 50900 "Price Validity Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleLineBecomesItsOwnCoveragePeriod()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] One validity window passes through as one coverage period
        AddLine(Line, 10000, DMY2Date(1, 2, 2027), DMY2Date(28, 2, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected a single input line to produce exactly one coverage period');
        AssertPeriod(Merged, 10000, DMY2Date(1, 2, 2027), DMY2Date(28, 2, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisjointPeriodsStaySeparateAndSortedByDate()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] Two windows with a real gap stay apart; output is numbered in date order, not input order
        // [GIVEN] the later window is inserted first
        AddLine(Line, 10000, DMY2Date(1, 3, 2027), DMY2Date(31, 3, 2027));
        AddLine(Line, 20000, DMY2Date(1, 1, 2027), DMY2Date(31, 1, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 2, 'Expected two disjoint validity windows to stay two separate coverage periods');
        AssertPeriod(Merged, 10000, DMY2Date(1, 1, 2027), DMY2Date(31, 1, 2027));
        AssertPeriod(Merged, 20000, DMY2Date(1, 3, 2027), DMY2Date(31, 3, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverlappingPeriodsMergeIntoOne()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] Two windows sharing several days combine into one coverage period
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(20, 1, 2027));
        AddLine(Line, 20000, DMY2Date(10, 1, 2027), DMY2Date(5, 2, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected two overlapping validity windows to merge into one coverage period');
        AssertPeriod(Merged, 10000, DMY2Date(1, 1, 2027), DMY2Date(5, 2, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeriodsSharingOneDayMerge()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] One window ends on the exact day the next begins — one shared day, one coverage period
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(10, 1, 2027));
        AddLine(Line, 20000, DMY2Date(10, 1, 2027), DMY2Date(20, 1, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected windows sharing exactly one day to merge into one coverage period');
        AssertPeriod(Merged, 10000, DMY2Date(1, 1, 2027), DMY2Date(20, 1, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdjacentPeriodsMergeIntoContinuousCoverage()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] A window starting the day after the previous one ends continues the same coverage
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(10, 1, 2027));
        AddLine(Line, 20000, DMY2Date(11, 1, 2027), DMY2Date(20, 1, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected adjacent validity windows (no uncovered day between them) to merge into one coverage period');
        AssertPeriod(Merged, 10000, DMY2Date(1, 1, 2027), DMY2Date(20, 1, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneDayGapKeepsPeriodsSeparate()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] A single uncovered day between two windows keeps them separate coverage periods
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(10, 1, 2027));
        AddLine(Line, 20000, DMY2Date(12, 1, 2027), DMY2Date(20, 1, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 2, 'Expected windows separated by one full uncovered day (January 11) to stay two coverage periods');
        AssertPeriod(Merged, 10000, DMY2Date(1, 1, 2027), DMY2Date(10, 1, 2027));
        AssertPeriod(Merged, 20000, DMY2Date(12, 1, 2027), DMY2Date(20, 1, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContainedPeriodIsAbsorbed()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] A window fully inside another must not shorten the coverage period's end
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(31, 12, 2027));
        AddLine(Line, 20000, DMY2Date(1, 3, 2027), DMY2Date(31, 3, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected a window fully contained in another to be absorbed into one coverage period');
        AssertPeriod(Merged, 10000, DMY2Date(1, 1, 2027), DMY2Date(31, 12, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChainOfOverlapsCollapsesToOnePeriod()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] Three windows chained by overlaps, inserted unsorted, collapse to one coverage period
        AddLine(Line, 10000, DMY2Date(15, 1, 2027), DMY2Date(15, 2, 2027));
        AddLine(Line, 20000, DMY2Date(1, 2, 2027), DMY2Date(10, 3, 2027));
        AddLine(Line, 30000, DMY2Date(1, 1, 2027), DMY2Date(20, 1, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected a chain of pairwise-overlapping windows to collapse into one coverage period');
        AssertPeriod(Merged, 10000, DMY2Date(1, 1, 2027), DMY2Date(10, 3, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankEndingDateMakesCoverageOpenEnded()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] A blank ending date means "valid forever", so a later window is swallowed
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), 0D);
        AddLine(Line, 20000, DMY2Date(1, 3, 2027), DMY2Date(31, 3, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected an open-ended window (blank "Ending Date" = forever) to absorb every later window');
        AssertPeriod(Merged, 10000, DMY2Date(1, 1, 2027), 0D);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankStartingDateKeepsCoverageUnbounded()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] A blank starting date means "always valid so far" and survives the merge
        AddLine(Line, 10000, DMY2Date(15, 1, 2027), DMY2Date(28, 2, 2027));
        AddLine(Line, 20000, 0D, DMY2Date(31, 1, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected a blank-start window overlapping a dated window to yield one coverage period');
        AssertPeriod(Merged, 10000, 0D, DMY2Date(28, 2, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdjacentBlankBoundsCoverAllTime()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] blank..Jan31 followed the very next day by Feb1..blank covers all of time
        AddLine(Line, 10000, 0D, DMY2Date(31, 1, 2027));
        AddLine(Line, 20000, DMY2Date(1, 2, 2027), 0D);

        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 1, 'Expected an adjacent blank-start and blank-end pair to merge into one all-time coverage period');
        AssertPeriod(Merged, 10000, 0D, 0D);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaleOutputRecordsAreRemovedBeforeMerging()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The output buffer arrives dirty and must be cleared first
        AddLine(Merged, 99999, DMY2Date(1, 6, 2020), DMY2Date(30, 6, 2020));
        AddLine(Line, 10000, DMY2Date(1, 5, 2027), DMY2Date(31, 5, 2027));

        Analyzer.MergeValidityPeriods(Line, Merged);

        Merged.Reset();
        Merged.SetRange("Line No.", 99999);
        Assert.IsTrue(Merged.IsEmpty(),
            'Expected MergeValidityPeriods to remove records already sitting in the output buffer — a stale record with Line No. 99999 survived');
        AssertPeriodCount(Merged, 1, 'Expected exactly one coverage period after the dirty output buffer was cleared');
        AssertPeriod(Merged, 10000, DMY2Date(1, 5, 2027), DMY2Date(31, 5, 2027));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyInputProducesNoCoverage()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
    begin
        // [SCENARIO] No input lines, no coverage periods
        Analyzer.MergeValidityPeriods(Line, Merged);

        AssertPeriodCount(Merged, 0, 'Expected an empty input buffer to produce no coverage periods');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomPeriodsMergeMatchesDayByDayCoverage()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Any: Codeunit Any;
        Covered: array[46] of Boolean;
        BaseDate: Date;
        StartOffset: Integer;
        EndOffset: Integer;
        i: Integer;
        Day: Integer;
        RunStart: Integer;
        InRun: Boolean;
        ExpectedLineNo: Integer;
    begin
        // [SCENARIO] Random windows are graded day by day: each maximal run of covered days is one coverage period
        BaseDate := DMY2Date(1, 3, 2027);
        for i := 1 to 5 do begin
            StartOffset := Any.IntegerInRange(1, 35);
            EndOffset := StartOffset + Any.IntegerInRange(0, 8);
            AddLine(Line, i * 10000, BaseDate + StartOffset - 1, BaseDate + EndOffset - 1);
            for Day := StartOffset to EndOffset do
                Covered[Day] := true;
        end;

        Analyzer.MergeValidityPeriods(Line, Merged);

        // Day 46 can never be covered (latest end is day 43); walking onto it
        // closes the last run without an out-of-bounds read.
        for Day := 1 to 46 do
            if Covered[Day] then begin
                if not InRun then begin
                    InRun := true;
                    RunStart := Day;
                end;
            end else
                if InRun then begin
                    InRun := false;
                    ExpectedLineNo += 10000;
                    AssertPeriod(Merged, ExpectedLineNo, BaseDate + RunStart - 1, BaseDate + Day - 2);
                end;
        AssertPeriodCount(Merged, ExpectedLineNo div 10000,
            'Expected exactly one coverage period per continuous run of covered days in the randomized input');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisjointPeriodsDoNotConflict()
    var
        Line: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Windows with a real gap between them are no conflict
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(31, 1, 2027));
        AddLine(Line, 20000, DMY2Date(1, 3, 2027), DMY2Date(31, 3, 2027));

        Assert.AreEqual(0, Analyzer.CountConflictingPairs(Line),
            'Expected disjoint validity windows to produce no conflicting pairs');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdjacentPeriodsDoNotConflict()
    var
        Line: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Touching windows share no day, so they merge in coverage but are NOT a conflict
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(10, 1, 2027));
        AddLine(Line, 20000, DMY2Date(11, 1, 2027), DMY2Date(20, 1, 2027));

        Assert.AreEqual(0, Analyzer.CountConflictingPairs(Line),
            'Expected adjacent windows (one ends the day before the other starts) to count as zero conflicts — they share no day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverlappingPairCountsOnce()
    var
        Line: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] One overlapping pair is exactly one conflict, not two ordered ones
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(20, 1, 2027));
        AddLine(Line, 20000, DMY2Date(15, 1, 2027), DMY2Date(31, 1, 2027));

        Assert.AreEqual(1, Analyzer.CountConflictingPairs(Line),
            'Expected one overlapping pair to count as exactly 1 conflict — pairs are unordered');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SharedOverlapCountsPairsNotLines()
    var
        Line: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A year-long window against two disjoint short ones is 2 pairs, though 3 lines are involved
        AddLine(Line, 10000, DMY2Date(1, 1, 2027), DMY2Date(31, 12, 2027));
        AddLine(Line, 20000, DMY2Date(10, 1, 2027), DMY2Date(20, 1, 2027));
        AddLine(Line, 30000, DMY2Date(1, 3, 2027), DMY2Date(10, 3, 2027));

        Assert.AreEqual(2, Analyzer.CountConflictingPairs(Line),
            'Expected 2 conflicting pairs (year+January, year+March) — count pairs, not the number of lines involved');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IdenticalPeriodsConflict()
    var
        Line: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Two lines with the same window are the classic duplicate import — one conflicting pair
        AddLine(Line, 10000, DMY2Date(1, 4, 2027), DMY2Date(30, 4, 2027));
        AddLine(Line, 20000, DMY2Date(1, 4, 2027), DMY2Date(30, 4, 2027));

        Assert.AreEqual(1, Analyzer.CountConflictingPairs(Line),
            'Expected two identical validity windows to count as 1 conflicting pair');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenEndedPeriodConflictsWithMuchLaterPeriod()
    var
        Line: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Blank ending date means forever — it overlaps a window years later
        AddLine(Line, 10000, DMY2Date(1, 6, 2027), 0D);
        AddLine(Line, 20000, DMY2Date(1, 12, 2029), DMY2Date(31, 12, 2029));

        Assert.AreEqual(1, Analyzer.CountConflictingPairs(Line),
            'Expected an open-ended window (blank "Ending Date") to conflict with a window starting years later — blank means forever, not the earliest date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomPeriodsConflictCountMatchesPairwiseCheck()
    var
        Line: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Starts: array[6] of Date;
        Ends: array[6] of Date;
        BaseDate: Date;
        Expected: Integer;
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO] Random windows are graded against an independent pairwise overlap check
        BaseDate := DMY2Date(1, 6, 2027);
        for i := 1 to 6 do begin
            Starts[i] := BaseDate + Any.IntegerInRange(1, 30);
            Ends[i] := Starts[i] + Any.IntegerInRange(0, 10);
            AddLine(Line, i * 10000, Starts[i], Ends[i]);
        end;
        for i := 1 to 5 do
            for j := i + 1 to 6 do
                if (Starts[j] <= Ends[i]) and (Starts[i] <= Ends[j]) then
                    Expected += 1;

        Assert.AreEqual(Expected, Analyzer.CountConflictingPairs(Line),
            'Expected the conflict count for the randomized windows to equal the number of pairs sharing at least one day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MergeRejectsEndingDateBeforeStartingDate()
    var
        Line: Record "Price List Line" temporary;
        Merged: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A reversed validity window fails the merge with the promised message
        AddLine(Line, 10000, DMY2Date(10, 5, 2027), DMY2Date(1, 5, 2027));

        asserterror Analyzer.MergeValidityPeriods(Line, Merged);
        Assert.ExpectedError('before the starting date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConflictCountRejectsEndingDateBeforeStartingDate()
    var
        Line: Record "Price List Line" temporary;
        Analyzer: Codeunit "Price Validity Analyzer";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A reversed validity window fails the conflict count with the promised message
        AddLine(Line, 10000, DMY2Date(1, 7, 2027), DMY2Date(31, 7, 2027));
        AddLine(Line, 20000, DMY2Date(10, 7, 2027), DMY2Date(5, 7, 2027));

        asserterror Analyzer.CountConflictingPairs(Line);
        Assert.ExpectedError('before the starting date');
    end;

    local procedure AddLine(var PriceListLine: Record "Price List Line" temporary; LineNo: Integer; StartDate: Date; EndDate: Date)
    begin
        PriceListLine.Init();
        PriceListLine."Line No." := LineNo;
        PriceListLine."Starting Date" := StartDate;
        PriceListLine."Ending Date" := EndDate;
        PriceListLine.Insert();
    end;

    local procedure AssertPeriod(var MergedPeriod: Record "Price List Line" temporary; ExpectedLineNo: Integer; ExpectedStart: Date; ExpectedEnd: Date)
    var
        Assert: Codeunit Assert;
        TotalPeriods: Integer;
    begin
        MergedPeriod.Reset();
        TotalPeriods := MergedPeriod.Count();
        MergedPeriod.SetRange("Line No.", ExpectedLineNo);
        Assert.IsTrue(MergedPeriod.FindFirst(),
            StrSubstNo('Expected a merged coverage period with Line No. %1 (numbering starts at 10000 in ascending date order); the output holds %2 period(s)', ExpectedLineNo, TotalPeriods));
        Assert.AreEqual(ExpectedStart, MergedPeriod."Starting Date",
            StrSubstNo('Wrong "Starting Date" on merged coverage period %1 (a blank date means no lower bound)', ExpectedLineNo));
        Assert.AreEqual(ExpectedEnd, MergedPeriod."Ending Date",
            StrSubstNo('Wrong "Ending Date" on merged coverage period %1 (a blank date means open-ended)', ExpectedLineNo));
        MergedPeriod.Reset();
    end;

    local procedure AssertPeriodCount(var MergedPeriod: Record "Price List Line" temporary; ExpectedCount: Integer; Msg: Text)
    var
        Assert: Codeunit Assert;
    begin
        MergedPeriod.Reset();
        Assert.AreEqual(ExpectedCount, MergedPeriod.Count(), Msg);
    end;
}
