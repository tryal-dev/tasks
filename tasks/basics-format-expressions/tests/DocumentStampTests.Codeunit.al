codeunit 50900 "Document Stamp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        MonthNamesTok: Label 'January,February,March,April,May,June,July,August,September,October,November,December', Locked = true;
        WeekdayNamesTok: Label 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoDateZeroPadsSingleDigitMonthAndDay()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 3 February 2026 renders as 2026-02-03 — month and day carry a leading zero
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoDate(DMY2Date(3, 2, 2026));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('2026-02-03', Actual,
            'Expected the ISO face of 3 February 2026 to be 2026-02-03 — four-digit year, then a zero-padded month and day separated by dashes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoDateOfGeneratedDate()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Value: Date;
        Actual: Text;
    begin
        // [SCENARIO] Any date renders as year-month-day built from its own parts
        Value := AnyDate();
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoDate(Value);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual(ExpectedIsoDate(Value), Actual,
            StrSubstNo('Expected the ISO face of %1 (day %2, month %3, year %4) to be year-month-day with two-digit month and day', Value, Date2DMY(Value, 1), Date2DMY(Value, 2), Date2DMY(Value, 3)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoDateDoesNotChangeWithTheSessionLanguage()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] A Danish session renders the same ISO text as an English one
        PreviousLanguage := SwitchToDanish();
        Actual := DocumentStamp.IsoDate(DMY2Date(3, 2, 2026));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('2026-02-03', Actual,
            'Expected the ISO face of 3 February 2026 to be 2026-02-03 in a Danish session as well — the one-argument Format follows the regional settings, the composed format string does not');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoDateOfBlankDateIsEmpty()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 0D yields an empty string, not an error
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoDate(0D);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('', Actual, 'Expected the ISO face of a blank date (0D) to be an empty string');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrintedDateUsesUnpaddedDayAndFullMonthName()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 3 February 2026 prints as "3. February 2026" in an English session
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.PrintedDate(DMY2Date(3, 2, 2026));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('3. February 2026', Actual,
            'Expected the printed face of 3 February 2026 to be "3. February 2026" — unpadded day, full stop, one space, the full month name, one space, four-digit year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrintedDateOfGeneratedDate()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Value: Date;
        Actual: Text;
    begin
        // [SCENARIO] Any date prints as day, full stop, English month name and four-digit year
        Value := AnyDate();
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.PrintedDate(Value);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual(StrSubstNo('%1. %2 %3', Date2DMY(Value, 1), SelectStr(Date2DMY(Value, 2), MonthNamesTok), Date2DMY(Value, 3)), Actual,
            StrSubstNo('Expected the printed face of %1 (day %2, month %3, year %4) to be the unpadded day, a full stop, a space, the full English month name, a space and the four-digit year', Value, Date2DMY(Value, 1), Date2DMY(Value, 2), Date2DMY(Value, 3)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrintedDateOfBlankDateIsEmpty()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 0D yields an empty string, not an error
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.PrintedDate(0D);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('', Actual, 'Expected the printed face of a blank date (0D) to be an empty string');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekdayNameIsTheFullEnglishName()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 3 February 2026 is a Tuesday
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.WeekdayName(DMY2Date(3, 2, 2026));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('Tuesday', Actual,
            'Expected the weekday face of 3 February 2026 to be Tuesday — the full weekday name in the English (US) session the test runs in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekdayNameOfGeneratedDate()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Value: Date;
        Actual: Text;
    begin
        // [SCENARIO] Any date renders its own weekday name
        Value := AnyDate();
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.WeekdayName(Value);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual(SelectStr(Date2DWY(Value, 1), WeekdayNamesTok), Actual,
            StrSubstNo('Expected the weekday face of %1 to be its full English weekday name (weekday number %2, Monday = 1)', Value, Date2DWY(Value, 1)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekdayNameOfBlankDateIsEmpty()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 0D yields an empty string, not an error
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.WeekdayName(0D);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('', Actual, 'Expected the weekday face of a blank date (0D) to be an empty string');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoWeekKeyZeroPadsSingleDigitWeek()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 3 February 2026 lies in ISO week 6 of 2026
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoWeekKey(DMY2Date(3, 2, 2026));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('2026-W06', Actual,
            'Expected the ISO week key of 3 February 2026 to be 2026-W06 — four-digit week year, dash, capital W and a zero-padded two-digit week');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoWeekKeyOfLateDecemberBelongsToTheNextYear()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] Monday 29 December 2025 opens ISO week 1 of 2026
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoWeekKey(DMY2Date(29, 12, 2025));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('2026-W01', Actual,
            'Expected the ISO week key of 29 December 2025 to be 2026-W01 — the calendar year is 2025 but the ISO week year is 2026');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoWeekKeyOfDecember31RollsIntoTheNextYear()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] Tuesday 31 December 2024 lies in ISO week 1 of 2025
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoWeekKey(DMY2Date(31, 12, 2024));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('2025-W01', Actual,
            'Expected the ISO week key of 31 December 2024 to be 2025-W01 — the last day of the year already belongs to week 1 of the next ISO year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoWeekKeyOfEarlyJanuaryStaysInThePreviousYear()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] Friday 1 January 2027 still lies in ISO week 53 of 2026
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoWeekKey(DMY2Date(1, 1, 2027));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('2026-W53', Actual,
            'Expected the ISO week key of 1 January 2027 to be 2026-W53 — the first days of January can belong to the last ISO week of the previous year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoWeekKeyOfGeneratedDate()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Value: Date;
        Actual: Text;
    begin
        // [SCENARIO] Any date renders the ISO week year and two-digit week the platform assigns it
        Value := AnyDate();
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoWeekKey(Value);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual(StrSubstNo('%1-W%2', Date2DWY(Value, 3), TwoDigits(Date2DWY(Value, 2))), Actual,
            StrSubstNo('Expected the ISO week key of %1 to be the ISO week year %2, a dash, W and the two-digit ISO week %3', Value, Date2DWY(Value, 3), Date2DWY(Value, 2)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoWeekKeyDoesNotChangeWithTheSessionLanguage()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] A Danish session renders the same ISO week key as an English one
        PreviousLanguage := SwitchToDanish();
        Actual := DocumentStamp.IsoWeekKey(DMY2Date(29, 12, 2025));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('2026-W01', Actual,
            'Expected the ISO week key of 29 December 2025 to be 2026-W01 in a Danish session as well — the week year, the capital W and the two-digit week never follow the regional settings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsoWeekKeyOfBlankDateIsEmpty()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 0D yields an empty string, not an error
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.IsoWeekKey(0D);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('', Actual, 'Expected the ISO week key of a blank date (0D) to be an empty string');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClockTimeZeroPadsHoursAndMinutes()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 09:05:30 renders as 09:05 — zero-filled hour, no seconds
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.ClockTime(090530T);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('09:05', Actual,
            'Expected the clock face of 09:05:30 to be 09:05 — a zero-filled two-digit hour (not a space), a colon, two-digit minutes and no seconds');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClockTimeUsesTheTwentyFourHourClock()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 21:07:00 renders as 21:07, not 09:07 or 9:07 PM
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.ClockTime(210700T);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('21:07', Actual,
            'Expected the clock face of 21:07:00 to be 21:07 — the 24-hour clock, so no AM/PM and no 12-hour hour');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClockTimeOfGeneratedTimeDropsSeconds()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PreviousLanguage: Integer;
        Hours: Integer;
        Minutes: Integer;
        Seconds: Integer;
        Value: Time;
        Actual: Text;
    begin
        // [SCENARIO] Any time renders its hour and minute and nothing else
        Hours := Any.IntegerInRange(0, 23);
        Minutes := Any.IntegerInRange(0, 59);
        Seconds := Any.IntegerInRange(1, 59);
        Value := 000000T + ((Hours * 60 + Minutes) * 60 + Seconds) * 1000;
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.ClockTime(Value);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual(StrSubstNo('%1:%2', TwoDigits(Hours), TwoDigits(Minutes)), Actual,
            StrSubstNo('Expected the clock face of %1 hours, %2 minutes and %3 seconds to be the two-digit hour, a colon and the two-digit minutes, with the seconds dropped', Hours, Minutes, Seconds));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClockTimeDoesNotChangeWithTheSessionLanguage()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] A Danish session renders the same clock text as an English one
        PreviousLanguage := SwitchToDanish();
        Actual := DocumentStamp.ClockTime(210700T);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('21:07', Actual,
            'Expected the clock face of 21:07:00 to be 21:07 in a Danish session as well — the one-argument Format follows the regional time settings, the composed format string does not');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClockTimeOfBlankTimeIsEmpty()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 0T yields an empty string, not an error
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.ClockTime(0T);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('', Actual, 'Expected the clock face of a blank time (0T) to be an empty string');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileStampHasNoSeparators()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 3 February 2026 renders as 20260203
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.FileStamp(DMY2Date(3, 2, 2026));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('20260203', Actual,
            'Expected the file stamp of 3 February 2026 to be 20260203 — four-digit year, two-digit month and two-digit day with nothing in between');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileStampOfGeneratedDate()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Value: Date;
        Actual: Text;
    begin
        // [SCENARIO] Any date renders as an eight-digit year-month-day stamp
        Value := AnyDate();
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.FileStamp(Value);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual(DelChr(ExpectedIsoDate(Value), '=', '-'), Actual,
            StrSubstNo('Expected the file stamp of %1 (day %2, month %3, year %4) to be the eight digits of year, two-digit month and two-digit day', Value, Date2DMY(Value, 1), Date2DMY(Value, 2), Date2DMY(Value, 3)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileStampDoesNotChangeWithTheSessionLanguage()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] A Danish session renders the same file stamp as an English one
        PreviousLanguage := SwitchToDanish();
        Actual := DocumentStamp.FileStamp(DMY2Date(3, 2, 2026));
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('20260203', Actual,
            'Expected the file stamp of 3 February 2026 to be 20260203 in a Danish session as well — the one-argument Format would render 03-02-2026 there, the composed format string does not follow the regional settings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileStampOfBlankDateIsEmpty()
    var
        DocumentStamp: Codeunit "Document Stamp";
        Assert: Codeunit Assert;
        PreviousLanguage: Integer;
        Actual: Text;
    begin
        // [SCENARIO] 0D yields an empty string, not an error
        PreviousLanguage := SwitchToEnglishUs();
        Actual := DocumentStamp.FileStamp(0D);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('', Actual, 'Expected the file stamp of a blank date (0D) to be an empty string');
    end;

    local procedure SwitchToEnglishUs(): Integer
    var
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(EnglishUsLanguageId());
        exit(PreviousLanguage);
    end;

    local procedure SwitchToDanish(): Integer
    var
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(DanishLanguageId());
        exit(PreviousLanguage);
    end;

    local procedure EnglishUsLanguageId(): Integer
    begin
        exit(1033);
    end;

    local procedure DanishLanguageId(): Integer
    begin
        exit(1030);
    end;

    local procedure AnyDate(): Date
    var
        Any: Codeunit Any;
    begin
        exit(DMY2Date(1, 1, 2020) + Any.IntegerInRange(0, 3652));
    end;

    local procedure ExpectedIsoDate(Value: Date): Text
    begin
        exit(StrSubstNo('%1-%2-%3', Date2DMY(Value, 3), TwoDigits(Date2DMY(Value, 2)), TwoDigits(Date2DMY(Value, 1))));
    end;

    local procedure TwoDigits(Number: Integer): Text
    begin
        if Number < 10 then
            exit('0' + Format(Number));
        exit(Format(Number));
    end;
}
