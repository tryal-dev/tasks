codeunit 50900 "Depot Hours Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        UndefinedTimeTok: Label 'undefined time (0T)', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenBeforeMidnightInOvernightWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 23:30 lies in the evening half of a 22:00–06:00 window
        Assert.IsTrue(DepotHours.IsOpen(233000T, 220000T, 060000T),
            'Expected IsOpen(23:30, 22:00, 06:00) to be true — 23:30 is after the opening of a window that crosses midnight, got false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenAfterMidnightInOvernightWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 01:00 lies in the morning half of a 22:00–06:00 window
        Assert.IsTrue(DepotHours.IsOpen(010000T, 220000T, 060000T),
            'Expected IsOpen(01:00, 22:00, 06:00) to be true — 01:00 is before the closing of a window that crosses midnight, got false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenExactlyAtOvernightOpeningTime()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The opening instant of a window that crosses midnight counts as open
        Assert.IsTrue(DepotHours.IsOpen(220000T, 220000T, 060000T),
            'Expected IsOpen(22:00, 22:00, 06:00) to be true — the opening instant is open, got false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClosedExactlyAtOvernightClosingTime()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The closing instant of a window that crosses midnight counts as closed
        Assert.IsFalse(DepotHours.IsOpen(060000T, 220000T, 060000T),
            'Expected IsOpen(06:00, 22:00, 06:00) to be false — the closing instant is already closed, got true');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClosedInTheMorningAfterOvernightWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 07:00 is after the closing and before the opening of a 22:00–06:00 window
        Assert.IsFalse(DepotHours.IsOpen(070000T, 220000T, 060000T),
            'Expected IsOpen(07:00, 22:00, 06:00) to be false — 07:00 is outside a window that crosses midnight, got true');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenInsideDaytimeWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        At: Time;
    begin
        // [SCENARIO] Any minute from 08:00 up to 16:59 lies inside an 08:00–17:00 window
        At := 080000T + Any.IntegerInRange(0, 539) * 60000;
        Assert.IsTrue(DepotHours.IsOpen(At, 080000T, 170000T),
            StrSubstNo('Expected IsOpen(%1, 08:00, 17:00) to be true — the time lies inside a plain daytime window, got false', At));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenExactlyAtDaytimeOpeningTime()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The opening instant of a daytime window counts as open
        Assert.IsTrue(DepotHours.IsOpen(080000T, 080000T, 170000T),
            'Expected IsOpen(08:00, 08:00, 17:00) to be true — the opening instant of a daytime window is open, got false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClosedExactlyAtDaytimeClosingTime()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The closing instant of a daytime window counts as closed
        Assert.IsFalse(DepotHours.IsOpen(170000T, 080000T, 170000T),
            'Expected IsOpen(17:00, 08:00, 17:00) to be false — the closing instant of a daytime window is already closed, got true');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClosedBeforeDaytimeWindowOpens()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 06:00 is before the opening of an 08:00–17:00 window
        Assert.IsFalse(DepotHours.IsOpen(060000T, 080000T, 170000T),
            'Expected IsOpen(06:00, 08:00, 17:00) to be false — the depot has not opened yet, got true');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClosedAfterDaytimeWindowCloses()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 19:00 is after the closing of an 08:00–17:00 window
        Assert.IsFalse(DepotHours.IsOpen(190000T, 080000T, 170000T),
            'Expected IsOpen(19:00, 08:00, 17:00) to be false — the depot has already closed, got true');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenRoundTheClockWhenOpensAtEqualsClosesAt()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        At: Time;
    begin
        // [SCENARIO] A 00:00–00:00 window is open at every minute of the day
        At := 000000T + Any.IntegerInRange(0, 1439) * 60000;
        Assert.IsTrue(DepotHours.IsOpen(At, 000000T, 000000T),
            StrSubstNo('Expected IsOpen(%1, 00:00, 00:00) to be true — equal opening and closing times mean open round the clock, got false', At));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenAtTheSharedTimeOfARoundTheClockWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] In a 06:00–06:00 window even 06:00 itself is open
        Assert.IsTrue(DepotHours.IsOpen(060000T, 060000T, 060000T),
            'Expected IsOpen(06:00, 06:00, 06:00) to be true — a round-the-clock window is open at its own shared time, got false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShiftMinutesForADaytimeShift()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Minutes: Integer;
    begin
        // [SCENARIO] A shift starting at 08:00 and lasting a generated number of minutes reports exactly that length
        Minutes := Any.IntegerInRange(1, 600);
        Assert.AreEqual(Minutes, DepotHours.ShiftMinutes(080000T, 080000T + Minutes * 60000),
            StrSubstNo('Expected a shift from 08:00 lasting %1 minutes to report %1 minutes', Minutes));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShiftMinutesForTheOvernightShift()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 22:00 to 06:00 is eight hours, not minus sixteen
        Assert.AreEqual(480, DepotHours.ShiftMinutes(220000T, 060000T),
            'Expected the 22:00–06:00 night shift to be 480 minutes long — an end time earlier on the clock means the shift crosses midnight');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShiftMinutesWrapsAcrossMidnight()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 23:59 to 00:01 is two minutes across midnight
        Assert.AreEqual(2, DepotHours.ShiftMinutes(235900T, 000100T),
            'Expected the shift from 23:59 to 00:01 to be 2 minutes long — the wrap past midnight must add exactly one day');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShiftMinutesIsZeroWhenEndEqualsStart()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StartTime: Time;
    begin
        // [SCENARIO] A shift that ends when it starts has no length
        StartTime := 000000T + Any.IntegerInRange(0, 1439) * 60000;
        Assert.AreEqual(0, DepotHours.ShiftMinutes(StartTime, StartTime),
            StrSubstNo('Expected a shift from %1 to %1 to be 0 minutes long — equal times are an empty shift, not a full day', StartTime));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShiftMinutesDropsLeftoverSeconds()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 08:15:15 to 09:00:00 is 44 minutes and 45 seconds; the seconds are dropped, not rounded up
        Assert.AreEqual(44, DepotHours.ShiftMinutes(081515T, 090000T),
            'Expected the shift from 08:15:15 to 09:00:00 to be 44 whole minutes — leftover seconds are dropped, never rounded up to 45');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseBeforeMidnightInOvernightWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] At 23:30 a 22:00–06:00 depot closes in 6 hours 30 minutes
        Assert.AreEqual(390, DepotHours.MinutesUntilClose(233000T, 220000T, 060000T),
            'Expected 390 minutes from 23:30 until the 06:00 closing of a 22:00–06:00 window — the count must continue past midnight');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseAfterMidnightInOvernightWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] At 01:00 a 22:00–06:00 depot closes in 5 hours
        Assert.AreEqual(300, DepotHours.MinutesUntilClose(010000T, 220000T, 060000T),
            'Expected 300 minutes from 01:00 until the 06:00 closing of a 22:00–06:00 window');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseIsZeroAtOvernightClosingTime()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] At the closing instant of a window that crosses midnight the depot is already closed
        Assert.AreEqual(0, DepotHours.MinutesUntilClose(060000T, 220000T, 060000T),
            'Expected 0 minutes at exactly 06:00 in a 22:00–06:00 window — the closing instant is closed, so nothing remains');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseIsZeroWhenClosed()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Outside the window there is no closing to count down to
        Assert.AreEqual(0, DepotHours.MinutesUntilClose(070000T, 220000T, 060000T),
            'Expected 0 minutes at 07:00 in a 22:00–06:00 window — the depot is closed, so the countdown must not run to the next closing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseInsideDaytimeWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Offset: Integer;
        At: Time;
    begin
        // [SCENARIO] A generated minute inside 08:00–17:00 reports exactly the minutes left until 17:00
        Offset := Any.IntegerInRange(0, 539);
        At := 080000T + Offset * 60000;
        Assert.AreEqual(540 - Offset, DepotHours.MinutesUntilClose(At, 080000T, 170000T),
            StrSubstNo('Expected %1 minutes from %2 until the 17:00 closing of an 08:00–17:00 window', 540 - Offset, At));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseIsZeroAtDaytimeClosingTime()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] At the closing instant of a daytime window the depot is already closed
        Assert.AreEqual(0, DepotHours.MinutesUntilClose(170000T, 080000T, 170000T),
            'Expected 0 minutes at exactly 17:00 in an 08:00–17:00 window — the closing instant is closed, so nothing remains');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseInARoundTheClockWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] At 21:00 a 00:00–00:00 depot is open and the clock next reads 00:00 in three hours
        Assert.AreEqual(180, DepotHours.MinutesUntilClose(210000T, 000000T, 000000T),
            'Expected 180 minutes from 21:00 until the clock next reads 00:00 in a round-the-clock 00:00–00:00 window');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseIsAFullDayAtTheSharedTimeOfARoundTheClockWindow()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] At 06:00 in a 06:00–06:00 window the depot is open and the next 06:00 is a whole day away
        Assert.AreEqual(1440, DepotHours.MinutesUntilClose(060000T, 060000T, 060000T),
            'Expected 1440 minutes at 06:00 in a round-the-clock 06:00–06:00 window — the depot is open and the next closing is strictly in the future');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsOpenRefusesUndefinedAt()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Result: Boolean;
    begin
        // [SCENARIO] An undefined At is refused with the task's own message, not answered with a silent false
        asserterror Result := DepotHours.IsOpen(0T, 220000T, 060000T);
        Assert.ExpectedError(UndefinedTimeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsOpenRefusesUndefinedOpensAt()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Result: Boolean;
    begin
        // [SCENARIO] An undefined OpensAt is refused with the task's own message
        asserterror Result := DepotHours.IsOpen(230000T, 0T, 060000T);
        Assert.ExpectedError(UndefinedTimeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsOpenRefusesUndefinedClosesAt()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Result: Boolean;
    begin
        // [SCENARIO] An undefined ClosesAt is refused with the task's own message
        asserterror Result := DepotHours.IsOpen(230000T, 220000T, 0T);
        Assert.ExpectedError(UndefinedTimeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShiftMinutesRefusesUndefinedStartTime()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Result: Integer;
    begin
        // [SCENARIO] An undefined StartTime is refused before any arithmetic crashes on it
        asserterror Result := DepotHours.ShiftMinutes(0T, 060000T);
        Assert.ExpectedError(UndefinedTimeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShiftMinutesRefusesUndefinedEndTime()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Result: Integer;
    begin
        // [SCENARIO] An undefined EndTime is refused before any arithmetic crashes on it
        asserterror Result := DepotHours.ShiftMinutes(220000T, 0T);
        Assert.ExpectedError(UndefinedTimeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseRefusesUndefinedAt()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Result: Integer;
    begin
        // [SCENARIO] An undefined At is refused with the task's own message, not answered with a silent 0
        asserterror Result := DepotHours.MinutesUntilClose(0T, 220000T, 060000T);
        Assert.ExpectedError(UndefinedTimeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseRefusesUndefinedOpensAt()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Result: Integer;
    begin
        // [SCENARIO] An undefined OpensAt is refused with the task's own message
        asserterror Result := DepotHours.MinutesUntilClose(230000T, 0T, 060000T);
        Assert.ExpectedError(UndefinedTimeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MinutesUntilCloseRefusesUndefinedClosesAt()
    var
        DepotHours: Codeunit "Depot Hours";
        Assert: Codeunit Assert;
        Result: Integer;
    begin
        // [SCENARIO] An undefined ClosesAt is refused with the task's own message
        asserterror Result := DepotHours.MinutesUntilClose(230000T, 220000T, 0T);
        Assert.ExpectedError(UndefinedTimeTok);
    end;
}
