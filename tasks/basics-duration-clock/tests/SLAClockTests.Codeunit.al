codeunit 50900 "SLA Clock Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ElapsedRendersClockAcrossMidnightAndMonthEnd()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 31 January 22:00:00 to 2 February 00:05:09 is 26 hours, 5 minutes and 9 seconds
        Assert.AreEqual('26:05:09',
            Clock.Elapsed(CreateDateTime(DMY2Date(31, 1, 2025), 220000T), CreateDateTime(DMY2Date(2, 2, 2025), 000509T)),
            'Expected Elapsed from 31 Jan 22:00:00 to 2 Feb 00:05:09 to render as 26:05:09 — hours keep counting past 24 and the month end changes nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ElapsedIsZeroForIdenticalTimes()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Moment: DateTime;
    begin
        // [SCENARIO] The same instant as start and end renders as 00:00:00
        Moment := AnyWinterDateTime();
        Assert.AreEqual('00:00:00', Clock.Elapsed(Moment, Moment),
            'Expected Elapsed between identical times to be 00:00:00 — every part zero-padded to two digits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ElapsedZeroPadsAndTruncatesSubSecondRemainder()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        StartDT: DateTime;
    begin
        // [SCENARIO] 3,723,999 ms is 1 h 2 min 3.999 s — rendered as 01:02:03, not rounded to 01:02:04
        StartDT := AnyWinterDateTime();
        Assert.AreEqual('01:02:03', Clock.Elapsed(StartDT, StartDT + 3723999),
            'Expected a span of 3,723,999 ms to render as 01:02:03 — single-digit parts are zero-padded and the 999 ms remainder is dropped, not rounded up');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ElapsedHoursDoNotWrapAtTwentyFour()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartDT: DateTime;
        Hours: Integer;
        Minutes: Integer;
        Seconds: Integer;
    begin
        // [SCENARIO] A generated span of more than a day renders its full hour count
        StartDT := AnyWinterDateTime();
        Hours := Any.IntegerInRange(25, 99);
        Minutes := Any.IntegerInRange(0, 59);
        Seconds := Any.IntegerInRange(0, 59);
        Assert.AreEqual(ClockText(Hours, Minutes, Seconds),
            Clock.Elapsed(StartDT, StartDT + SpanMs(Hours, Minutes, Seconds)),
            StrSubstNo('Expected a span of %1 h %2 min %3 s to render with all %1 hours — hours never wrap into days', Hours, Minutes, Seconds));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ElapsedHoursGrowBeyondTwoDigits()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartDT: DateTime;
        Hours: Integer;
        Minutes: Integer;
        Seconds: Integer;
    begin
        // [SCENARIO] A generated span of 100+ hours renders a three-digit hour part
        StartDT := AnyWinterDateTime();
        Hours := Any.IntegerInRange(100, 400);
        Minutes := Any.IntegerInRange(0, 59);
        Seconds := Any.IntegerInRange(0, 59);
        Assert.AreEqual(ClockText(Hours, Minutes, Seconds),
            Clock.Elapsed(StartDT, StartDT + SpanMs(Hours, Minutes, Seconds)),
            StrSubstNo('Expected a span of %1 h %2 min %3 s to render a three-digit hour part — two digits is a minimum, not a limit', Hours, Minutes, Seconds));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ElapsedErrorsWhenEndIsBeforeStart()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        StartDT: DateTime;
    begin
        // [SCENARIO] An end one minute before the start is refused
        StartDT := AnyWinterDateTime();
        asserterror Clock.Elapsed(StartDT, StartDT - 60000);
        Assert.ExpectedError('before the start time');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ElapsedErrorsWhenStartIsNotSet()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0DT as the start is refused with the must-be-set message
        asserterror Clock.Elapsed(0DT, AnyWinterDateTime());
        Assert.ExpectedError('must be set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ElapsedReportsUnsetEndAsNotSetRatherThanBeforeStart()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0DT as the end sorts before any real start, but the must-be-set check comes first
        asserterror Clock.Elapsed(AnyWinterDateTime(), 0DT);
        Assert.ExpectedError('must be set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeadlineCrossesMidnight()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 15 January 20:00 plus an 8-hour SLA is 16 January 04:00
        Assert.AreEqual(CreateDateTime(DMY2Date(16, 1, 2025), 040000T),
            Clock.Deadline(CreateDateTime(DMY2Date(15, 1, 2025), 200000T), 8),
            'Expected the deadline for a ticket reported 15 Jan 20:00 with an 8-hour SLA to be 16 Jan 04:00 — the date must roll over with the time');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeadlineCrossesMonthEnd()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 27 February 10:00 plus a 48-hour SLA is 1 March 10:00 (2025 is not a leap year)
        Assert.AreEqual(CreateDateTime(DMY2Date(1, 3, 2025), 100000T),
            Clock.Deadline(CreateDateTime(DMY2Date(27, 2, 2025), 100000T), 48),
            'Expected the deadline for a ticket reported 27 Feb 10:00 with a 48-hour SLA to be 1 Mar 10:00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeadlineAddsGeneratedSlaHours()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ReportedAt: DateTime;
        SlaHours: Integer;
    begin
        // [SCENARIO] A generated SLA moves the reported time forward by exactly that many hours
        ReportedAt := AnyWinterDateTime();
        SlaHours := Any.IntegerInRange(1, 72);
        Assert.AreEqual(ReportedAt + SpanMs(SlaHours, 0, 0), Clock.Deadline(ReportedAt, SlaHours),
            StrSubstNo('Expected the deadline to be exactly %1 hours after %2', SlaHours, ReportedAt));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeadlineErrorsWhenReportedAtIsNotSet()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A ticket without a reported time has no deadline
        asserterror Clock.Deadline(0DT, 8);
        Assert.ExpectedError('must be set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextBeforeTheDeadline()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        AsOf: DateTime;
    begin
        // [SCENARIO] 2 hours and 5 minutes before the deadline reads 2h 05m
        AsOf := AnyWinterDateTime();
        Assert.AreEqual('2h 05m', Clock.RemainingText(AsOf + SpanMs(2, 5, 0), AsOf),
            'Expected 2 hours 5 minutes of remaining time to read 2h 05m — hours unpadded, minutes two digits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextTruncatesSeconds()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        AsOf: DateTime;
    begin
        // [SCENARIO] 2 hours, 5 minutes and 59 seconds still reads 2h 05m
        AsOf := AnyWinterDateTime();
        Assert.AreEqual('2h 05m', Clock.RemainingText(AsOf + SpanMs(2, 5, 59), AsOf),
            'Expected 2 h 5 min 59 s of remaining time to read 2h 05m — the seconds are dropped, not rounded up to 2h 06m');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextAtTheDeadline()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Moment: DateTime;
    begin
        // [SCENARIO] Exactly at the deadline nothing remains and nothing is overdue
        Moment := AnyWinterDateTime();
        Assert.AreEqual('0h 00m', Clock.RemainingText(Moment, Moment),
            'Expected exactly at the deadline to read 0h 00m — only a time strictly after the deadline is overdue');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextOverdue()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        DeadlineAt: DateTime;
    begin
        // [SCENARIO] 1 hour and 10 minutes past the deadline reads overdue by 1h 10m
        DeadlineAt := AnyWinterDateTime();
        Assert.AreEqual('overdue by 1h 10m', Clock.RemainingText(DeadlineAt, DeadlineAt + SpanMs(1, 10, 0)),
            'Expected 1 hour 10 minutes past the deadline to read overdue by 1h 10m — lowercase prefix, single space before h and m');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextOverdueByUnderAMinute()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        DeadlineAt: DateTime;
    begin
        // [SCENARIO] 45 seconds past the deadline is already overdue, by zero whole minutes
        DeadlineAt := AnyWinterDateTime();
        Assert.AreEqual('overdue by 0h 00m', Clock.RemainingText(DeadlineAt, DeadlineAt + 45000),
            'Expected 45 seconds past the deadline to read overdue by 0h 00m — any time strictly after the deadline is overdue, and the seconds are dropped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextHoursDoNotWrap()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        AsOf: DateTime;
        Hours: Integer;
        Minutes: Integer;
    begin
        // [SCENARIO] A generated remaining time of more than a day keeps its full hour count
        AsOf := AnyWinterDateTime();
        Hours := Any.IntegerInRange(24, 200);
        Minutes := Any.IntegerInRange(0, 59);
        Assert.AreEqual(RemainingClockText(Hours, Minutes),
            Clock.RemainingText(AsOf + SpanMs(Hours, Minutes, Any.IntegerInRange(0, 59)), AsOf),
            StrSubstNo('Expected %1 h %2 min of remaining time to read %1h %3m — hours never wrap into days', Hours, Minutes, TwoDigits(Minutes)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextOverdueForGeneratedSpan()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DeadlineAt: DateTime;
        Hours: Integer;
        Minutes: Integer;
    begin
        // [SCENARIO] A generated span past the deadline reads overdue by that many hours and minutes
        DeadlineAt := AnyWinterDateTime();
        Hours := Any.IntegerInRange(0, 99);
        Minutes := Any.IntegerInRange(1, 59);
        Assert.AreEqual('overdue by ' + RemainingClockText(Hours, Minutes),
            Clock.RemainingText(DeadlineAt, DeadlineAt + SpanMs(Hours, Minutes, Any.IntegerInRange(0, 59))),
            StrSubstNo('Expected %1 h %2 min past the deadline to read overdue by %1h %3m', Hours, Minutes, TwoDigits(Minutes)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextErrorsWhenAsOfIsNotSet()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Remaining time cannot be measured from an unset instant
        asserterror Clock.RemainingText(AnyWinterDateTime(), 0DT);
        Assert.ExpectedError('must be set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingTextErrorsWhenDeadlineIsNotSet()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A ticket without a deadline has no remaining time to describe
        asserterror Clock.RemainingText(0DT, AnyWinterDateTime());
        Assert.ExpectedError('must be set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BillableHoursKeepsExactTwoHours()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        StartDT: DateTime;
    begin
        // [SCENARIO] Exactly two hours bills as 2.00, not the next quarter
        StartDT := AnyWinterDateTime();
        Assert.AreEqual(2.0, Clock.BillableHours(StartDT, StartDT + SpanMs(2, 0, 0)),
            'Expected exactly 2 hours to bill as 2.00 — an exact multiple of a quarter hour must not be pushed up to 2.25');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BillableHoursKeepsGeneratedExactQuarters()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartDT: DateTime;
        Quarters: Integer;
    begin
        // [SCENARIO] A generated whole number of quarter hours bills as exactly that many quarters
        StartDT := AnyWinterDateTime();
        Quarters := Any.IntegerInRange(1, 40);
        Assert.AreEqual(Quarters * 0.25, Clock.BillableHours(StartDT, StartDT + SpanMs(0, Quarters * 15, 0)),
            StrSubstNo('Expected exactly %1 quarter hours (%2 minutes) to bill as %3', Quarters, Quarters * 15, Quarters * 0.25));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BillableHoursRoundsUpOneSecondPastAQuarter()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartDT: DateTime;
        Quarters: Integer;
    begin
        // [SCENARIO] One second past a generated quarter boundary bills the next quarter
        StartDT := AnyWinterDateTime();
        Quarters := Any.IntegerInRange(1, 40);
        Assert.AreEqual((Quarters + 1) * 0.25, Clock.BillableHours(StartDT, StartDT + SpanMs(0, Quarters * 15, 1)),
            StrSubstNo('Expected %1 quarter hours plus one second to bill as %2 — anything past a quarter boundary rounds up', Quarters, (Quarters + 1) * 0.25));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BillableHoursRoundsUpNotToNearest()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        StartDT: DateTime;
    begin
        // [SCENARIO] 1 hour 46 minutes (1.7667 h) bills as 2.00, not the nearest quarter 1.75
        StartDT := AnyWinterDateTime();
        Assert.AreEqual(2.0, Clock.BillableHours(StartDT, StartDT + SpanMs(1, 46, 0)),
            'Expected 1 hour 46 minutes to bill as 2.00 — billable hours round up to the next quarter, never to the nearest one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BillableHoursIsZeroForIdenticalTimes()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        Moment: DateTime;
    begin
        // [SCENARIO] No elapsed time bills nothing
        Moment := AnyWinterDateTime();
        Assert.AreEqual(0.0, Clock.BillableHours(Moment, Moment),
            'Expected identical start and end times to bill 0 hours');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BillableHoursErrorsWhenEndIsBeforeStart()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
        StartDT: DateTime;
    begin
        // [SCENARIO] Work cannot end before it starts
        StartDT := AnyWinterDateTime();
        asserterror Clock.BillableHours(StartDT, StartDT - 1000);
        Assert.ExpectedError('before the start time');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BillableHoursErrorsWhenStartIsNotSet()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Work without a start time cannot be billed
        asserterror Clock.BillableHours(0DT, AnyWinterDateTime());
        Assert.ExpectedError('must be set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BillableHoursReportsUnsetEndAsNotSetRatherThanBeforeStart()
    var
        Clock: Codeunit "SLA Clock";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0DT as the end sorts before any real start, but the must-be-set check comes first
        asserterror Clock.BillableHours(AnyWinterDateTime(), 0DT);
        Assert.ExpectedError('must be set');
    end;

    // 2-20 January 2025 plus up to 400 hours stays inside a daylight-saving-free window in every
    // European time zone, so wall-clock arithmetic and millisecond arithmetic agree.
    local procedure AnyWinterDateTime(): DateTime
    var
        Any: Codeunit Any;
    begin
        exit(CreateDateTime(DMY2Date(2, 1, 2025) + Any.IntegerInRange(0, 18), 000000T + Any.IntegerInRange(0, 86399) * 1000));
    end;

    local procedure SpanMs(Hours: Integer; Minutes: Integer; Seconds: Integer): Duration
    var
        Span: Duration;
    begin
        Span := Hours;
        Span := Span * 3600000 + Minutes * 60000 + Seconds * 1000;
        exit(Span);
    end;

    local procedure ClockText(Hours: Integer; Minutes: Integer; Seconds: Integer): Text
    begin
        exit(StrSubstNo('%1:%2:%3', TwoDigits(Hours), TwoDigits(Minutes), TwoDigits(Seconds)));
    end;

    local procedure RemainingClockText(Hours: Integer; Minutes: Integer): Text
    begin
        exit(StrSubstNo('%1h %2m', Hours, TwoDigits(Minutes)));
    end;

    local procedure TwoDigits(Value: Integer): Text
    var
        Digits: Text;
    begin
        Digits := Format(Value);
        exit(Digits.PadLeft(2, '0'));
    end;
}
