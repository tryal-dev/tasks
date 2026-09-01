codeunit 50900 "Fiscal Period Mapper Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JanuaryStartMapsJuneToPeriodSix()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(6, FiscalPeriodMapper.GetPeriodNo(1, DMY2Date(15, 6, 2025)),
            'Expected June to be period 6 when the fiscal year starts in January — periods then match calendar months');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstDayOfTheStartMonthIsPeriodOne()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(1, FiscalPeriodMapper.GetPeriodNo(4, DMY2Date(1, 4, 2026)),
            'Expected 2026-04-01 to be period 1 of an April-start fiscal year — the start month itself is period 1, not 0 or 12');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthRightBeforeTheStartMonthIsPeriodTwelve()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(12, FiscalPeriodMapper.GetPeriodNo(4, DMY2Date(31, 3, 2026)),
            'Expected 2026-03-31 to be period 12 of an April-start fiscal year — March is the last month before the year wraps');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthsAfterTheCalendarYearEndKeepCounting()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(10, FiscalPeriodMapper.GetPeriodNo(4, DMY2Date(15, 1, 2026)),
            'Expected January to be period 10 of an April-start fiscal year — the numbering continues past December 31');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeapDayBelongsToItsPeriodLikeAnyFebruaryDate()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(8, FiscalPeriodMapper.GetPeriodNo(7, DMY2Date(29, 2, 2024)),
            'Expected February 29 2024 to be period 8 of a July-start fiscal year — a leap day maps like any other February date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstDayOfTheFiscalYearStartsItsOwnYear()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(DMY2Date(1, 10, 2025), FiscalPeriodMapper.GetFiscalYearStartDate(10, DMY2Date(1, 10, 2025)),
            'Expected the first day of an October-start fiscal year to be the start of its own fiscal year, not of the previous one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DateAfterTheStartMonthUsesThisYearsStart()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(DMY2Date(1, 10, 2025), FiscalPeriodMapper.GetFiscalYearStartDate(10, DMY2Date(24, 12, 2025)),
            'Expected 2025-12-24 to belong to the fiscal year that began 2025-10-01 — December is on or after the October start month');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DateBeforeTheStartMonthUsesLastYearsStart()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(DMY2Date(1, 10, 2025), FiscalPeriodMapper.GetFiscalYearStartDate(10, DMY2Date(30, 9, 2026)),
            'Expected 2026-09-30, the very last day of the fiscal year, to belong to the fiscal year that began 2025-10-01');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MarchStartEndsOnLeapDayInALeapYear()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(DMY2Date(29, 2, 2024), FiscalPeriodMapper.GetFiscalYearEndDate(3, DMY2Date(15, 7, 2023)),
            'Expected the March-start fiscal year containing 2023-07-15 to end on 2024-02-29 — 2024 is a leap year, so February has 29 days');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MarchStartEndsOnFebruary28InACommonYear()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(DMY2Date(28, 2, 2022), FiscalPeriodMapper.GetFiscalYearEndDate(3, DMY2Date(15, 7, 2021)),
            'Expected the March-start fiscal year containing 2021-07-15 to end on 2022-02-28 — 2022 is a common year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CenturyYear2100IsNotALeapYear()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(DMY2Date(28, 2, 2100), FiscalPeriodMapper.GetFiscalYearEndDate(3, DMY2Date(1, 6, 2099)),
            'Expected the March-start fiscal year containing 2099-06-01 to end on 2100-02-28 — 2100 is divisible by 4 but is NOT a leap year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDateFallsInTheComputedPeriod()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartMonth: Integer;
        TheDate: Date;
        ExpectedPeriodNo: Integer;
    begin
        StartMonth := Any.IntegerInRange(1, 12);
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2018), 1, 4000);

        ExpectedPeriodNo := Date2DMY(TheDate, 2) - StartMonth + 1;
        if ExpectedPeriodNo <= 0 then
            ExpectedPeriodNo += 12;

        Assert.AreEqual(ExpectedPeriodNo, FiscalPeriodMapper.GetPeriodNo(StartMonth, TheDate),
            StrSubstNo('Expected %1 to fall in period %2 of a fiscal year starting in month %3', TheDate, ExpectedPeriodNo, StartMonth));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDateFiscalYearStartsOnDayOneOfTheStartMonth()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartMonth: Integer;
        TheDate: Date;
        StartYear: Integer;
    begin
        StartMonth := Any.IntegerInRange(1, 12);
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2018), 1, 4000);

        StartYear := Date2DMY(TheDate, 3);
        if Date2DMY(TheDate, 2) < StartMonth then
            StartYear -= 1;

        Assert.AreEqual(DMY2Date(1, StartMonth, StartYear), FiscalPeriodMapper.GetFiscalYearStartDate(StartMonth, TheDate),
            StrSubstNo('Expected the fiscal year containing %1 (start month %2) to begin on the first day of that month', TheDate, StartMonth));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDateFiscalYearEndsTheDayBeforeTheNextStart()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartMonth: Integer;
        TheDate: Date;
        StartYear: Integer;
    begin
        StartMonth := Any.IntegerInRange(1, 12);
        TheDate := Any.DateInRange(DMY2Date(1, 1, 2018), 1, 4000);

        StartYear := Date2DMY(TheDate, 3);
        if Date2DMY(TheDate, 2) < StartMonth then
            StartYear -= 1;

        Assert.AreEqual(DMY2Date(1, StartMonth, StartYear + 1) - 1, FiscalPeriodMapper.GetFiscalYearEndDate(StartMonth, TheDate),
            StrSubstNo('Expected the fiscal year containing %1 (start month %2) to end the day before the next fiscal year begins', TheDate, StartMonth));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetPeriodNoRejectsStartMonthZero()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        asserterror FiscalPeriodMapper.GetPeriodNo(0, DMY2Date(15, 6, 2025));
        Assert.ExpectedError('between 1 and 12');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetFiscalYearStartDateRejectsStartMonthThirteen()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        asserterror FiscalPeriodMapper.GetFiscalYearStartDate(13, DMY2Date(15, 6, 2025));
        Assert.ExpectedError('between 1 and 12');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetFiscalYearEndDateRejectsStartMonthZero()
    var
        FiscalPeriodMapper: Codeunit "Fiscal Period Mapper";
        Assert: Codeunit Assert;
    begin
        asserterror FiscalPeriodMapper.GetFiscalYearEndDate(0, DMY2Date(15, 6, 2025));
        Assert.ExpectedError('between 1 and 12');
    end;
}
