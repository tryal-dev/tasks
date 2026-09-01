codeunit 50900 "Downtime Analysis Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleStopTotalIsItsDuration()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] One stop from 06:10 to 06:35 is 25 minutes of downtime
        ShiftDate := DMY2Date(12, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 6, 35, 'running'));
        LogLines.Add(LogLine(ShiftDate, 6, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 6, 10, 'stopped'));

        Assert.AreEqual(25, Analyzer.TotalDowntimeMinutes(LogLines, 'GRINDER'),
            'Expected a single stop from 06:10 to 06:35 to count as 25 minutes of downtime');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MultipleStopsInOneShiftAddUp()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] Three stops of 5, 20, and 2 minutes in one shift sum to 27
        ShiftDate := DMY2Date(13, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 7, 20, 'running'));
        LogLines.Add(LogLine(ShiftDate, 6, 10, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 9, 1, 'running'));
        LogLines.Add(LogLine(ShiftDate, 6, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 8, 59, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 6, 15, 'running'));
        LogLines.Add(LogLine(ShiftDate, 7, 0, 'stopped'));

        Assert.AreEqual(27, Analyzer.TotalDowntimeMinutes(LogLines, 'GRINDER'),
            'Expected stops of 5, 20, and 2 minutes within one shift to add up to 27 minutes of downtime');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShuffledLogAttributesStopToEarlierShift()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
    begin
        // [SCENARIO] Bare stopped/running lines belong to the latest shift start BY TIMESTAMP, not by list position
        // [GIVEN] a scrambled log where processing in list order pairs the stops with the wrong work centers
        BuildCrossedShiftsLog(LogLines);

        Assert.AreEqual(15, Analyzer.TotalDowntimeMinutes(LogLines, 'GRINDER'),
            'Expected GRINDER to own only the 22:30-22:45 stop (15 minutes) - sort the log by timestamp before attributing stops');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShuffledLogAttributesStopToLaterShift()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
    begin
        // [SCENARIO] The stop after MILL's 23:00 shift start belongs to MILL even though GRINDER's lines surround it in list order
        // [GIVEN] a scrambled log where processing in list order pairs the stops with the wrong work centers
        BuildCrossedShiftsLog(LogLines);

        Assert.AreEqual(20, Analyzer.TotalDowntimeMinutes(LogLines, 'MILL'),
            'Expected MILL to own only the 23:10-23:30 stop (20 minutes) - sort the log by timestamp before attributing stops');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MidnightSpanningStopCountsEveryMinute()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] A stop from 23:50 to 00:10 next day is 20 minutes, never negative or a day too long
        ShiftDate := DMY2Date(15, 8, 2027);
        LogLines.Add(LogLine(ShiftDate, 23, 50, 'stopped'));
        LogLines.Add(LogLine(ShiftDate + 1, 0, 10, 'running'));
        LogLines.Add(LogLine(ShiftDate, 23, 30, 'GRINDER begins shift'));

        Assert.AreEqual(20, Analyzer.TotalDowntimeMinutes(LogLines, 'GRINDER'),
            'Expected a stop from 23:50 to 00:10 the next day to count as 20 minutes - the stop spans midnight');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalIsZeroForWorkCenterThatNeverStopped()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] A work center with a shift but no stops has zero downtime
        ShiftDate := DMY2Date(16, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 6, 5, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 7, 0, 'MILL begins shift'));
        LogLines.Add(LogLine(ShiftDate, 6, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 6, 10, 'running'));

        Assert.AreEqual(0, Analyzer.TotalDowntimeMinutes(LogLines, 'MILL'),
            'Expected 0 downtime minutes for MILL - its shift records no stopped event (the 06:05 stop belongs to GRINDER)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyLogHasZeroTotal()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
    begin
        // [SCENARIO] An empty log yields zero downtime for any work center
        Assert.AreEqual(0, Analyzer.TotalDowntimeMinutes(LogLines, 'GRINDER'),
            'Expected 0 downtime minutes from an empty log');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyLogHasNoMostFrequentMinute()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
    begin
        // [SCENARIO] An empty log has no down minute at all, so the answer is -1, not an error
        Assert.AreEqual(-1, Analyzer.MostFrequentDownMinute(LogLines, 'GRINDER'),
            'Expected -1 as the most frequent down minute of an empty log');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AbsentWorkCenterHasZeroTotal()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] A work center that never appears in a non-empty log has zero downtime
        ShiftDate := DMY2Date(24, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 6, 30, 'running'));
        LogLines.Add(LogLine(ShiftDate, 6, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 6, 20, 'stopped'));

        Assert.AreEqual(0, Analyzer.TotalDowntimeMinutes(LogLines, 'WELDER'),
            'Expected 0 downtime minutes for a work center that never appears in the log');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AbsentWorkCenterHasNoMostFrequentMinute()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] A work center that never appears in a non-empty log has no most frequent down minute
        ShiftDate := DMY2Date(25, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 7, 45, 'running'));
        LogLines.Add(LogLine(ShiftDate, 7, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 7, 30, 'stopped'));

        Assert.AreEqual(-1, Analyzer.MostFrequentDownMinute(LogLines, 'WELDER'),
            'Expected -1 for a work center that never appears in the log');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MostFrequentMinuteIsFoundAcrossShifts()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        BaseDate: Date;
        GrinderStopMin: array[3] of Integer;
        GrinderRunMin: array[3] of Integer;
        DayNo: Integer;
    begin
        // [SCENARIO] Three GRINDER shifts overlap only at 06:25-06:27, so minute 385 wins; MILL is down 05:10-05:19 every day as a decoy
        BaseDate := DMY2Date(1, 9, 2027);
        GrinderStopMin[1] := 10;
        GrinderRunMin[1] := 30;
        GrinderStopMin[2] := 20;
        GrinderRunMin[2] := 40;
        GrinderStopMin[3] := 25;
        GrinderRunMin[3] := 28;
        for DayNo := 3 downto 1 do begin
            LogLines.Add(LogLine(BaseDate + DayNo - 1, 6, GrinderStopMin[DayNo], 'stopped'));
            LogLines.Add(LogLine(BaseDate + DayNo - 1, 5, 0, 'MILL begins shift'));
            LogLines.Add(LogLine(BaseDate + DayNo - 1, 6, GrinderRunMin[DayNo], 'running'));
            LogLines.Add(LogLine(BaseDate + DayNo - 1, 5, 10, 'stopped'));
            LogLines.Add(LogLine(BaseDate + DayNo - 1, 6, 0, 'GRINDER begins shift'));
            LogLines.Add(LogLine(BaseDate + DayNo - 1, 5, 20, 'running'));
        end;

        Assert.AreEqual(385, Analyzer.MostFrequentDownMinute(LogLines, 'GRINDER'),
            'Expected minute 385 (06:25), the only minute down in all three GRINDER stops - MILL''s daily 05:10 stop must not leak into GRINDER''s tally');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TieOnDownCountReturnsEarliestMinute()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] Two stops that never overlap leave every covered minute at count 1 - the smallest minute of day wins
        ShiftDate := DMY2Date(17, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 9, 0, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 8, 5, 'running'));
        LogLines.Add(LogLine(ShiftDate, 6, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 9, 5, 'running'));
        LogLines.Add(LogLine(ShiftDate, 8, 0, 'stopped'));

        Assert.AreEqual(480, Analyzer.MostFrequentDownMinute(LogLines, 'GRINDER'),
            'Expected minute 480 (08:00): all covered minutes tie at one stop each, and ties resolve to the smallest minute of day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MostFrequentMinuteWrapsAcrossMidnight()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        BaseDate: Date;
    begin
        // [SCENARIO] A 23:50-00:10 stop covers minutes on BOTH sides of midnight; combined with 00:02-00:06 and 00:03-00:09 stops, minute 3 is down three times
        BaseDate := DMY2Date(20, 10, 2027);
        LogLines.Add(LogLine(BaseDate + 2, 0, 2, 'stopped'));
        LogLines.Add(LogLine(BaseDate, 23, 40, 'GRINDER begins shift'));
        LogLines.Add(LogLine(BaseDate + 3, 0, 9, 'running'));
        LogLines.Add(LogLine(BaseDate, 23, 50, 'stopped'));
        LogLines.Add(LogLine(BaseDate + 2, 23, 40, 'GRINDER begins shift'));
        LogLines.Add(LogLine(BaseDate + 1, 0, 10, 'running'));
        LogLines.Add(LogLine(BaseDate + 3, 0, 3, 'stopped'));
        LogLines.Add(LogLine(BaseDate + 1, 23, 40, 'GRINDER begins shift'));
        LogLines.Add(LogLine(BaseDate + 2, 0, 6, 'running'));

        Assert.AreEqual(3, Analyzer.MostFrequentDownMinute(LogLines, 'GRINDER'),
            'Expected minute 3 (00:03), down in all three stops - the 23:50-00:10 stop must also cover the minutes after midnight');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StopEndMinuteIsNotCountedAsDown()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] A stop ending at 06:10 on day one and a stop starting at 06:10 on day two share that minute of day only if the end minute is wrongly counted as down
        ShiftDate := DMY2Date(22, 4, 2027);
        LogLines.Add(LogLine(ShiftDate + 1, 6, 10, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 6, 0, 'stopped'));
        LogLines.Add(LogLine(ShiftDate + 1, 6, 20, 'running'));
        LogLines.Add(LogLine(ShiftDate, 5, 50, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 6, 10, 'running'));

        Assert.AreEqual(360, Analyzer.MostFrequentDownMinute(LogLines, 'GRINDER'),
            'Expected minute 360 (06:00): a stop covers its start minute but not the minute it ends, so every covered minute ties at one stop and the earliest wins');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinuteIsMinusOneWithoutDowntime()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
    begin
        // [SCENARIO] A work center that never stopped has no most frequent down minute
        LogLines.Add(LogLine(DMY2Date(18, 4, 2027), 6, 0, 'APOLLO begins shift'));

        Assert.AreEqual(-1, Analyzer.MostFrequentDownMinute(LogLines, 'APOLLO'),
            'Expected -1 for a work center whose shift records no stops at all');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoppedAtLogEndRaisesUnmatchedError()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] A stopped event as the chronologically last line has no running event to close it
        ShiftDate := DMY2Date(19, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 7, 0, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 6, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 6, 20, 'running'));
        LogLines.Add(LogLine(ShiftDate, 6, 10, 'stopped'));

        asserterror Analyzer.TotalDowntimeMinutes(LogLines, 'GRINDER');
        Assert.ExpectedError('no matching running event');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoppedCutOffByNextShiftRaisesErrorForAnyWorkCenter()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] GRINDER's 22:30 stop is cut off by MILL's shift start; even asking about MILL must fail
        ShiftDate := DMY2Date(20, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 23, 5, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 22, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 23, 15, 'running'));
        LogLines.Add(LogLine(ShiftDate, 22, 30, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 23, 0, 'MILL begins shift'));

        asserterror Analyzer.MostFrequentDownMinute(LogLines, 'MILL');
        Assert.ExpectedError('no matching running event');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoStoppedInARowRaiseUnmatchedError()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        LogLines: List of [Text];
        ShiftDate: Date;
    begin
        // [SCENARIO] A second stopped arrives while the first is still open - the first has no matching running event
        ShiftDate := DMY2Date(21, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 6, 30, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 6, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 6, 40, 'running'));
        LogLines.Add(LogLine(ShiftDate, 6, 10, 'stopped'));

        asserterror Analyzer.TotalDowntimeMinutes(LogLines, 'GRINDER');
        Assert.ExpectedError('no matching running event');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomStopsTotalMatchesSumOfDurations()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ChronoLines: List of [Text];
        ShiftDate: Date;
        CurrentMinute: Integer;
        StopMinute: Integer;
        StopLength: Integer;
        ExpectedTotal: Integer;
        i: Integer;
    begin
        // [SCENARIO] Four random stops are graded against an independently accumulated sum, so hardcoded answers fail
        ShiftDate := DMY2Date(3, 5, 2027);
        ChronoLines.Add(LogLine(ShiftDate, 6, 0, 'PRESS begins shift'));
        CurrentMinute := 6 * 60;
        for i := 1 to 4 do begin
            StopMinute := CurrentMinute + Any.IntegerInRange(1, 25);
            StopLength := Any.IntegerInRange(1, 45);
            ChronoLines.Add(LogLine(ShiftDate, StopMinute div 60, StopMinute mod 60, 'stopped'));
            ChronoLines.Add(LogLine(ShiftDate, (StopMinute + StopLength) div 60, (StopMinute + StopLength) mod 60, 'running'));
            ExpectedTotal += StopLength;
            CurrentMinute := StopMinute + StopLength;
        end;

        Assert.AreEqual(ExpectedTotal, Analyzer.TotalDowntimeMinutes(Shuffled(ChronoLines), 'PRESS'),
            'Expected the total downtime of the randomized log to equal the sum of its stop durations');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomLogMostFrequentMinuteMatchesIndependentTally()
    var
        Analyzer: Codeunit "Downtime Analyzer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ChronoLines: List of [Text];
        DownCount: array[1440] of Integer;
        BaseDate: Date;
        CurrentMinute: Integer;
        StopMinute: Integer;
        StopLength: Integer;
        ExpectedMinute: Integer;
        BestCount: Integer;
        DayNo: Integer;
        i: Integer;
        m: Integer;
    begin
        // [SCENARIO] Six random stops over three shifts are graded against an independent minute-by-minute tally
        BaseDate := DMY2Date(10, 6, 2027);
        for DayNo := 0 to 2 do begin
            ChronoLines.Add(LogLine(BaseDate + DayNo, 6, 0, 'LATHE begins shift'));
            CurrentMinute := 6 * 60;
            for i := 1 to 2 do begin
                StopMinute := CurrentMinute + Any.IntegerInRange(1, 30);
                StopLength := Any.IntegerInRange(5, 60);
                ChronoLines.Add(LogLine(BaseDate + DayNo, StopMinute div 60, StopMinute mod 60, 'stopped'));
                ChronoLines.Add(LogLine(BaseDate + DayNo, (StopMinute + StopLength) div 60, (StopMinute + StopLength) mod 60, 'running'));
                for m := StopMinute to StopMinute + StopLength - 1 do
                    DownCount[m + 1] += 1;
                CurrentMinute := StopMinute + StopLength;
            end;
        end;
        ExpectedMinute := -1;
        for m := 1 to 1440 do
            if DownCount[m] > BestCount then begin
                BestCount := DownCount[m];
                ExpectedMinute := m - 1;
            end;

        Assert.AreEqual(ExpectedMinute, Analyzer.MostFrequentDownMinute(Shuffled(ChronoLines), 'LATHE'),
            'Expected the most frequent down minute of the randomized log to match an independent minute-by-minute tally (ties resolve to the smallest minute of day)');
    end;

    local procedure BuildCrossedShiftsLog(var LogLines: List of [Text])
    var
        ShiftDate: Date;
    begin
        ShiftDate := DMY2Date(14, 4, 2027);
        LogLines.Add(LogLine(ShiftDate, 23, 0, 'MILL begins shift'));
        LogLines.Add(LogLine(ShiftDate, 22, 30, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 23, 30, 'running'));
        LogLines.Add(LogLine(ShiftDate, 22, 0, 'GRINDER begins shift'));
        LogLines.Add(LogLine(ShiftDate, 23, 10, 'stopped'));
        LogLines.Add(LogLine(ShiftDate, 22, 45, 'running'));
    end;

    local procedure LogLine(EventDate: Date; EventHour: Integer; EventMinute: Integer; EventText: Text): Text
    begin
        exit(StrSubstNo('[%1 %2:%3] %4',
            Format(EventDate, 0, '<Year4>-<Month,2>-<Day,2>'),
            Format(EventHour, 0, '<Integer,2><Filler Character,0>'),
            Format(EventMinute, 0, '<Integer,2><Filler Character,0>'),
            EventText));
    end;

    local procedure Shuffled(LogLines: List of [Text]) Result: List of [Text]
    var
        Any: Codeunit Any;
        Line: Text;
        InsertAt: Integer;
    begin
        foreach Line in LogLines do begin
            InsertAt := Any.IntegerInRange(1, Result.Count() + 1);
            if InsertAt > Result.Count() then
                Result.Add(Line)
            else
                Result.Insert(InsertAt, Line);
        end;
    end;
}
