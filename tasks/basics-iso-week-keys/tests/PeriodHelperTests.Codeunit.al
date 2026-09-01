codeunit 50900 "Period Helper Tests"
{
    // [FEATURE] [Period Helper]
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekKeyOfAMidYearDate()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A date in an ordinary week gets a four-digit year and a two-digit week
        Assert.AreEqual('2024-W24', PeriodHelper.IsoWeekKey(DMY2Date(12, 6, 2024)),
            'Expected Wednesday 12 June 2024 to carry the key 2024-W24 — four-digit year, hyphen, capital W, two-digit week');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekKeyOfJanuary1st2021IsWeek53Of2020()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The first days of January belong to the last ISO week of the previous year
        Assert.AreEqual('2020-W53', PeriodHelper.IsoWeekKey(DMY2Date(1, 1, 2021)),
            'Expected Friday 1 January 2021 to carry the key 2020-W53 — it sits in the last ISO week of 2020, so the key uses the week-numbering year, not the calendar year of the date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekKeyOfDecember29th2025IsWeek1Of2026()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The last days of December belong to week 1 of the next year
        Assert.AreEqual('2026-W01', PeriodHelper.IsoWeekKey(DMY2Date(29, 12, 2025)),
            'Expected Monday 29 December 2025 to carry the key 2026-W01 — it starts the ISO week that contains 1 January 2026, so the key uses 2026 and a zero-padded week 01');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekKeyZeroPadsTheWeekNumber()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A single-digit week number is written with a leading zero
        Assert.AreEqual('2026-W08', PeriodHelper.IsoWeekKey(DMY2Date(18, 2, 2026)),
            'Expected Wednesday 18 February 2026 to carry the key 2026-W08 — the week number is always two digits, so week 8 is written 08');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDateWeekKeyMatchesTheThursdayRule()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
        ThursdayOfWeek: Date;
        IsoYear: Integer;
        WeekNo: Integer;
    begin
        // [SCENARIO] A generated date matches the ISO rule: a week belongs to the year its Thursday falls in
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2000), 1, 12000);
        ThursdayOfWeek := TheDate + (4 - Date2DWY(TheDate, 1));
        IsoYear := Date2DMY(ThursdayOfWeek, 3);
        WeekNo := (ThursdayOfWeek - DMY2Date(1, 1, IsoYear)) div 7 + 1;

        Assert.AreEqual(StrSubstNo('%1-W%2', IsoYear, TwoDigits(WeekNo)), PeriodHelper.IsoWeekKey(TheDate),
            StrSubstNo('Expected %1 to carry the key of the ISO week whose Thursday is %2 — year %3, week %4', TheDate, ThursdayOfWeek, IsoYear, WeekNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SundayWeekMondayIsSixDaysBack()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A Sunday is the last day of its week, so its Monday is six days earlier
        Assert.AreEqual(DMY2Date(2, 3, 2026), PeriodHelper.WeekMonday(DMY2Date(8, 3, 2026)),
            'Expected the week of Sunday 8 March 2026 to start on Monday 2 March 2026 — weeks run Monday to Sunday, so the Monday of a Sunday is six days back');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MondayWeekMondayIsTheDateItself()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A Monday starts its own week
        Assert.AreEqual(DMY2Date(6, 7, 2026), PeriodHelper.WeekMonday(DMY2Date(6, 7, 2026)),
            'Expected Monday 6 July 2026 to be returned unchanged — a Monday starts its own week');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekMondayOfJanuary1st2021IsInDecember2020()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The Monday of a week that straddles New Year lies in the previous year
        Assert.AreEqual(DMY2Date(28, 12, 2020), PeriodHelper.WeekMonday(DMY2Date(1, 1, 2021)),
            'Expected the week of Friday 1 January 2021 to start on Monday 28 December 2020 — rebuilding the Monday from week 53 of calendar year 2021 lands in the wrong year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekMondayOfDecember31st2025StartsWeek1Of2026()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A late-December date in ISO week 1 keeps its December Monday
        Assert.AreEqual(DMY2Date(29, 12, 2025), PeriodHelper.WeekMonday(DMY2Date(31, 12, 2025)),
            'Expected the week of Wednesday 31 December 2025 to start on Monday 29 December 2025 — rebuilding the Monday from week 1 of calendar year 2025 lands a whole year early');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDateWeekMondayIsTheMondayOnOrBefore()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
    begin
        // [SCENARIO] A generated date's Monday is the date moved back by its weekday number minus one
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2000), 1, 12000);

        Assert.AreEqual(TheDate - (Date2DWY(TheDate, 1) - 1), PeriodHelper.WeekMonday(TheDate),
            StrSubstNo('Expected the Monday of the week containing %1 (weekday %2) — the date moved back by weekday minus one days', TheDate, Date2DWY(TheDate, 1)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndOfMonthInLeapYearFebruaryIsThe29th()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] February 2024 ends on the 29th
        Assert.AreEqual(DMY2Date(29, 2, 2024), PeriodHelper.EndOfMonth(DMY2Date(10, 2, 2024)),
            'Expected February 2024 to end on 29 February 2024 — 2024 is a leap year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndOfMonthInCommonYearFebruaryIsThe28th()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] February 2023 ends on the 28th
        Assert.AreEqual(DMY2Date(28, 2, 2023), PeriodHelper.EndOfMonth(DMY2Date(10, 2, 2023)),
            'Expected February 2023 to end on 28 February 2023 — 2023 is a common year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndOfMonthInDecemberStaysInTheSameYear()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] December's month end is 31 December of the same year
        Assert.AreEqual(DMY2Date(31, 12, 2026), PeriodHelper.EndOfMonth(DMY2Date(15, 12, 2026)),
            'Expected December 2026 to end on 31 December 2026 — there is no month 13 to step into');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndOfMonthOfTheLastDayIsTheDateItself()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The last day of a month maps to itself
        Assert.AreEqual(DMY2Date(30, 4, 2026), PeriodHelper.EndOfMonth(DMY2Date(30, 4, 2026)),
            'Expected 30 April 2026, already the last day of its month, to be returned unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDateEndOfMonthIsTheLastDayOfItsMonth()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
        ExpectedDate: Date;
    begin
        // [SCENARIO] A generated date's month end matches a day-by-day walk to the last day of that month
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2000), 1, 12000);
        ExpectedDate := TheDate;
        while Date2DMY(ExpectedDate + 1, 2) = Date2DMY(TheDate, 2) do
            ExpectedDate += 1;

        Assert.AreEqual(ExpectedDate, PeriodHelper.EndOfMonth(TheDate),
            StrSubstNo('Expected the month end of %1 to be %2 — the last date before the month number changes', TheDate, ExpectedDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysInLeapYearFebruaryIs29()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] February 2024 has 29 days
        Assert.AreEqual(29, PeriodHelper.DaysInMonth(DMY2Date(1, 2, 2024)),
            'Expected February 2024 to have 29 days — 2024 is a leap year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysInCenturyYearFebruaryIs28()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] February 2100 has 28 days: divisible by 4 but a century year not divisible by 400
        Assert.AreEqual(28, PeriodHelper.DaysInMonth(DMY2Date(15, 2, 2100)),
            'Expected February 2100 to have 28 days — 2100 is divisible by 4 but, as a century year not divisible by 400, is NOT a leap year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDateDaysInMonthMatchesADayWalk()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
        Cursor: Date;
        DayCount: Integer;
    begin
        // [SCENARIO] A generated date's month length matches counting its days one by one
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2000), 1, 12000);
        Cursor := DMY2Date(1, Date2DMY(TheDate, 2), Date2DMY(TheDate, 3));
        while Date2DMY(Cursor, 2) = Date2DMY(TheDate, 2) do begin
            DayCount += 1;
            Cursor += 1;
        end;

        Assert.AreEqual(DayCount, PeriodHelper.DaysInMonth(TheDate),
            StrSubstNo('Expected the month of %1 to have %2 days, counted one by one', TheDate, DayCount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure Year2024IsALeapYear()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A year divisible by 4 is a leap year
        Assert.IsTrue(PeriodHelper.IsLeapYear(2024),
            'Expected 2024 to be a leap year — it is divisible by 4 and is not a century year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure Year2023IsNotALeapYear()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A year not divisible by 4 is a common year
        Assert.IsFalse(PeriodHelper.IsLeapYear(2023),
            'Expected 2023 not to be a leap year — it is not divisible by 4');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure Year1900IsNotALeapYear()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A century year not divisible by 400 is a common year
        Assert.IsFalse(PeriodHelper.IsLeapYear(1900),
            'Expected 1900 not to be a leap year — century years are leap years only when divisible by 400, and a plain "divisible by 4" rule gets this wrong');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure Year2000IsALeapYear()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A century year divisible by 400 is a leap year
        Assert.IsTrue(PeriodHelper.IsLeapYear(2000),
            'Expected 2000 to be a leap year — it is a century year divisible by 400, so the century exception does not apply');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomYearLeapFlagMatchesFebruaryLength()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Year: Integer;
        FebruaryDays: Integer;
    begin
        // [SCENARIO] A generated year is leap exactly when the platform's calendar gives its February 29 days
        Year := Any.IntegerInRange(1800, 2400);
        FebruaryDays := DMY2Date(1, 3, Year) - DMY2Date(1, 2, Year);

        Assert.AreEqual(FebruaryDays = 29, PeriodHelper.IsLeapYear(Year),
            StrSubstNo('Expected the leap flag of %1 to match its February length of %2 days', Year, FebruaryDays));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuarterOfMarch31stIsOne()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The last day of March is still in the first quarter
        Assert.AreEqual(1, PeriodHelper.QuarterOf(DMY2Date(31, 3, 2026)),
            'Expected 31 March 2026 to be in quarter 1 — March is the last month of the first quarter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuarterOfApril1stIsTwo()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The first day of April opens the second quarter
        Assert.AreEqual(2, PeriodHelper.QuarterOf(DMY2Date(1, 4, 2026)),
            'Expected 1 April 2026 to be in quarter 2 — April is the first month of the second quarter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuarterOfADecemberDateIsFour()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] December is in the fourth quarter
        Assert.AreEqual(4, PeriodHelper.QuarterOf(DMY2Date(31, 12, 2026)),
            'Expected 31 December 2026 to be in quarter 4 — October to December form the fourth quarter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDateQuarterMatchesItsMonth()
    var
        PeriodHelper: Codeunit "Period Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TheDate: Date;
        ExpectedQuarter: Integer;
    begin
        // [SCENARIO] A generated date's quarter follows the month it falls in
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2000), 1, 12000);
        case Date2DMY(TheDate, 2) of
            1 .. 3:
                ExpectedQuarter := 1;
            4 .. 6:
                ExpectedQuarter := 2;
            7 .. 9:
                ExpectedQuarter := 3;
            else
                ExpectedQuarter := 4;
        end;

        Assert.AreEqual(ExpectedQuarter, PeriodHelper.QuarterOf(TheDate),
            StrSubstNo('Expected %1 (month %2) to be in quarter %3', TheDate, Date2DMY(TheDate, 2), ExpectedQuarter));
    end;

    local procedure TwoDigits(Value: Integer): Text
    begin
        if Value < 10 then
            exit('0' + Format(Value));
        exit(Format(Value));
    end;
}
