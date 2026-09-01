codeunit 50900 "Working Days Tests"
{
    // [FEATURE] [Working Days Calculator]
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsEveryWorkingDayOfAStandardWeek()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A full Monday-to-Friday range with a Saturday-Sunday weekend counts all five days
        Assert.AreEqual(5,
            Calculator.WorkingDaysBetween(DMY2Date(6, 7, 2026), DMY2Date(10, 7, 2026), SatSunWeekend(), Holidays),
            'Expected Monday 6 July 2026 through Friday 10 July 2026 to count 5 working days with a Saturday-Sunday weekend and no holidays — both endpoints are included');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekendDaysInsideTheRangeAreSkipped()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A Friday-to-Monday range crossing a Saturday-Sunday weekend counts only Friday and Monday
        Assert.AreEqual(2,
            Calculator.WorkingDaysBetween(DMY2Date(10, 7, 2026), DMY2Date(13, 7, 2026), SatSunWeekend(), Holidays),
            'Expected Friday 10 July 2026 through Monday 13 July 2026 to count 2 working days — Saturday and Sunday are weekend days');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleWorkingDayRangeCountsOne()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A range of one working day counts exactly that day
        Assert.AreEqual(1,
            Calculator.WorkingDaysBetween(DMY2Date(8, 7, 2026), DMY2Date(8, 7, 2026), SatSunWeekend(), Holidays),
            'Expected the single-day range on Wednesday 8 July 2026 to count 1 working day — a range where FromDate equals ToDate contains that one day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleWeekendDayRangeCountsZero()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A range of one weekend day counts nothing
        Assert.AreEqual(0,
            Calculator.WorkingDaysBetween(DMY2Date(11, 7, 2026), DMY2Date(11, 7, 2026), SatSunWeekend(), Holidays),
            'Expected the single-day range on Saturday 11 July 2026 to count 0 working days with a Saturday-Sunday weekend');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomWeekendPatternIsRespected()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        WeekendDays: List of [Integer];
        Holidays: List of [Date];
    begin
        // [SCENARIO] With a Friday-Saturday weekend, Thursday-to-Sunday counts Thursday and Sunday
        WeekendDays.Add(5);
        WeekendDays.Add(6);

        Assert.AreEqual(2,
            Calculator.WorkingDaysBetween(DMY2Date(9, 7, 2026), DMY2Date(12, 7, 2026), WeekendDays, Holidays),
            'Expected Thursday 9 July 2026 through Sunday 12 July 2026 to count 2 working days with a Friday-Saturday weekend — the weekend pattern comes from the WeekendDays parameter, not from Saturday-Sunday');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HolidayInsideTheRangeIsSubtracted()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A holiday on a weekday inside the range removes that day from the count
        Holidays.Add(DMY2Date(8, 7, 2026));

        Assert.AreEqual(4,
            Calculator.WorkingDaysBetween(DMY2Date(6, 7, 2026), DMY2Date(10, 7, 2026), SatSunWeekend(), Holidays),
            'Expected the Monday-to-Friday week to count 4 working days when Wednesday 8 July 2026 is a holiday');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DuplicateHolidayIsSubtractedOnce()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] The same holiday listed twice removes its day from the count only once
        Holidays.Add(DMY2Date(8, 7, 2026));
        Holidays.Add(DMY2Date(8, 7, 2026));

        Assert.AreEqual(4,
            Calculator.WorkingDaysBetween(DMY2Date(6, 7, 2026), DMY2Date(10, 7, 2026), SatSunWeekend(), Holidays),
            'Expected the Monday-to-Friday week to count 4 working days when Wednesday 8 July 2026 appears twice in the holiday list — a duplicate entry must not be subtracted twice');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HolidayOnAWeekendChangesNothing()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A holiday falling on a Saturday does not reduce the count
        Holidays.Add(DMY2Date(11, 7, 2026));

        Assert.AreEqual(5,
            Calculator.WorkingDaysBetween(DMY2Date(6, 7, 2026), DMY2Date(12, 7, 2026), SatSunWeekend(), Holidays),
            'Expected Monday 6 July 2026 through Sunday 12 July 2026 to count 5 working days when the holiday falls on Saturday 11 July — a weekend day was never a working day, so the holiday must not be subtracted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HolidayOutsideTheRangeIsIgnored()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A holiday after ToDate does not reduce the count
        Holidays.Add(DMY2Date(13, 7, 2026));

        Assert.AreEqual(5,
            Calculator.WorkingDaysBetween(DMY2Date(6, 7, 2026), DMY2Date(10, 7, 2026), SatSunWeekend(), Holidays),
            'Expected the Monday-to-Friday week to count 5 working days when the only holiday, Monday 13 July 2026, lies outside the range');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyWeekendPatternCountsEveryNonHolidayDay()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        WeekendDays: List of [Integer];
        Holidays: List of [Date];
    begin
        // [SCENARIO] With no weekend days, only holidays reduce the count
        Holidays.Add(DMY2Date(8, 7, 2026));

        Assert.AreEqual(6,
            Calculator.WorkingDaysBetween(DMY2Date(6, 7, 2026), DMY2Date(12, 7, 2026), WeekendDays, Holidays),
            'Expected the 7-day range from Monday 6 July 2026 with an empty weekend list to count 6 working days — every day works except the Wednesday holiday');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndDateBeforeStartDateRaisesAnError()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A range whose end is earlier than its start is rejected
        asserterror Calculator.WorkingDaysBetween(DMY2Date(10, 7, 2026), DMY2Date(6, 7, 2026), SatSunWeekend(), Holidays);

        Assert.ExpectedError('must not be before');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomRangeMatchesADayByDayCount()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        WeekendDays: List of [Integer];
        Holidays: List of [Date];
        FromDate: Date;
        ToDate: Date;
    begin
        // [SCENARIO] A randomized range, weekend pattern and holiday list match an independent day-by-day count
        FromDate := Any.DateInRange(DMY2Date(1, 1, 2026), 1, 300);
        ToDate := FromDate + Any.IntegerInRange(10, 40);
        AddRandomWeekendPattern(WeekendDays, Any);
        Holidays.Add(FromDate + Any.IntegerInRange(0, 5));
        Holidays.Add(FromDate + Any.IntegerInRange(6, 10));

        Assert.AreEqual(CountByCalendarWalk(FromDate, ToDate, WeekendDays, Holidays),
            Calculator.WorkingDaysBetween(FromDate, ToDate, WeekendDays, Holidays),
            StrSubstNo('Expected the working-day count from %1 to %2 with weekend days %3 and holidays on %4 and %5 to match a day-by-day walk over the calendar', FromDate, ToDate, WeekendDaysText(WeekendDays), Holidays.Get(1), Holidays.Get(2)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PromiseSkipsTheWeekend()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] One working day of lead time on a Friday order promises Monday
        Assert.AreEqual(DMY2Date(13, 7, 2026),
            Calculator.PromiseShipmentDate(DMY2Date(10, 7, 2026), 1, SatSunWeekend(), Holidays),
            'Expected an order placed on Friday 10 July 2026 with 1 working day of lead time to promise Monday 13 July 2026 — Saturday and Sunday do not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderDateItselfNeverCounts()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A lead time of 1 on a working Monday promises Tuesday, not Monday
        Assert.AreEqual(DMY2Date(7, 7, 2026),
            Calculator.PromiseShipmentDate(DMY2Date(6, 7, 2026), 1, SatSunWeekend(), Holidays),
            'Expected an order placed on Monday 6 July 2026 with 1 working day of lead time to promise Tuesday 7 July 2026 — the order date itself never counts, even when it is a working day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PromiseStepsOverAHolidayRun()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] Three working days from Monday step over a Wednesday-Thursday holiday run and the weekend
        Holidays.Add(DMY2Date(8, 7, 2026));
        Holidays.Add(DMY2Date(9, 7, 2026));

        Assert.AreEqual(DMY2Date(13, 7, 2026),
            Calculator.PromiseShipmentDate(DMY2Date(6, 7, 2026), 3, SatSunWeekend(), Holidays),
            'Expected an order placed on Monday 6 July 2026 with 3 working days of lead time to promise Monday 13 July 2026 — Tuesday and Friday count, the Wednesday-Thursday holidays and the weekend do not');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PromiseRespectsACustomWeekend()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        WeekendDays: List of [Integer];
        Holidays: List of [Date];
    begin
        // [SCENARIO] With a Friday-Saturday weekend, one working day after Thursday is Sunday
        WeekendDays.Add(5);
        WeekendDays.Add(6);

        Assert.AreEqual(DMY2Date(12, 7, 2026),
            Calculator.PromiseShipmentDate(DMY2Date(9, 7, 2026), 1, WeekendDays, Holidays),
            'Expected an order placed on Thursday 9 July 2026 with 1 working day of lead time and a Friday-Saturday weekend to promise Sunday 12 July 2026 — Sunday is a working day under this pattern');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroLeadTimeRaisesAnError()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A lead time below 1 is rejected
        asserterror Calculator.PromiseShipmentDate(DMY2Date(6, 7, 2026), 0, SatSunWeekend(), Holidays);

        Assert.ExpectedError('at least one working day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeLeadTimeRaisesAnError()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Holidays: List of [Date];
    begin
        // [SCENARIO] A negative lead time is rejected just like zero
        asserterror Calculator.PromiseShipmentDate(DMY2Date(6, 7, 2026), -Any.IntegerInRange(1, 10), SatSunWeekend(), Holidays);

        Assert.ExpectedError('at least one working day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomPromiseMatchesACalendarWalk()
    var
        Calculator: Codeunit "Working Days Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        WeekendDays: List of [Integer];
        Holidays: List of [Date];
        OrderDate: Date;
        ExpectedDate: Date;
        LeadTime: Integer;
        CountedWorkingDays: Integer;
    begin
        // [SCENARIO] A randomized order date, lead time, weekend pattern and holiday match an independent calendar walk
        OrderDate := Any.DateInRange(DMY2Date(1, 1, 2026), 1, 300);
        LeadTime := Any.IntegerInRange(2, 15);
        AddRandomWeekendPattern(WeekendDays, Any);
        Holidays.Add(OrderDate + Any.IntegerInRange(1, 4));

        ExpectedDate := OrderDate;
        while CountedWorkingDays < LeadTime do begin
            ExpectedDate += 1;
            if IsWorkingDayInTest(ExpectedDate, WeekendDays, Holidays) then
                CountedWorkingDays += 1;
        end;

        Assert.AreEqual(ExpectedDate,
            Calculator.PromiseShipmentDate(OrderDate, LeadTime, WeekendDays, Holidays),
            StrSubstNo('Expected the promise for an order on %1 with %2 working days of lead time, weekend days %3 and a holiday on %4 to match a day-by-day walk over the calendar', OrderDate, LeadTime, WeekendDaysText(WeekendDays), Holidays.Get(1)));
    end;

    local procedure SatSunWeekend() WeekendDays: List of [Integer]
    begin
        WeekendDays.Add(6);
        WeekendDays.Add(7);
    end;

    local procedure AddRandomWeekendPattern(var WeekendDays: List of [Integer]; Any: Codeunit Any)
    var
        WeekendSize: Integer;
        CandidateDay: Integer;
    begin
        // A size of at most 5 always leaves a working weekday, as task.md promises
        WeekendSize := Any.IntegerInRange(2, 5);
        while WeekendDays.Count() < WeekendSize do begin
            CandidateDay := Any.IntegerInRange(1, 7);
            if not WeekendDays.Contains(CandidateDay) then
                WeekendDays.Add(CandidateDay);
        end;
    end;

    local procedure WeekendDaysText(WeekendDays: List of [Integer]): Text
    var
        WeekendDay: Integer;
        Result: TextBuilder;
    begin
        foreach WeekendDay in WeekendDays do begin
            if Result.Length() > 0 then
                Result.Append(', ');
            Result.Append(Format(WeekendDay));
        end;
        exit(Result.ToText());
    end;

    local procedure CountByCalendarWalk(FromDate: Date; ToDate: Date; WeekendDays: List of [Integer]; Holidays: List of [Date]): Integer
    var
        CurrentDate: Date;
        WorkingDayCount: Integer;
    begin
        CurrentDate := FromDate;
        while CurrentDate <= ToDate do begin
            if IsWorkingDayInTest(CurrentDate, WeekendDays, Holidays) then
                WorkingDayCount += 1;
            CurrentDate += 1;
        end;
        exit(WorkingDayCount);
    end;

    local procedure IsWorkingDayInTest(TheDate: Date; WeekendDays: List of [Integer]; Holidays: List of [Date]): Boolean
    begin
        exit(not WeekendDays.Contains(Date2DWY(TheDate, 1)) and not Holidays.Contains(TheDate));
    end;
}
