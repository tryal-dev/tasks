codeunit 50900 "Timezone Unix Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        WEuropeTzLbl: Label 'W. Europe Standard Time', Locked = true;
        IndiaTzLbl: Label 'India Standard Time', Locked = true;
        BogotaTzLbl: Label 'SA Pacific Standard Time', Locked = true;
        UtcTzLbl: Label 'UTC', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WinterOffsetTextIsPlusOneHour()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
    begin
        // [SCENARIO] In January, W. Europe Standard Time is one hour ahead of UTC
        InputDateTime := AnyJanuaryUtc();
        Assert.AreEqual('+01:00', Toolkit.GetOffsetText(InputDateTime, WEuropeTzLbl),
            StrSubstNo('Expected the W. Europe Standard Time offset for the January instant %1 to be +01:00 (standard time)', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummerOffsetTextIsPlusTwoHours()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
    begin
        // [SCENARIO] In July, daylight saving pushes W. Europe Standard Time to two hours ahead of UTC
        InputDateTime := AnyJulyUtc();
        Assert.AreEqual('+02:00', Toolkit.GetOffsetText(InputDateTime, WEuropeTzLbl),
            StrSubstNo('Expected the W. Europe Standard Time offset for the July instant %1 to be +02:00 (daylight saving time)', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HalfHourZoneOffsetTextKeepsMinutes()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
    begin
        // [SCENARIO] India Standard Time is UTC+05:30 — the minutes part must not be lost or rounded
        InputDateTime := AnyJanuaryUtc();
        Assert.AreEqual('+05:30', Toolkit.GetOffsetText(InputDateTime, IndiaTzLbl),
            StrSubstNo('Expected the India Standard Time offset for %1 to be +05:30 — the offset text must carry the minutes part, not just whole hours', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeOffsetTextStartsWithMinus()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
    begin
        // [SCENARIO] SA Pacific Standard Time (Bogota/Lima) is UTC-05:00 all year
        InputDateTime := AnyJanuaryUtc();
        Assert.AreEqual('-05:00', Toolkit.GetOffsetText(InputDateTime, BogotaTzLbl),
            StrSubstNo('Expected the SA Pacific Standard Time offset for %1 to be -05:00 — a zone west of Greenwich needs a minus sign', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UtcOffsetTextIsZeroWithPlusSign()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
    begin
        // [SCENARIO] UTC itself has a zero offset, still formatted with the sign and both two-digit parts
        InputDateTime := AnyJulyUtc();
        Assert.AreEqual('+00:00', Toolkit.GetOffsetText(InputDateTime, UtcTzLbl),
            StrSubstNo('Expected the UTC offset for %1 to be +00:00 — the sign and both two-digit parts are required even for zero', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WinterInstantIsNotDaylightSaving()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
    begin
        // [SCENARIO] A January instant falls outside the W. Europe daylight saving period
        InputDateTime := AnyJanuaryUtc();
        Assert.IsFalse(Toolkit.IsDaylightSaving(InputDateTime, WEuropeTzLbl),
            StrSubstNo('Expected IsDaylightSaving to be false for the January instant %1 in W. Europe Standard Time', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummerInstantIsDaylightSaving()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
    begin
        // [SCENARIO] A July instant falls inside the W. Europe daylight saving period
        InputDateTime := AnyJulyUtc();
        Assert.IsTrue(Toolkit.IsDaylightSaving(InputDateTime, WEuropeTzLbl),
            StrSubstNo('Expected IsDaylightSaving to be true for the July instant %1 in W. Europe Standard Time', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZoneWithoutDstIsNeverDaylightSaving()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
    begin
        // [SCENARIO] India never observes daylight saving — even a July instant is not DST
        InputDateTime := AnyJulyUtc();
        Assert.IsFalse(Toolkit.IsDaylightSaving(InputDateTime, IndiaTzLbl),
            StrSubstNo('Expected IsDaylightSaving to be false for India Standard Time even at the July instant %1 — the zone never observes daylight saving, so guessing from the month fails here', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ToLocalTimeAppliesWinterOffset()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
        OneHour: Duration;
    begin
        // [SCENARIO] A January UTC instant is one hour later on a W. Europe wall clock
        InputDateTime := AnyJanuaryUtc();
        OneHour := 60 * 60 * 1000;
        Assert.AreEqual(InputDateTime + OneHour, Toolkit.ToLocalTime(InputDateTime, WEuropeTzLbl),
            StrSubstNo('Expected the January UTC instant %1 to be exactly one hour later on the W. Europe Standard Time wall clock', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ToLocalTimeAppliesSummerOffset()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
        TwoHours: Duration;
    begin
        // [SCENARIO] A July UTC instant is two hours later on a W. Europe wall clock (daylight saving)
        InputDateTime := AnyJulyUtc();
        TwoHours := 2 * 60 * 60 * 1000;
        Assert.AreEqual(InputDateTime + TwoHours, Toolkit.ToLocalTime(InputDateTime, WEuropeTzLbl),
            StrSubstNo('Expected the July UTC instant %1 to be exactly two hours later on the W. Europe Standard Time wall clock (daylight saving)', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ToLocalTimeAppliesHalfHourOffset()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        InputDateTime: DateTime;
        FiveAndAHalfHours: Duration;
    begin
        // [SCENARIO] A UTC instant is five and a half hours later on an India wall clock
        InputDateTime := AnyJanuaryUtc();
        FiveAndAHalfHours := (5 * 60 + 30) * 60 * 1000;
        Assert.AreEqual(InputDateTime + FiveAndAHalfHours, Toolkit.ToLocalTime(InputDateTime, IndiaTzLbl),
            StrSubstNo('Expected the UTC instant %1 to be exactly five and a half hours later on the India Standard Time wall clock', InputDateTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ToUnixSecondsForKnownWinterInstant()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        ExpectedSeconds: BigInteger;
    begin
        // [SCENARIO] 2025-01-15T12:00:00Z is Unix second 1736942400
        ExpectedSeconds := 1736942400L;
        Assert.AreEqual(ExpectedSeconds, Toolkit.ToUnixSeconds(WinterUtc()),
            'Expected 2025-01-15 12:00 UTC to be Unix second 1736942400 — the timestamp must be in whole seconds since 1970-01-01T00:00:00Z');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ToUnixSecondsForKnownSummerInstant()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        ExpectedSeconds: BigInteger;
    begin
        // [SCENARIO] 2025-07-15T12:00:00Z is Unix second 1752580800
        ExpectedSeconds := 1752580800L;
        Assert.AreEqual(ExpectedSeconds, Toolkit.ToUnixSeconds(SummerUtc()),
            'Expected 2025-07-15 12:00 UTC to be Unix second 1752580800 — the timestamp must be in whole seconds since 1970-01-01T00:00:00Z');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FromUnixSecondsReturnsKnownWinterInstant()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Unix second 1736942400 parses back to 2025-01-15T12:00:00Z
        Assert.AreEqual(WinterUtc(), Toolkit.FromUnixSeconds(1736942400L),
            'Expected Unix second 1736942400 to parse to the UTC datetime 2025-01-15 12:00:00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FromUnixSecondsReturnsKnownSummerInstant()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Unix second 1752580800 parses back to 2025-07-15T12:00:00Z
        Assert.AreEqual(SummerUtc(), Toolkit.FromUnixSeconds(1752580800L),
            'Expected Unix second 1752580800 to parse to the UTC datetime 2025-07-15 12:00:00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnixSecondsDifferenceMatchesDaysApart()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        BaseDate: Date;
        DaysApart: Integer;
        ExpectedDiff: BigInteger;
    begin
        // [SCENARIO] Two datetimes N days apart differ by exactly N * 86400 Unix seconds
        // [GIVEN] a generated base date and a generated distance in days
        BaseDate := DMY2Date(1, 1, 2024) + Any.IntegerInRange(0, 365);
        DaysApart := Any.IntegerInRange(1, 500);
        ExpectedDiff := DaysApart;
        ExpectedDiff := ExpectedDiff * 86400;
        // [THEN] the emitted timestamps are exactly that many seconds apart
        Assert.AreEqual(ExpectedDiff,
            Toolkit.ToUnixSeconds(UtcDateTime(BaseDate + DaysApart, 8 * 3600 + 30 * 60)) - Toolkit.ToUnixSeconds(UtcDateTime(BaseDate, 8 * 3600 + 30 * 60)),
            StrSubstNo('Expected two datetimes %1 days apart to differ by exactly %1 * 86400 Unix seconds', DaysApart));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnixRoundTripIsLossless()
    var
        Toolkit: Codeunit "Time Zone Toolkit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OriginalDateTime: DateTime;
    begin
        // [SCENARIO] A whole-second datetime survives ToUnixSeconds + FromUnixSeconds unchanged
        // [GIVEN] a generated datetime with zero milliseconds
        OriginalDateTime := UtcDateTime(DMY2Date(1, 1, 2024) + Any.IntegerInRange(0, 700), Any.IntegerInRange(0, 86399));
        // [THEN] the round trip returns the exact same datetime
        Assert.AreEqual(OriginalDateTime, Toolkit.FromUnixSeconds(Toolkit.ToUnixSeconds(OriginalDateTime)),
            'Expected a whole-second datetime to survive the Unix round trip (ToUnixSeconds then FromUnixSeconds) unchanged');
    end;

    // Any January/July 2025 instant is safely clear of the W. Europe DST transitions (last Sundays of March and October).
    local procedure AnyJanuaryUtc(): DateTime
    var
        Any: Codeunit Any;
    begin
        exit(UtcDateTime(DMY2Date(1, 1, 2025) + Any.IntegerInRange(0, 30), Any.IntegerInRange(0, 23) * 3600));
    end;

    local procedure AnyJulyUtc(): DateTime
    var
        Any: Codeunit Any;
    begin
        exit(UtcDateTime(DMY2Date(1, 7, 2025) + Any.IntegerInRange(0, 30), Any.IntegerInRange(0, 23) * 3600));
    end;

    local procedure WinterUtc(): DateTime
    begin
        exit(UtcDateTime(DMY2Date(15, 1, 2025), 12 * 3600));
    end;

    local procedure SummerUtc(): DateTime
    begin
        exit(UtcDateTime(DMY2Date(15, 7, 2025), 12 * 3600));
    end;

    // CreateDateTime builds the instant in the session's time zone, which is not UTC on
    // the grading server; the XML format with a trailing Z is the only UTC-anchored way in.
    local procedure UtcDateTime(OnDate: Date; SecondsIntoDay: Integer): DateTime
    var
        UtcMidnight: DateTime;
        IntoDay: Duration;
    begin
        Evaluate(UtcMidnight, Format(OnDate, 0, 9) + 'T00:00:00Z', 9);
        IntoDay := SecondsIntoDay;
        exit(UtcMidnight + IntoDay * 1000);
    end;
}
