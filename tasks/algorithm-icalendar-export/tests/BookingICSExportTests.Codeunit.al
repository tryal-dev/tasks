codeunit 50900 "Booking ICS Export Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyTableProducesBareCalendarSkeleton()
    var
        Output: Text;
    begin
        // [SCENARIO] An empty Booking table still yields a valid, event-free calendar
        // [GIVEN] no bookings
        ClearBookings();

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(1, 4, 2026), 120000T);

        // [THEN] the feed is exactly the VCALENDAR wrapper, CRLF-terminated
        AssertExactFeed(
            'BEGIN:VCALENDAR' + CrLf() +
            'VERSION:2.0' + CrLf() +
            'PRODID:-//TryAL//Bookings 1.0//EN' + CrLf() +
            'END:VCALENDAR' + CrLf(),
            Output);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EveryLineBreakIsCrlf()
    var
        Output: Text;
        CharCode: Integer;
        BareBreak: Boolean;
        i: Integer;
    begin
        // [SCENARIO] Every line break in the feed is CR immediately followed by LF
        // [GIVEN] one simple booking
        ClearBookings();
        AddBooking('CRLF-01', 'Standup', 'Teams', DMY2Date(2, 6, 2026), 100000T, DMY2Date(2, 6, 2026), 101500T);

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(1, 6, 2026), 080000T);

        // [THEN] the feed ends with CRLF and contains no bare CR or LF
        Assert.IsTrue(Output.EndsWith(CrLf()),
            StrSubstNo('Expected the feed to end with a CRLF after END:VCALENDAR, got: <%1>', MakeVisible(Output)));
        // AL evaluates both operands of "and"/"or", so the neighbour lookups stay
        // behind their own bounds checks instead of sharing one condition.
        for i := 1 to StrLen(Output) do begin
            CharCode := Output[i];
            if CharCode = 10 then begin
                BareBreak := i = 1;
                if not BareBreak then
                    BareBreak := Output[i - 1] <> 13;
                if BareBreak then
                    Assert.Fail(StrSubstNo('Found a bare LF at character %1 — every line break must be CR immediately followed by LF. Feed: <%2>', i, MakeVisible(Output)));
            end;
            if CharCode = 13 then begin
                BareBreak := i = StrLen(Output);
                if not BareBreak then
                    BareBreak := Output[i + 1] <> 10;
                if BareBreak then
                    Assert.Fail(StrSubstNo('Found a CR without a following LF at character %1 — every line break must be CR immediately followed by LF. Feed: <%2>', i, MakeVisible(Output)));
            end;
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleBookingProducesTheExactFeed()
    var
        Output: Text;
    begin
        // [SCENARIO] One plain booking serializes to the exact byte sequence of the example
        // [GIVEN] one booking with a short description and location
        ClearBookings();
        AddBooking('BK-001', 'Board meeting', 'Room 4', DMY2Date(10, 4, 2026), 090000T, DMY2Date(10, 4, 2026), 103000T);

        // [WHEN] exporting with the stamp April 1, 2026 12:00:00
        Output := Export(DMY2Date(1, 4, 2026), 120000T);

        // [THEN] the whole feed matches byte for byte
        AssertExactFeed(
            'BEGIN:VCALENDAR' + CrLf() +
            'VERSION:2.0' + CrLf() +
            'PRODID:-//TryAL//Bookings 1.0//EN' + CrLf() +
            'BEGIN:VEVENT' + CrLf() +
            'UID:BK-001@tryal-bookings' + CrLf() +
            'DTSTAMP:20260401T120000Z' + CrLf() +
            'DTSTART:20260410T090000Z' + CrLf() +
            'DTEND:20260410T103000Z' + CrLf() +
            'SUMMARY:Board meeting' + CrLf() +
            'LOCATION:Room 4' + CrLf() +
            'END:VEVENT' + CrLf() +
            'END:VCALENDAR' + CrLf(),
            Output);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoBookingsProduceTheExactExampleFeed()
    var
        Output: Text;
    begin
        // [SCENARIO] The two-booking feed from the statement example serializes byte for byte, the second event's lines included
        // [GIVEN] the two bookings of the statement example, the second with a long description and no location
        ClearBookings();
        AddBooking('BK-001', 'Board meeting', 'Room 4', DMY2Date(10, 4, 2026), 090000T, DMY2Date(10, 4, 2026), 103000T);
        AddBooking('BK-002', 'Quarterly review with all the regional facility coordinators, catering ordered, projector booked', '', DMY2Date(11, 4, 2026), 140000T, DMY2Date(11, 4, 2026), 150000T);

        // [WHEN] exporting with the stamp April 1, 2026 12:00:00
        Output := Export(DMY2Date(1, 4, 2026), 120000T);

        // [THEN] both events carry their complete VEVENT block, the second SUMMARY folded
        AssertExactFeed(
            'BEGIN:VCALENDAR' + CrLf() +
            'VERSION:2.0' + CrLf() +
            'PRODID:-//TryAL//Bookings 1.0//EN' + CrLf() +
            'BEGIN:VEVENT' + CrLf() +
            'UID:BK-001@tryal-bookings' + CrLf() +
            'DTSTAMP:20260401T120000Z' + CrLf() +
            'DTSTART:20260410T090000Z' + CrLf() +
            'DTEND:20260410T103000Z' + CrLf() +
            'SUMMARY:Board meeting' + CrLf() +
            'LOCATION:Room 4' + CrLf() +
            'END:VEVENT' + CrLf() +
            'BEGIN:VEVENT' + CrLf() +
            'UID:BK-002@tryal-bookings' + CrLf() +
            'DTSTAMP:20260401T120000Z' + CrLf() +
            'DTSTART:20260411T140000Z' + CrLf() +
            'DTEND:20260411T150000Z' + CrLf() +
            'SUMMARY:Quarterly review with all the regional facility coordinators\, cate' + CrLf() +
            ' ring ordered\, projector booked' + CrLf() +
            'END:VEVENT' + CrLf() +
            'END:VCALENDAR' + CrLf(),
            Output);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleDigitDateAndTimePartsAreZeroPadded()
    var
        Output: Text;
    begin
        // [SCENARIO] Date-time components below 10 keep their leading zero
        // [GIVEN] a booking starting March 5, 2026 at 07:04:09
        ClearBookings();
        AddBooking('PAD-01', 'Early sync', '', DMY2Date(5, 3, 2026), 070409T, DMY2Date(5, 3, 2026), 080000T);

        // [WHEN] exporting with the stamp January 2, 2026 03:04:05
        Output := Export(DMY2Date(2, 1, 2026), 030405T);

        // [THEN] every component is zero-padded to fixed width
        Assert.AreEqual('DTSTAMP:20260102T030405Z', GetUnfoldedLine(Output, 'DTSTAMP:'),
            'Expected every component of the DTSTAMP date-time to be zero-padded to fixed width');
        Assert.AreEqual('DTSTART:20260305T070409Z', GetUnfoldedLine(Output, 'DTSTART:'),
            'Expected every component of the DTSTART date-time to be zero-padded to fixed width');
        Assert.AreEqual('DTEND:20260305T080000Z', GetUnfoldedLine(Output, 'DTEND:'),
            'Expected every component of the DTEND date-time to be zero-padded to fixed width');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryAndLocationSpecialCharactersAreEscaped()
    var
        Output: Text;
    begin
        // [SCENARIO] Backslash, semicolon and comma are escaped in SUMMARY and LOCATION
        // [GIVEN] a booking whose description and location contain all three characters
        ClearBookings();
        AddBooking('ESC-01', 'Lunch; bring \ your, plans', 'Cafe; downstairs', DMY2Date(8, 4, 2026), 120000T, DMY2Date(8, 4, 2026), 130000T);

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(7, 4, 2026), 090000T);

        // [THEN] the values are escaped without cascading
        Assert.AreEqual('SUMMARY:Lunch\; bring \\ your\, plans', GetUnfoldedLine(Output, 'SUMMARY:'),
            'Expected backslash, semicolon and comma in the description to be escaped in SUMMARY, without re-escaping the escapes');
        Assert.AreEqual('LOCATION:Cafe\; downstairs', GetUnfoldedLine(Output, 'LOCATION:'),
            'Expected the semicolon in the location to be escaped in LOCATION');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LongSummaryFoldsAt75OctetsWithASpaceContinuation()
    var
        Lines: List of [Text];
        Output: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] A 108-character SUMMARY content line folds into 75 + space+33
        // [GIVEN] a booking whose description is 100 characters long
        ClearBookings();
        AddBooking('FOLD-01', PadStr('', 100, 'A'), '', DMY2Date(15, 4, 2026), 090000T, DMY2Date(15, 4, 2026), 100000T);

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(14, 4, 2026), 120000T);

        // [THEN] the SUMMARY spans exactly two physical lines of 75 and 34 characters
        Lines := GetPhysicalLines(Output);
        LineNo := FindLineIndex(Lines, 'SUMMARY:', Output);
        Assert.IsTrue(LineNo + 1 <= Lines.Count(),
            StrSubstNo('Expected a continuation line after the folded SUMMARY. Feed: <%1>', MakeVisible(Output)));
        Assert.AreEqual('SUMMARY:' + PadStr('', 67, 'A'), Lines.Get(LineNo),
            'Expected the first physical line of the folded SUMMARY to carry exactly 75 characters');
        Assert.AreEqual(' ' + PadStr('', 33, 'A'), Lines.Get(LineNo + 1),
            'Expected the continuation line to be a single space followed by the remaining 33 characters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryFillingTheLineToExactly75CharactersStaysUnfolded()
    var
        Output: Text;
    begin
        // [SCENARIO] A content line of exactly 75 characters is not folded — only longer ones are
        // [GIVEN] a booking whose 67-character description makes the SUMMARY content line exactly 75 characters
        ClearBookings();
        AddBooking('EDGE-75', PadStr('', 67, 'E'), '', DMY2Date(18, 4, 2026), 090000T, DMY2Date(18, 4, 2026), 100000T);

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(14, 4, 2026), 120000T);

        // [THEN] the SUMMARY is a single 75-character physical line with no continuation
        AssertExactFeed(
            'BEGIN:VCALENDAR' + CrLf() +
            'VERSION:2.0' + CrLf() +
            'PRODID:-//TryAL//Bookings 1.0//EN' + CrLf() +
            'BEGIN:VEVENT' + CrLf() +
            'UID:EDGE-75@tryal-bookings' + CrLf() +
            'DTSTAMP:20260414T120000Z' + CrLf() +
            'DTSTART:20260418T090000Z' + CrLf() +
            'DTEND:20260418T100000Z' + CrLf() +
            'SUMMARY:' + PadStr('', 67, 'E') + CrLf() +
            'END:VEVENT' + CrLf() +
            'END:VCALENDAR' + CrLf(),
            Output);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryOneCharacterOverTheLineCapFoldsIntoTwoPhysicalLines()
    var
        Output: Text;
    begin
        // [SCENARIO] A 76-character content line folds into 75 characters plus a two-character continuation
        // [GIVEN] a booking whose 68-character description makes the SUMMARY content line 76 characters
        ClearBookings();
        AddBooking('EDGE-76', PadStr('', 68, 'F'), '', DMY2Date(19, 4, 2026), 090000T, DMY2Date(19, 4, 2026), 100000T);

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(14, 4, 2026), 120000T);

        // [THEN] the SUMMARY spans exactly 75 characters plus a space and the one remaining character
        AssertExactFeed(
            'BEGIN:VCALENDAR' + CrLf() +
            'VERSION:2.0' + CrLf() +
            'PRODID:-//TryAL//Bookings 1.0//EN' + CrLf() +
            'BEGIN:VEVENT' + CrLf() +
            'UID:EDGE-76@tryal-bookings' + CrLf() +
            'DTSTAMP:20260414T120000Z' + CrLf() +
            'DTSTART:20260419T090000Z' + CrLf() +
            'DTEND:20260419T100000Z' + CrLf() +
            'SUMMARY:' + PadStr('', 67, 'F') + CrLf() +
            ' F' + CrLf() +
            'END:VEVENT' + CrLf() +
            'END:VCALENDAR' + CrLf(),
            Output);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EscapeInflatedSummaryFoldsIntoThreePhysicalLines()
    var
        Lines: List of [Text];
        Output: Text;
        Escaped: Text;
        LineNo: Integer;
        i: Integer;
    begin
        // [SCENARIO] Folding happens after escaping, by pure character count
        // [GIVEN] a booking whose description is 100 commas (208 characters once escaped and prefixed)
        ClearBookings();
        AddBooking('FOLD-02', PadStr('', 100, ','), '', DMY2Date(16, 4, 2026), 090000T, DMY2Date(16, 4, 2026), 100000T);
        for i := 1 to 100 do
            Escaped += '\,';

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(14, 4, 2026), 120000T);

        // [THEN] the SUMMARY spans exactly three physical lines of 75, 75 and 60 characters
        Lines := GetPhysicalLines(Output);
        LineNo := FindLineIndex(Lines, 'SUMMARY:', Output);
        Assert.IsTrue(LineNo + 2 <= Lines.Count(),
            StrSubstNo('Expected the 208-character escaped SUMMARY to fold into three physical lines. Feed: <%1>', MakeVisible(Output)));
        Assert.AreEqual('SUMMARY:' + CopyStr(Escaped, 1, 67), Lines.Get(LineNo),
            'Expected the first physical line of the folded SUMMARY to carry exactly 75 characters — escape first, then fold by pure character count');
        Assert.AreEqual(' ' + CopyStr(Escaped, 68, 74), Lines.Get(LineNo + 1),
            'Expected the second physical line to be a space plus the next 74 characters, even though that splits an escape pair');
        Assert.AreEqual(' ' + CopyStr(Escaped, 142), Lines.Get(LineNo + 2),
            'Expected the third physical line to be a space plus the remaining 59 characters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoPhysicalLineExceeds75Octets()
    var
        Lines: List of [Text];
        Output: Text;
        i: Integer;
    begin
        // [SCENARIO] Long SUMMARY and LOCATION lines are both folded under the cap
        // [GIVEN] a booking with a 90-character description and a 100-character location
        ClearBookings();
        AddBooking('CAP-01', PadStr('', 90, 'C'), PadStr('', 100, 'B'), DMY2Date(17, 4, 2026), 090000T, DMY2Date(17, 4, 2026), 100000T);

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(14, 4, 2026), 120000T);

        // [THEN] the feed has the expected 14 physical lines and none exceeds 75 characters
        Lines := GetPhysicalLines(Output);
        Assert.AreEqual(14, Lines.Count(),
            StrSubstNo('Expected 14 physical lines: 12 event and wrapper lines plus one continuation each for the folded SUMMARY and LOCATION. Feed: <%1>', MakeVisible(Output)));
        for i := 1 to Lines.Count() do
            Assert.IsTrue(StrLen(Lines.Get(i)) <= 75,
                StrSubstNo('Physical line %1 is %2 characters long — no physical line may exceed 75 octets excluding the CRLF: <%3>', i, StrLen(Lines.Get(i)), Lines.Get(i)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BookingsAppearInNumberOrder()
    var
        Lines: List of [Text];
        UidLines: List of [Text];
        Output: Text;
        i: Integer;
    begin
        // [SCENARIO] Events are emitted in ascending "No." order
        // [GIVEN] three bookings inserted out of key order
        ClearBookings();
        AddBooking('ORD-B2', 'Second', '', DMY2Date(2, 7, 2026), 090000T, DMY2Date(2, 7, 2026), 100000T);
        AddBooking('ORD-C3', 'Third', '', DMY2Date(3, 7, 2026), 090000T, DMY2Date(3, 7, 2026), 100000T);
        AddBooking('ORD-A1', 'First', '', DMY2Date(1, 7, 2026), 090000T, DMY2Date(1, 7, 2026), 100000T);

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(30, 6, 2026), 120000T);

        // [THEN] the UID lines appear in ascending booking number order
        Lines := GetPhysicalLines(Output);
        for i := 1 to Lines.Count() do
            if Lines.Get(i).StartsWith('UID:') then
                UidLines.Add(Lines.Get(i));
        Assert.AreEqual(3, UidLines.Count(),
            StrSubstNo('Expected one UID line per booking. Feed: <%1>', MakeVisible(Output)));
        Assert.AreEqual('UID:ORD-A1@tryal-bookings', UidLines.Get(1), 'Expected the booking with the lowest "No." to come first');
        Assert.AreEqual('UID:ORD-B2@tryal-bookings', UidLines.Get(2), 'Expected the bookings to be ordered by "No."');
        Assert.AreEqual('UID:ORD-C3@tryal-bookings', UidLines.Get(3), 'Expected the booking with the highest "No." to come last');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LocationLineIsOmittedWhenLocationIsEmpty()
    var
        Output: Text;
    begin
        // [SCENARIO] An empty Location produces no LOCATION line at all
        // [GIVEN] one booking without a location
        ClearBookings();
        AddBooking('NOLOC-1', 'Site visit', '', DMY2Date(20, 5, 2026), 130000T, DMY2Date(20, 5, 2026), 140000T);

        // [WHEN] exporting the feed
        Output := Export(DMY2Date(19, 5, 2026), 070000T);

        // [THEN] SUMMARY is followed directly by END:VEVENT, byte for byte
        AssertExactFeed(
            'BEGIN:VCALENDAR' + CrLf() +
            'VERSION:2.0' + CrLf() +
            'PRODID:-//TryAL//Bookings 1.0//EN' + CrLf() +
            'BEGIN:VEVENT' + CrLf() +
            'UID:NOLOC-1@tryal-bookings' + CrLf() +
            'DTSTAMP:20260519T070000Z' + CrLf() +
            'DTSTART:20260520T130000Z' + CrLf() +
            'DTEND:20260520T140000Z' + CrLf() +
            'SUMMARY:Site visit' + CrLf() +
            'END:VEVENT' + CrLf() +
            'END:VCALENDAR' + CrLf(),
            Output);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedBookingMatchesTheSpecification()
    var
        Booking: Record Booking;
        Any: Codeunit Any;
        Output: Text;
        StampDate: Date;
        StampTime: Time;
    begin
        // [SCENARIO] A generated booking is serialized exactly as the specification demands
        // [GIVEN] one booking with random number, times, and a long description containing a comma and a semicolon
        ClearBookings();
        AddBooking(
            CopyStr(UpperCase(Any.AlphabeticText(10)), 1, 20),
            Any.AlphabeticText(30) + ',' + Any.AlphabeticText(40) + ';' + Any.AlphabeticText(20),
            Any.AlphabeticText(12),
            DMY2Date(Any.IntegerInRange(1, 28), Any.IntegerInRange(1, 12), 2026),
            MakeTime(Any.IntegerInRange(0, 23), Any.IntegerInRange(0, 59), Any.IntegerInRange(0, 59)),
            DMY2Date(Any.IntegerInRange(1, 28), Any.IntegerInRange(1, 12), 2027),
            MakeTime(Any.IntegerInRange(0, 23), Any.IntegerInRange(0, 59), Any.IntegerInRange(0, 59)));
        StampDate := DMY2Date(Any.IntegerInRange(1, 28), Any.IntegerInRange(1, 12), 2026);
        StampTime := MakeTime(Any.IntegerInRange(0, 23), Any.IntegerInRange(0, 59), Any.IntegerInRange(0, 59));
        Booking.FindFirst();

        // [WHEN] exporting the feed
        Output := Export(StampDate, StampTime);

        // [THEN] the feed matches an independently assembled expectation byte for byte
        AssertExactFeed(
            'BEGIN:VCALENDAR' + CrLf() +
            'VERSION:2.0' + CrLf() +
            'PRODID:-//TryAL//Bookings 1.0//EN' + CrLf() +
            'BEGIN:VEVENT' + CrLf() +
            ExpectedFolded('UID:' + Booking."No." + '@tryal-bookings') +
            ExpectedFolded('DTSTAMP:' + ExpectedUtc(StampDate, StampTime)) +
            ExpectedFolded('DTSTART:' + ExpectedUtc(Booking."Start Date", Booking."Start Time")) +
            ExpectedFolded('DTEND:' + ExpectedUtc(Booking."End Date", Booking."End Time")) +
            ExpectedFolded('SUMMARY:' + ExpectedEscaped(Booking.Description)) +
            ExpectedFolded('LOCATION:' + ExpectedEscaped(Booking.Location)) +
            'END:VEVENT' + CrLf() +
            'END:VCALENDAR' + CrLf(),
            Output);
    end;

    local procedure ClearBookings()
    var
        Booking: Record Booking;
    begin
        Booking.DeleteAll();
    end;

    local procedure AddBooking(No: Code[20]; Description: Text; Location: Text; StartDate: Date; StartTime: Time; EndDate: Date; EndTime: Time)
    var
        Booking: Record Booking;
    begin
        Booking.Init();
        Booking."No." := No;
        Booking.Description := CopyStr(Description, 1, MaxStrLen(Booking.Description));
        Booking.Location := CopyStr(Location, 1, MaxStrLen(Booking.Location));
        Booking."Start Date" := StartDate;
        Booking."Start Time" := StartTime;
        Booking."End Date" := EndDate;
        Booking."End Time" := EndTime;
        Booking.Insert();
    end;

    local procedure Export(StampDate: Date; StampTime: Time): Text
    var
        BookingICSExport: Codeunit "Booking ICS Export";
    begin
        exit(BookingICSExport.Export(StampDate, StampTime));
    end;

    local procedure MakeTime(Hours: Integer; Minutes: Integer; Seconds: Integer): Time
    begin
        exit(000000T + (Hours * 3600000 + Minutes * 60000 + Seconds * 1000));
    end;

    local procedure ExpectedUtc(D: Date; T: Time): Text
    var
        Ms: BigInteger;
        TotalSeconds: BigInteger;
    begin
        Ms := T - 000000T;
        TotalSeconds := Ms div 1000;
        exit(Format(Date2DMY(D, 3), 0, 9) + Pad2(Date2DMY(D, 2)) + Pad2(Date2DMY(D, 1)) + 'T' +
            Pad2(TotalSeconds div 3600) + Pad2((TotalSeconds div 60) mod 60) + Pad2(TotalSeconds mod 60) + 'Z');
    end;

    local procedure Pad2(Value: BigInteger): Text
    var
        Result: Text;
    begin
        Result := Format(Value, 0, 9);
        if StrLen(Result) < 2 then
            Result := '0' + Result;
        exit(Result);
    end;

    local procedure ExpectedEscaped(Value: Text): Text
    begin
        exit(Value.Replace('\', '\\').Replace(';', '\;').Replace(',', '\,'));
    end;

    local procedure ExpectedFolded(ContentLine: Text) Result: Text
    begin
        while StrLen(ContentLine) > 75 do begin
            Result += CopyStr(ContentLine, 1, 75) + CrLf();
            ContentLine := ' ' + CopyStr(ContentLine, 76);
        end;
        Result += ContentLine + CrLf();
    end;

    local procedure GetPhysicalLines(Output: Text): List of [Text]
    var
        Lines: List of [Text];
    begin
        Lines := Output.Split(CrLf());
        // the trailing CRLF leaves one empty element behind
        if Lines.Count() > 0 then
            if Lines.Get(Lines.Count()) = '' then
                Lines.RemoveAt(Lines.Count());
        exit(Lines);
    end;

    local procedure FindLineIndex(Lines: List of [Text]; Prefix: Text; Output: Text): Integer
    var
        i: Integer;
    begin
        for i := 1 to Lines.Count() do
            if Lines.Get(i).StartsWith(Prefix) then
                exit(i);
        Assert.Fail(StrSubstNo('Expected the feed to contain a %1 line. Feed: <%2>', Prefix, MakeVisible(Output)));
    end;

    local procedure GetUnfoldedLine(Output: Text; Prefix: Text): Text
    var
        Lines: List of [Text];
        Line: Text;
        Unfolded: Text;
        FoundAt: Integer;
        i: Integer;
    begin
        Lines := GetPhysicalLines(Output);
        FoundAt := FindLineIndex(Lines, Prefix, Output);
        Unfolded := Lines.Get(FoundAt);
        // AL evaluates both operands of "and", so the bounds check and the Get
        // cannot share one condition.
        for i := FoundAt + 1 to Lines.Count() do begin
            Line := Lines.Get(i);
            if not Line.StartsWith(' ') then
                exit(Unfolded);
            Unfolded += CopyStr(Line, 2);
        end;
        exit(Unfolded);
    end;

    local procedure AssertExactFeed(Expected: Text; Actual: Text)
    var
        Shorter: Integer;
        i: Integer;
    begin
        if Expected = Actual then
            exit;
        Shorter := StrLen(Expected);
        if StrLen(Actual) < Shorter then
            Shorter := StrLen(Actual);
        for i := 1 to Shorter do
            if Expected[i] <> Actual[i] then
                Assert.Fail(StrSubstNo('The feed differs at character %1: expected %2 but got %3. Expected feed: <%4>. Actual feed: <%5>',
                    i, DescribeChar(Expected[i]), DescribeChar(Actual[i]), MakeVisible(Expected), MakeVisible(Actual)));
        Assert.Fail(StrSubstNo('The feed has the wrong length: expected %1 characters but got %2 (the first %3 characters match). Expected feed: <%4>. Actual feed: <%5>',
            StrLen(Expected), StrLen(Actual), Shorter, MakeVisible(Expected), MakeVisible(Actual)));
    end;

    local procedure DescribeChar(C: Char): Text
    var
        CharCode: Integer;
    begin
        CharCode := C;
        case CharCode of
            13:
                exit('CR (code 13)');
            10:
                exit('LF (code 10)');
            32:
                exit('a space (code 32)');
            else
                exit(StrSubstNo('"%1" (code %2)', CharText(C), CharCode));
        end;
    end;

    local procedure MakeVisible(Value: Text): Text
    begin
        exit(Value.Replace(CrLf(), '<CRLF>').Replace(CharText(13), '<CR>').Replace(CharText(10), '<LF>'));
    end;

    local procedure CharText(C: Char): Text
    var
        Result: Text[1];
    begin
        Result := ' ';
        Result[1] := C;
        exit(Result);
    end;

    local procedure CrLf(): Text
    var
        Result: Text[2];
    begin
        Result := '  ';
        Result[1] := 13;
        Result[2] := 10;
        exit(Result);
    end;
}
