codeunit 50900 "Recurrence Planner Tests"
{
    // [FEATURE] [Recurrence Planner]
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeeklyFirstOccurrenceFallsOnTheAnchorDate()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A weekly schedule anchored on a scheduled weekday starts on the anchor itself
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, MonWedFri(), DMY2Date(31, 12, 2026));

        Assert.AreEqual(At(6, 7, 2026, 090000T), Planner.CalculateNextOccurrence(0DT),
            'Expected the very first occurrence of a Mon-Wed-Fri schedule anchored on Monday 6 July 2026 to be that same Monday at 09:00 — 0DT asks for the first occurrence, and StartDate itself counts when its weekday is scheduled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeeklySequenceFollowsTheWeekdaySet()
    var
        Planner: Codeunit "Recurrence Planner";
        Expected: List of [DateTime];
    begin
        // [SCENARIO] The first five occurrences of a Mon-Wed-Fri schedule land on Mon, Wed, Fri, Mon, Wed
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 060000T, MonWedFri(), DMY2Date(31, 12, 2026));

        Expected.Add(At(6, 7, 2026, 060000T));
        Expected.Add(At(8, 7, 2026, 060000T));
        Expected.Add(At(10, 7, 2026, 060000T));
        Expected.Add(At(13, 7, 2026, 060000T));
        Expected.Add(At(15, 7, 2026, 060000T));

        AssertOccurrenceList(Expected, Planner.NextOccurrences(0DT, 5),
            'the Mon-Wed-Fri schedule anchored on Monday 6 July 2026 at 06:00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnAnchorOnAnUnscheduledWeekdayRollsForward()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A Friday-only schedule anchored on a Tuesday first fires on the coming Friday
        Planner.CreateWeekly(DMY2Date(7, 7, 2026), 090000T, SingleWeekday(5), 0D);

        Assert.AreEqual(At(10, 7, 2026, 090000T), Planner.CalculateNextOccurrence(0DT),
            'Expected a Friday-only schedule anchored on Tuesday 7 July 2026 to fire first on Friday 10 July 2026 at 09:00 — the anchor day itself is not a scheduled weekday');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QueryingFromBeforeTheStartDateStartsAtTheAnchor()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A moment weeks before StartDate yields the schedule's first occurrence, never a pre-anchor date
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, MonWedFri(), 0D);

        Assert.AreEqual(At(6, 7, 2026, 090000T), Planner.CalculateNextOccurrence(At(1, 6, 2026, 120000T)),
            'Expected the next occurrence after Monday 1 June 2026 12:00 to be Monday 6 July 2026 at 09:00 — occurrences only exist from StartDate onward, so June dates whose weekday matches the set must not be returned');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextOccurrenceIsStrictlyAfterTheGivenMoment()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Passing an occurrence's own DateTime yields the following occurrence, not the same one back
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, MonWedFri(), 0D);

        Assert.AreEqual(At(10, 7, 2026, 090000T), Planner.CalculateNextOccurrence(At(8, 7, 2026, 090000T)),
            'Expected the occurrence after Wednesday 8 July 2026 09:00 to be Friday 10 July 2026 09:00 — the result must be strictly later than LastOccurrence, so Wednesday itself must not be returned again');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnEarlierMomentOnAScheduledDayYieldsThatSameDay()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] When the given moment is before StartTime on an occurrence date, that date's occurrence is still ahead
        Planner.CreateWeekly(DMY2Date(1, 7, 2026), 143000T, SingleWeekday(3), 0D);

        Assert.AreEqual(At(8, 7, 2026, 143000T), Planner.CalculateNextOccurrence(At(8, 7, 2026, 060000T)),
            'Expected the next occurrence after Wednesday 8 July 2026 06:00 to be that same Wednesday at 14:30 — the day''s occurrence is still ahead when LastOccurrence is earlier than StartTime, so it must not be skipped to the following week');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnOccurrenceExactlyOnTheEndDateIsIncluded()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] EndDate is inclusive: an occurrence date equal to EndDate still fires
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, MonWedFri(), DMY2Date(10, 7, 2026));

        Assert.AreEqual(At(10, 7, 2026, 090000T), Planner.CalculateNextOccurrence(At(8, 7, 2026, 090000T)),
            'Expected the occurrence on Friday 10 July 2026 to fire even though 10 July is the EndDate — a date on EndDate still carries an occurrence');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BeyondTheEndDateComesZeroDateTime()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Once the last occurrence has passed, the schedule answers 0DT
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, MonWedFri(), DMY2Date(10, 7, 2026));

        Assert.AreEqual(0DT, Planner.CalculateNextOccurrence(At(10, 7, 2026, 090000T)),
            'Expected 0DT after the occurrence on Friday 10 July 2026 — the EndDate is 10 July, so no occurrence remains and the schedule must signal its end with 0DT');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AScheduleWithoutAnEndDateNeverRunsOut()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] With EndDate 0D the schedule still answers years past its anchor
        Planner.CreateWeekly(DMY2Date(1, 1, 2026), 090000T, SingleWeekday(1), 0D);

        Assert.AreEqual(At(7, 1, 2030, 090000T), Planner.CalculateNextOccurrence(At(1, 1, 2030, 090000T)),
            'Expected the Monday-only schedule with no EndDate to answer Monday 7 January 2030 at 09:00 when asked from Tuesday 1 January 2030 — an EndDate of 0D means the schedule never ends');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextOccurrencesStopsEarlyWhenTheScheduleEnds()
    var
        Planner: Codeunit "Recurrence Planner";
        Expected: List of [DateTime];
    begin
        // [SCENARIO] Asking for ten occurrences of a schedule that only has three yields exactly those three
        Planner.CreateWeekly(DMY2Date(1, 7, 2026), 090000T, SingleWeekday(3), DMY2Date(21, 7, 2026));

        Expected.Add(At(1, 7, 2026, 090000T));
        Expected.Add(At(8, 7, 2026, 090000T));
        Expected.Add(At(15, 7, 2026, 090000T));

        AssertOccurrenceList(Expected, Planner.NextOccurrences(0DT, 10),
            'the Wednesday-only schedule from 1 July 2026 ending 21 July 2026, asked for 10 occurrences');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextOccurrencesIsEmptyWhenNothingRemains()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Asked from a moment past the schedule's last occurrence, NextOccurrences yields an empty list
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, MonWedFri(), DMY2Date(10, 7, 2026));

        Assert.AreEqual(0, Planner.NextOccurrences(At(10, 7, 2026, 090000T), 5).Count(),
            'Expected an empty list when asking for occurrences after Friday 10 July 2026 09:00 — the EndDate is 10 July, so nothing remains and NextOccurrences must return no entries rather than fail');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LastFridayOfEveryMonthSequence()
    var
        Planner: Codeunit "Recurrence Planner";
        Expected: List of [DateTime];
    begin
        // [SCENARIO] The last Friday of Jan-Apr 2026 lands on the 30th, 27th, 27th and 24th
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 1, 2026), 170000T, "Recurrence Ordinal"::Last, 5, DMY2Date(31, 12, 2026));

        Expected.Add(At(30, 1, 2026, 170000T));
        Expected.Add(At(27, 2, 2026, 170000T));
        Expected.Add(At(27, 3, 2026, 170000T));
        Expected.Add(At(24, 4, 2026, 170000T));

        AssertOccurrenceList(Expected, Planner.NextOccurrences(0DT, 4),
            'the last-Friday-of-the-month schedule anchored on 1 January 2026 at 17:00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstMondayOfEveryMonthSequence()
    var
        Planner: Codeunit "Recurrence Planner";
        Expected: List of [DateTime];
    begin
        // [SCENARIO] The first Monday of Jan-Apr 2026 lands on the 5th, 2nd, 2nd and 6th
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 1, 2026), 080000T, "Recurrence Ordinal"::First, 1, 0D);

        Expected.Add(At(5, 1, 2026, 080000T));
        Expected.Add(At(2, 2, 2026, 080000T));
        Expected.Add(At(2, 3, 2026, 080000T));
        Expected.Add(At(6, 4, 2026, 080000T));

        AssertOccurrenceList(Expected, Planner.NextOccurrences(0DT, 4),
            'the first-Monday-of-the-month schedule anchored on 1 January 2026 at 08:00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheSecondTuesdayOfAMonth()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Second picks the second matching weekday of the month, one week after the first
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 7, 2026), 100000T, "Recurrence Ordinal"::Second, 2, 0D);

        Assert.AreEqual(At(14, 7, 2026, 100000T), Planner.CalculateNextOccurrence(0DT),
            'Expected the second Tuesday of July 2026 to be 14 July at 10:00 — the Tuesdays of July 2026 are 7, 14, 21 and 28, and Second means the second one, a single week after the first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheThirdWednesdayOfEveryMonthSequence()
    var
        Planner: Codeunit "Recurrence Planner";
        Expected: List of [DateTime];
    begin
        // [SCENARIO] The third Wednesday of Jan-Mar 2026 lands on the 21st, 18th and 18th
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 1, 2026), 110000T, "Recurrence Ordinal"::Third, 3, 0D);

        Expected.Add(At(21, 1, 2026, 110000T));
        Expected.Add(At(18, 2, 2026, 110000T));
        Expected.Add(At(18, 3, 2026, 110000T));

        AssertOccurrenceList(Expected, Planner.NextOccurrences(0DT, 3),
            'the third-Wednesday-of-the-month schedule anchored on 1 January 2026 at 11:00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheFourthFridayOfAFiveFridayMonth()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] July 2026 has five Fridays; Fourth picks 24 July, not the month's last Friday
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 7, 2026), 170000T, "Recurrence Ordinal"::Fourth, 5, 0D);

        Assert.AreEqual(At(24, 7, 2026, 170000T), Planner.CalculateNextOccurrence(0DT),
            'Expected the fourth Friday of July 2026 to be 24 July at 17:00 — July 2026 has five Fridays (3, 10, 17, 24, 31), and Fourth means the fourth one, not the last one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheLastFridayOfAFiveFridayMonth()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] July 2026 has five Fridays; Last picks 31 July, a week after the fourth
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 7, 2026), 170000T, "Recurrence Ordinal"::Last, 5, 0D);

        Assert.AreEqual(At(31, 7, 2026, 170000T), Planner.CalculateNextOccurrence(0DT),
            'Expected the last Friday of July 2026 to be 31 July at 17:00 — July 2026 has five Fridays (3, 10, 17, 24, 31), so Last is the fifth, a full week after the fourth');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AMonthlyAnchorPastTheCandidateSkipsToTheNextMonth()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Anchored after July's first Monday, the schedule first fires on August's
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(10, 7, 2026), 080000T, "Recurrence Ordinal"::First, 1, 0D);

        Assert.AreEqual(At(3, 8, 2026, 080000T), Planner.CalculateNextOccurrence(0DT),
            'Expected the first occurrence to be Monday 3 August 2026 at 08:00 — the first Monday of July 2026 (6 July) lies before the StartDate of 10 July, so July contributes no occurrence');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AMonthlyScheduleStopsAtItsEndDate()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] With EndDate 15 April 2026, the last Friday of April (24 April) is out of reach
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 1, 2026), 170000T, "Recurrence Ordinal"::Last, 5, DMY2Date(15, 4, 2026));

        Assert.AreEqual(0DT, Planner.CalculateNextOccurrence(At(27, 3, 2026, 170000T)),
            'Expected 0DT after the occurrence on Friday 27 March 2026 — April''s last Friday, 24 April, falls after the EndDate of 15 April, so nothing remains');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AMonthlyOccurrenceExactlyOnTheEndDateIsIncluded()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] EndDate is inclusive for monthly schedules too: a candidate date equal to EndDate still fires
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 1, 2026), 170000T, "Recurrence Ordinal"::Last, 5, DMY2Date(27, 2, 2026));

        Assert.AreEqual(At(27, 2, 2026, 170000T), Planner.CalculateNextOccurrence(At(30, 1, 2026, 170000T)),
            'Expected the occurrence on Friday 27 February 2026 to fire even though 27 February is the EndDate — in the monthly kind too, a date on EndDate still carries an occurrence');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AMonthlyScheduleEndsRightAfterItsEndDateOccurrence()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Once the occurrence sitting exactly on EndDate has passed, the monthly schedule answers 0DT
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 1, 2026), 170000T, "Recurrence Ordinal"::Last, 5, DMY2Date(27, 2, 2026));

        Assert.AreEqual(0DT, Planner.CalculateNextOccurrence(At(27, 2, 2026, 170000T)),
            'Expected 0DT after the occurrence on Friday 27 February 2026 — that date is the EndDate, so March''s last Friday lies beyond the schedule and nothing remains');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreatingANewScheduleReplacesTheOldOne()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A second Create call on the same instance discards the first schedule entirely
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, SingleWeekday(1), 0D);
        Planner.CreateMonthlyByDayOfWeek(DMY2Date(1, 7, 2026), 170000T, "Recurrence Ordinal"::Last, 5, 0D);

        Assert.AreEqual(At(31, 7, 2026, 170000T), Planner.CalculateNextOccurrence(0DT),
            'Expected the first occurrence to be Friday 31 July 2026 at 17:00 from the last-Friday schedule — the earlier Monday-weekly schedule was replaced by the second Create call, so Monday 6 July at 09:00 would be wrong');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AskingBeforeAnyScheduleExistsRaisesAnError()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] CalculateNextOccurrence on a fresh instance is rejected
        asserterror Planner.CalculateNextOccurrence(0DT);

        Assert.ExpectedError('No schedule has been created');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AskingForZeroOccurrencesRaisesAnError()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A MaxCount of zero is rejected
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, MonWedFri(), 0D);

        asserterror Planner.NextOccurrences(0DT, 0);

        Assert.ExpectedError('at least one occurrence');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AskingForANegativeNumberOfOccurrencesRaisesAnError()
    var
        Planner: Codeunit "Recurrence Planner";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A negative MaxCount is rejected just like zero
        Planner.CreateWeekly(DMY2Date(6, 7, 2026), 090000T, MonWedFri(), 0D);

        asserterror Planner.NextOccurrences(0DT, -Any.IntegerInRange(1, 10));

        Assert.ExpectedError('at least one occurrence');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ARandomWeeklyScheduleMatchesADayByDayWalk()
    var
        Planner: Codeunit "Recurrence Planner";
        Any: Codeunit Any;
        Weekdays: List of [Integer];
        Expected: List of [DateTime];
        AnchorDate: Date;
        EndDate: Date;
        WalkDate: Date;
        StartTime: Time;
    begin
        // [SCENARIO] A randomized anchor, time of day, weekday set and end date match an independent calendar walk
        AnchorDate := Any.DateInRange(DMY2Date(1, 1, 2026), 1, 300);
        EndDate := AnchorDate + Any.IntegerInRange(30, 60);
        StartTime := DT2Time(CreateDateTime(AnchorDate, 000000T) + Any.IntegerInRange(0, 86399) * 1000);
        AddRandomWeekdaySet(Weekdays, Any);

        Planner.CreateWeekly(AnchorDate, StartTime, Weekdays, EndDate);

        WalkDate := AnchorDate;
        while (WalkDate <= EndDate) and (Expected.Count() < 8) do begin
            if Weekdays.Contains(Date2DWY(WalkDate, 1)) then
                Expected.Add(CreateDateTime(WalkDate, StartTime));
            WalkDate += 1;
        end;

        AssertOccurrenceList(Expected, Planner.NextOccurrences(0DT, 8),
            StrSubstNo('the randomized weekly schedule anchored %1 at %2 with weekday set %3 ending %4', AnchorDate, StartTime, WeekdaysText(Weekdays), EndDate));
    end;

    local procedure At(Day: Integer; Month: Integer; Year: Integer; TimeOfDay: Time): DateTime
    begin
        exit(CreateDateTime(DMY2Date(Day, Month, Year), TimeOfDay));
    end;

    local procedure MonWedFri() Weekdays: List of [Integer]
    begin
        Weekdays.Add(1);
        Weekdays.Add(3);
        Weekdays.Add(5);
    end;

    local procedure SingleWeekday(WeekdayNo: Integer) Weekdays: List of [Integer]
    begin
        Weekdays.Add(WeekdayNo);
    end;

    local procedure AddRandomWeekdaySet(var Weekdays: List of [Integer]; Any: Codeunit Any)
    var
        SetSize: Integer;
        CandidateDay: Integer;
    begin
        SetSize := Any.IntegerInRange(2, 4);
        while Weekdays.Count() < SetSize do begin
            CandidateDay := Any.IntegerInRange(1, 7);
            if not Weekdays.Contains(CandidateDay) then
                Weekdays.Add(CandidateDay);
        end;
    end;

    local procedure WeekdaysText(Weekdays: List of [Integer]): Text
    var
        WeekdayNo: Integer;
        Result: TextBuilder;
    begin
        foreach WeekdayNo in Weekdays do begin
            if Result.Length() > 0 then
                Result.Append(', ');
            Result.Append(Format(WeekdayNo));
        end;
        exit(Result.ToText());
    end;

    local procedure AssertOccurrenceList(Expected: List of [DateTime]; Actual: List of [DateTime]; ScheduleText: Text)
    var
        Assert: Codeunit Assert;
        Index: Integer;
    begin
        Assert.AreEqual(Expected.Count(), Actual.Count(),
            StrSubstNo('Expected %1 occurrences from %2', Expected.Count(), ScheduleText));
        for Index := 1 to Expected.Count() do
            Assert.AreEqual(Expected.Get(Index), Actual.Get(Index),
                StrSubstNo('Expected occurrence %1 of %2 from %3', Index, Expected.Count(), ScheduleText));
    end;
}
