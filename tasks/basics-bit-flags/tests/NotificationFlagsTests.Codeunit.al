codeunit 50900 "Notification Flags Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NotificationFlags: Codeunit "Notification Flags";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasFlagReadsEachFlagOfNine()
    begin
        // [SCENARIO] 9 = 8 + 1 carries Email and Post and nothing else
        // [WHEN] asking for each of the five flags of 9
        // [THEN] Email and Post are set; SMS, Portal and Urgent first are not
        Assert.IsTrue(NotificationFlags.HasFlag(9, 1), 'Expected HasFlag(9, 1) to be true — 9 = 8 + 1, so the Email flag (1) is part of it');
        Assert.IsFalse(NotificationFlags.HasFlag(9, 2), 'Expected HasFlag(9, 2) to be false — the SMS flag (2) is not part of 9 = 8 + 1');
        Assert.IsFalse(NotificationFlags.HasFlag(9, 4), 'Expected HasFlag(9, 4) to be false — the Portal flag (4) is not part of 9 = 8 + 1');
        Assert.IsTrue(NotificationFlags.HasFlag(9, 8), 'Expected HasFlag(9, 8) to be true — 9 = 8 + 1, so the Post flag (8) is part of it');
        Assert.IsFalse(NotificationFlags.HasFlag(9, 16), 'Expected HasFlag(9, 16) to be false — the Urgent first flag (16) is not part of 9 = 8 + 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasFlagIsFalseForEveryFlagOfZero()
    var
        Bit: Integer;
    begin
        // [SCENARIO] 0 carries no flag at all, and 0 is inside the valid range
        // [WHEN] asking for each of the five flags of 0
        // [THEN] none is set
        Bit := 1;
        repeat
            Assert.IsFalse(NotificationFlags.HasFlag(0, Bit), StrSubstNo('Expected HasFlag(0, %1) to be false — 0 has no flag set', Bit));
            Bit := Bit * 2;
        until Bit > 16;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasFlagIsTrueForEveryFlagOfThirtyOne()
    var
        Bit: Integer;
    begin
        // [SCENARIO] 31 = 16 + 8 + 4 + 2 + 1 carries every flag, and 31 is inside the valid range
        // [WHEN] asking for each of the five flags of 31
        // [THEN] every one is set
        Bit := 1;
        repeat
            Assert.IsTrue(NotificationFlags.HasFlag(31, Bit), StrSubstNo('Expected HasFlag(31, %1) to be true — 31 = 16 + 8 + 4 + 2 + 1 has every flag set', Bit));
            Bit := Bit * 2;
        until Bit > 16;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasFlagOnAGeneratedValueMatchesItsFlags()
    var
        Any: Codeunit Any;
        Value: Integer;
        Bit: Integer;
    begin
        // [SCENARIO] For a value the implementation cannot anticipate, HasFlag agrees with the powers of two that add up to it
        // [GIVEN] a generated value between 1 and 30
        Value := Any.IntegerInRange(1, 30);

        // [WHEN] asking for each of the five flags
        // [THEN] each answer matches whether that flag is part of the sum
        Bit := 1;
        repeat
            Assert.AreEqual(FlagIsPartOf(Value, Bit), NotificationFlags.HasFlag(Value, Bit),
                StrSubstNo('Expected HasFlag(%1, %2) to tell whether flag %2 is one of the powers of two that add up to %1', Value, Bit));
            Bit := Bit * 2;
        until Bit > 16;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetFlagAddsAFlagThatIsMissing()
    begin
        // [SCENARIO] Setting SMS on Email + Post gives Email + SMS + Post
        // [WHEN] setting flag 2 on 9
        // [THEN] 11
        Assert.AreEqual(11, NotificationFlags.SetFlag(9, 2), 'Expected SetFlag(9, 2) to add the SMS flag: 9 + 2 = 11');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetFlagLeavesAnAlreadySetFlagAlone()
    begin
        // [SCENARIO] Setting Post on a value that already has Post changes nothing
        // [WHEN] setting flag 8 on 9
        // [THEN] still 9 — adding 8 again would give 17, which is Email + Urgent first
        Assert.AreEqual(9, NotificationFlags.SetFlag(9, 8), 'Expected SetFlag(9, 8) to leave 9 unchanged — the Post flag is already set, and adding 8 again turns Email + Post into Email + Urgent first (17)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetFlagOnAGeneratedValueChangesOnlyThatFlag()
    var
        Any: Codeunit Any;
        Value: Integer;
        Bit: Integer;
        Expected: Integer;
    begin
        // [SCENARIO] For any value and any flag, SetFlag adds the flag exactly when it is missing
        // [GIVEN] a generated value between 0 and 31 and a generated flag
        Value := Any.IntegerInRange(0, 31);
        Bit := Power(2, Any.IntegerInRange(0, 4));
        Expected := Value;
        if not FlagIsPartOf(Value, Bit) then
            Expected += Bit;

        // [WHEN] setting the flag
        // [THEN] the flag is part of the result and no other flag moved
        Assert.AreEqual(Expected, NotificationFlags.SetFlag(Value, Bit),
            StrSubstNo('Expected SetFlag(%1, %2) to add flag %2 only when it is not already part of %1, and to change nothing else', Value, Bit));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClearFlagRemovesAFlagThatIsSet()
    begin
        // [SCENARIO] Clearing Post from Email + Post leaves Email
        // [WHEN] clearing flag 8 from 9
        // [THEN] 1
        Assert.AreEqual(1, NotificationFlags.ClearFlag(9, 8), 'Expected ClearFlag(9, 8) to remove the Post flag: 9 - 8 = 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClearFlagLeavesAnUnsetFlagAlone()
    begin
        // [SCENARIO] Clearing SMS from a value that has no SMS changes nothing
        // [WHEN] clearing flag 2 from 9
        // [THEN] still 9 — subtracting 2 would give 7, which is Email + SMS + Portal
        Assert.AreEqual(9, NotificationFlags.ClearFlag(9, 2), 'Expected ClearFlag(9, 2) to leave 9 unchanged — the SMS flag is not set, and subtracting 2 anyway turns Email + Post into Email + SMS + Portal (7)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClearFlagOnAGeneratedValueChangesOnlyThatFlag()
    var
        Any: Codeunit Any;
        Value: Integer;
        Bit: Integer;
        Expected: Integer;
    begin
        // [SCENARIO] For any value and any flag, ClearFlag removes the flag exactly when it is present
        // [GIVEN] a generated value between 0 and 31 and a generated flag
        Value := Any.IntegerInRange(0, 31);
        Bit := Power(2, Any.IntegerInRange(0, 4));
        Expected := Value;
        if FlagIsPartOf(Value, Bit) then
            Expected -= Bit;

        // [WHEN] clearing the flag
        // [THEN] the flag is gone from the result and no other flag moved
        Assert.AreEqual(Expected, NotificationFlags.ClearFlag(Value, Bit),
            StrSubstNo('Expected ClearFlag(%1, %2) to remove flag %2 only when it is part of %1, and to change nothing else', Value, Bit));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChannelsOfNineAreEmailThenPost()
    var
        Expected: List of [Text];
    begin
        // [SCENARIO] Email + Post lists the two channels in ascending flag order
        Expected.Add('Email');
        Expected.Add('Post');

        // [WHEN] listing the channels of 9
        // [THEN] Email, Post
        AssertChannels(9, Expected, '9 = 8 + 1 is Email and Post, in ascending flag order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChannelsOfTwentySixAreReversedToPostThenSms()
    var
        Expected: List of [Text];
    begin
        // [SCENARIO] Urgent first reverses the channel order and is not a channel itself
        Expected.Add('Post');
        Expected.Add('SMS');

        // [WHEN] listing the channels of 26
        // [THEN] Post, SMS
        AssertChannels(26, Expected, '26 = 16 + 8 + 2 is SMS and Post with Urgent first set, so the order is reversed and Urgent first itself is not listed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChannelsOfFifteenListAllFourInOrder()
    var
        Expected: List of [Text];
    begin
        // [SCENARIO] All four channels without Urgent first come in ascending flag order
        Expected.Add('Email');
        Expected.Add('SMS');
        Expected.Add('Portal');
        Expected.Add('Post');

        // [WHEN] listing the channels of 15
        // [THEN] Email, SMS, Portal, Post
        AssertChannels(15, Expected, '15 = 8 + 4 + 2 + 1 has every channel and no Urgent first, so all four come in ascending flag order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChannelsOfThirtyOneListAllFourReversed()
    var
        Expected: List of [Text];
    begin
        // [SCENARIO] All four channels with Urgent first come in descending flag order
        Expected.Add('Post');
        Expected.Add('Portal');
        Expected.Add('SMS');
        Expected.Add('Email');

        // [WHEN] listing the channels of 31
        // [THEN] Post, Portal, SMS, Email
        AssertChannels(31, Expected, '31 has every channel and Urgent first, so all four come in descending flag order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChannelsIsEmptyWhenNoChannelFlagIsSet()
    var
        Empty: List of [Text];
    begin
        // [SCENARIO] Neither 0 nor Urgent first alone names a channel
        // [WHEN] listing the channels of 0 and of 16
        // [THEN] both lists are empty
        AssertChannels(0, Empty, '0 has no flag set, so there is no channel to list');
        AssertChannels(16, Empty, '16 is Urgent first alone — it reverses the order but is not a channel, so the list stays empty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChannelsOnAGeneratedValueMatchItsFlags()
    var
        Any: Codeunit Any;
        Value: Integer;
    begin
        // [SCENARIO] For a value the implementation cannot anticipate, the channel list follows the set flags and the Urgent first rule
        // [GIVEN] a generated value between 1 and 30
        Value := Any.IntegerInRange(1, 30);

        // [WHEN] listing its channels
        // [THEN] the names of the set channel flags, ascending, or descending when flag 16 is part of the value
        AssertChannels(Value, ExpectedChannels(Value), StrSubstNo('%1 lists the set channel flags in ascending order, reversed when the Urgent first flag (16) is part of it', Value));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasFlagRefusesAValueAboveThirtyOne()
    begin
        // [SCENARIO] 32 would need a sixth flag and is not a valid preference value
        // [WHEN] asking HasFlag about 32
        asserterror NotificationFlags.HasFlag(32, 1);

        // [THEN] the error says the value must be between 0 and 31
        Assert.ExpectedError('between 0 and 31');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetFlagRefusesANegativeValue()
    begin
        // [SCENARIO] A negative number is not a sum of flags
        // [WHEN] asking SetFlag to work on -1
        asserterror NotificationFlags.SetFlag(-1, 1);

        // [THEN] the error says the value must be between 0 and 31
        Assert.ExpectedError('between 0 and 31');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClearFlagRefusesAValueAboveThirtyOne()
    begin
        // [SCENARIO] 64 is outside the five-flag range
        // [WHEN] asking ClearFlag to work on 64
        asserterror NotificationFlags.ClearFlag(64, 8);

        // [THEN] the error says the value must be between 0 and 31
        Assert.ExpectedError('between 0 and 31');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChannelsRefusesANegativeValue()
    begin
        // [SCENARIO] A negative number is not a sum of flags
        // [WHEN] listing the channels of -5
        asserterror NotificationFlags.Channels(-5);

        // [THEN] the error says the value must be between 0 and 31
        Assert.ExpectedError('between 0 and 31');
    end;

    local procedure AssertChannels(Value: Integer; Expected: List of [Text]; Why: Text)
    var
        Actual: List of [Text];
    begin
        Actual := NotificationFlags.Channels(Value);
        Assert.AreEqual(Join(Expected), Join(Actual),
            StrSubstNo('Expected Channels(%1) to return [%2] (every element is shown quoted and comma-separated, so an empty text in the list shows as two quotes): %3', Value, Join(Expected), Why));
        Assert.AreEqual(Expected.Count, Actual.Count,
            StrSubstNo('Expected Channels(%1) to return exactly %2 element(s) — one name per set channel flag and none for Urgent first (16) — but got [%3]: %4', Value, Expected.Count, Join(Actual), Why));
    end;

    local procedure ExpectedChannels(Value: Integer): List of [Text]
    var
        Names: List of [Text];
        Bit: Integer;
    begin
        Bit := 1;
        repeat
            if FlagIsPartOf(Value, Bit) then
                if FlagIsPartOf(Value, 16) then
                    Names.Insert(1, ChannelName(Bit))
                else
                    Names.Add(ChannelName(Bit));
            Bit := Bit * 2;
        until Bit > 8;
        exit(Names);
    end;

    local procedure ChannelName(Bit: Integer): Text
    begin
        case Bit of
            1:
                exit('Email');
            2:
                exit('SMS');
            4:
                exit('Portal');
            8:
                exit('Post');
        end;
    end;

    // Peels the flags off from the largest down, independently of the div/mod
    // route the task teaches: a flag is part of the value exactly when it still
    // fits after every larger flag has been removed.
    local procedure FlagIsPartOf(Value: Integer; Bit: Integer): Boolean
    var
        Remaining: Integer;
        Candidate: Integer;
    begin
        Remaining := Value;
        Candidate := 16;
        while Candidate > Bit do begin
            if Remaining >= Candidate then
                Remaining -= Candidate;
            Candidate := Candidate div 2;
        end;
        exit(Remaining >= Bit);
    end;

    // Every element is rendered quoted and every gap gets its separator, so an
    // empty text that slipped into the list (a "name" for Urgent first) shows up
    // as '' instead of vanishing from the comparison.
    local procedure Join(Names: List of [Text]): Text
    var
        Joined: Text;
        i: Integer;
    begin
        for i := 1 to Names.Count do begin
            if i > 1 then
                Joined += ', ';
            Joined += '''' + Names.Get(i) + '''';
        end;
        exit(Joined);
    end;
}
