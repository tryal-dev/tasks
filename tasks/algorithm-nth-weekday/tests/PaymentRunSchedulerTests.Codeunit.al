codeunit 50900 "Payment Run Scheduler Tests"
{
    // [FEATURE] [Payment Run Scheduler]
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstOccurrenceOnTheMonthsFirstDay()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The first Tuesday of a month that starts on a Tuesday is the 1st
        Assert.AreEqual(DMY2Date(1, 9, 2026),
            Scheduler.NthWeekdayOfMonth(2026, 9, 2, 1),
            'Expected the first Tuesday of September 2026 to be Tuesday 1 September 2026 — occurrence 1 may be the 1st of the month itself');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondTuesdayOfAnOrdinaryMonth()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The second Tuesday of July 2026 is the 14th
        Assert.AreEqual(DMY2Date(14, 7, 2026),
            Scheduler.NthWeekdayOfMonth(2026, 7, 2, 2),
            'Expected the second Tuesday of July 2026 to be Tuesday 14 July 2026 — the first Tuesday is the 7th and the second is one week later');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FifthFridayWhenTheMonthHasFive()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] July 2026 has five Fridays and the fifth is the 31st
        Assert.AreEqual(DMY2Date(31, 7, 2026),
            Scheduler.NthWeekdayOfMonth(2026, 7, 5, 5),
            'Expected the fifth Friday of July 2026 to be Friday 31 July 2026 — the Fridays fall on the 3rd, 10th, 17th, 24th and 31st');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingFifthWeekdayRaisesAnError()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Asking for the fifth Monday of a month with only four is rejected
        asserterror Scheduler.NthWeekdayOfMonth(2026, 7, 1, 5);

        Assert.ExpectedError('no fifth');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomNthWeekdayMatchesACalendarWalk()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Year: Integer;
        Month: Integer;
        WeekdayNumber: Integer;
        Occurrence: Integer;
    begin
        // [SCENARIO] A randomized year, month, weekday and occurrence match an independent day-by-day walk
        Year := Any.IntegerInRange(2020, 2030);
        Month := Any.IntegerInRange(1, 12);
        WeekdayNumber := Any.IntegerInRange(1, 7);
        Occurrence := Any.IntegerInRange(1, 4);

        Assert.AreEqual(NthWeekdayByCalendarWalk(Year, Month, WeekdayNumber, Occurrence),
            Scheduler.NthWeekdayOfMonth(Year, Month, WeekdayNumber, Occurrence),
            StrSubstNo('Expected occurrence %1 of weekday %2 in month %3 of year %4 to match a day-by-day walk over that month', Occurrence, WeekdayNumber, Month, Year));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LastWeekdayWhenTheMonthHasFive()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The last Friday of a five-Friday month is the fifth one
        Assert.AreEqual(DMY2Date(31, 7, 2026),
            Scheduler.LastWeekdayOfMonth(2026, 7, 5),
            'Expected the last Friday of July 2026 to be Friday 31 July 2026 — the month has five Fridays, so the last one is the fifth, not the fourth');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LastWeekdayWhenTheMonthHasFour()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The last Monday of a four-Monday month is the fourth one
        Assert.AreEqual(DMY2Date(27, 7, 2026),
            Scheduler.LastWeekdayOfMonth(2026, 7, 1),
            'Expected the last Monday of July 2026 to be Monday 27 July 2026 — the Mondays fall on the 6th, 13th, 20th and 27th');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LastWeekdayOfLeapYearFebruary()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] In the leap year 2028 the last Tuesday of February is the 29th
        Assert.AreEqual(DMY2Date(29, 2, 2028),
            Scheduler.LastWeekdayOfMonth(2028, 2, 2),
            'Expected the last Tuesday of February 2028 to be Tuesday 29 February 2028 — 2028 is a leap year, so February runs to the 29th');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LastWeekdayOfCommonYearFebruary()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] In the common year 2027 the last Sunday of February is the 28th
        Assert.AreEqual(DMY2Date(28, 2, 2027),
            Scheduler.LastWeekdayOfMonth(2027, 2, 7),
            'Expected the last Sunday of February 2027 to be Sunday 28 February 2027 — 2027 is not a leap year, so February ends on the 28th');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WorkdayStartingDateStaysPut()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A Wednesday 15th is already a workday and is returned unchanged
        Assert.AreEqual(DMY2Date(15, 7, 2026),
            Scheduler.FirstWorkdayOnOrAfter(DMY2Date(15, 7, 2026)),
            'Expected Wednesday 15 July 2026 to be returned unchanged — a starting date that is already a workday must not be moved');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FridayStartingDateStaysPut()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A Friday is a workday and is returned unchanged
        Assert.AreEqual(DMY2Date(17, 7, 2026),
            Scheduler.FirstWorkdayOnOrAfter(DMY2Date(17, 7, 2026)),
            'Expected Friday 17 July 2026 to be returned unchanged — Friday is a workday, only Saturday and Sunday are not');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SaturdayFifteenthRollsToMonday()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A Saturday 15th rolls forward over the weekend to Monday the 17th
        Assert.AreEqual(DMY2Date(17, 8, 2026),
            Scheduler.FirstWorkdayOnOrAfter(DMY2Date(15, 8, 2026)),
            'Expected Saturday 15 August 2026 to roll to Monday 17 August 2026 — Saturday and Sunday are not workdays');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SundayMonthEndRollsIntoTheNextMonth()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Sunday 31 August rolls into September
        Assert.AreEqual(DMY2Date(1, 9, 2025),
            Scheduler.FirstWorkdayOnOrAfter(DMY2Date(31, 8, 2025)),
            'Expected Sunday 31 August 2025 to roll to Monday 1 September 2025 — the first workday may fall in the next month');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure YearEndSundayRollsIntoJanuary()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Sunday 31 December rolls into the next year
        Assert.AreEqual(DMY2Date(1, 1, 2029),
            Scheduler.FirstWorkdayOnOrAfter(DMY2Date(31, 12, 2028)),
            'Expected Sunday 31 December 2028 to roll to Monday 1 January 2029 — the first workday may fall in the next year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunDatesCrossTheYearBoundary()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
        RunDates: List of [Date];
    begin
        // [SCENARIO] Four months of second Tuesdays starting November 2026 continue into 2027
        RunDates := Scheduler.PaymentRunDates(2026, 11, 4, 2, 2);

        Assert.AreEqual(4, RunDates.Count(),
            'Expected a 4-month payment run starting November 2026 to produce exactly 4 run dates — one per month');
        Assert.AreEqual(DMY2Date(10, 11, 2026), RunDates.Get(1),
            'Expected the first run date to be the second Tuesday of November 2026, Tuesday 10 November 2026');
        Assert.AreEqual(DMY2Date(8, 12, 2026), RunDates.Get(2),
            'Expected the second run date to be the second Tuesday of December 2026, Tuesday 8 December 2026');
        Assert.AreEqual(DMY2Date(12, 1, 2027), RunDates.Get(3),
            'Expected the third run date to be the second Tuesday of January 2027, Tuesday 12 January 2027 — after December the schedule continues into the next year');
        Assert.AreEqual(DMY2Date(9, 2, 2027), RunDates.Get(4),
            'Expected the fourth run date to be the second Tuesday of February 2027, Tuesday 9 February 2027');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleMonthRunHasExactlyOneDate()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
        RunDates: List of [Date];
    begin
        // [SCENARIO] A one-month schedule holds exactly the third Wednesday of that month
        RunDates := Scheduler.PaymentRunDates(2027, 3, 1, 3, 3);

        Assert.AreEqual(1, RunDates.Count(),
            'Expected a 1-month payment run to produce exactly 1 run date');
        Assert.AreEqual(DMY2Date(17, 3, 2027), RunDates.Get(1),
            'Expected the single run date to be the third Wednesday of March 2027, Wednesday 17 March 2027');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroMonthCountRaisesAnError()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A schedule over zero months is rejected
        asserterror Scheduler.PaymentRunDates(2026, 7, 0, 2, 2);

        Assert.ExpectedError('at least one month');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeMonthCountRaisesAnError()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A negative month count is rejected just like zero
        asserterror Scheduler.PaymentRunDates(2026, 7, -Any.IntegerInRange(1, 10), 2, 2);

        Assert.ExpectedError('at least one month');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomRunDatesMatchPerMonthWalks()
    var
        Scheduler: Codeunit "Payment Run Scheduler";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        RunDates: List of [Date];
        StartYear: Integer;
        StartMonth: Integer;
        MonthCount: Integer;
        WeekdayNumber: Integer;
        Occurrence: Integer;
        CurrentYear: Integer;
        CurrentMonth: Integer;
        MonthIndex: Integer;
    begin
        // [SCENARIO] A randomized schedule matches an independent per-month day-by-day walk
        StartYear := Any.IntegerInRange(2021, 2029);
        StartMonth := Any.IntegerInRange(1, 12);
        MonthCount := Any.IntegerInRange(3, 8);
        WeekdayNumber := Any.IntegerInRange(1, 7);
        Occurrence := Any.IntegerInRange(1, 4);

        RunDates := Scheduler.PaymentRunDates(StartYear, StartMonth, MonthCount, WeekdayNumber, Occurrence);

        Assert.AreEqual(MonthCount, RunDates.Count(),
            StrSubstNo('Expected one run date per month for a %1-month schedule starting in month %2 of year %3', MonthCount, StartMonth, StartYear));
        CurrentYear := StartYear;
        CurrentMonth := StartMonth;
        for MonthIndex := 1 to MonthCount do begin
            Assert.AreEqual(NthWeekdayByCalendarWalk(CurrentYear, CurrentMonth, WeekdayNumber, Occurrence), RunDates.Get(MonthIndex),
                StrSubstNo('Expected run date %1 of the schedule to be occurrence %2 of weekday %3 in month %4 of year %5, matching a day-by-day walk over that month', MonthIndex, Occurrence, WeekdayNumber, CurrentMonth, CurrentYear));
            CurrentMonth += 1;
            if CurrentMonth > 12 then begin
                CurrentMonth := 1;
                CurrentYear += 1;
            end;
        end;
    end;

    local procedure NthWeekdayByCalendarWalk(Year: Integer; Month: Integer; WeekdayNumber: Integer; Occurrence: Integer): Date
    var
        CurrentDate: Date;
        MatchCount: Integer;
    begin
        CurrentDate := DMY2Date(1, Month, Year);
        while Date2DMY(CurrentDate, 2) = Month do begin
            if Date2DWY(CurrentDate, 1) = WeekdayNumber then begin
                MatchCount += 1;
                if MatchCount = Occurrence then
                    exit(CurrentDate);
            end;
            CurrentDate += 1;
        end;
    end;
}
