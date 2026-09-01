codeunit 50900 "Line Breaks Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JoinsLinesWithCrLfBetweenThem()
    var
        LineBreaks: Codeunit "Line Breaks";
        Any: Codeunit Any;
        Lines: List of [Text];
        First: Text;
        Second: Text;
        Third: Text;
    begin
        // [SCENARIO] Three generated lines are joined into one body
        First := Any.AlphabeticText(8);
        Second := Any.AlphabeticText(9);
        Third := Any.AlphabeticText(10);
        Lines.AddRange(First, Second, Third);

        AssertExactText(First + Crlf() + Second + Crlf() + Third, LineBreaks.JoinLines(Lines),
            'Consecutive lines must be separated by CR LF (character 13 then character 10) and nothing else');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JoinedSeparatorIsExactlyCharacters13And10()
    var
        LineBreaks: Codeunit "Line Breaks";
        Assert: Codeunit Assert;
        Lines: List of [Text];
        Joined: Text;
    begin
        // [SCENARIO] Joining "a" and "b" yields four characters: a, CR, LF, b
        Lines.AddRange('a', 'b');

        Joined := LineBreaks.JoinLines(Lines);

        Assert.AreEqual(4, StrLen(Joined),
            StrSubstNo('Expected "a" + CR + LF + "b" (4 characters) but your JoinLines returned "%1" (%2 characters)',
                MakeControlCharsVisible(Joined), StrLen(Joined)));
        Assert.AreEqual(13, CharCodeAt(Joined, 2),
            StrSubstNo('Expected character 2 of the joined text to be code 13 (CR), got code %1 in "%2"',
                CharCodeAt(Joined, 2), MakeControlCharsVisible(Joined)));
        Assert.AreEqual(10, CharCodeAt(Joined, 3),
            StrSubstNo('Expected character 3 of the joined text to be code 10 (LF), got code %1 in "%2"',
                CharCodeAt(Joined, 3), MakeControlCharsVisible(Joined)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JoinCopiesLineTextsVerbatim()
    var
        LineBreaks: Codeunit "Line Breaks";
        Lines: List of [Text];
    begin
        // [SCENARIO] Lines carry leading/trailing spaces, digits, punctuation, and mixed case
        Lines.AddRange('  Amount: 1,250.00 EUR ', 'ref#42', ' Mixed CASE tail');

        AssertExactText('  Amount: 1,250.00 EUR ' + Crlf() + 'ref#42' + Crlf() + ' Mixed CASE tail', LineBreaks.JoinLines(Lines),
            'Line texts must be copied character for character - no trimming, no case changes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleLineJoinsUnchanged()
    var
        LineBreaks: Codeunit "Line Breaks";
        Any: Codeunit Any;
        Lines: List of [Text];
        SoloLine: Text;
    begin
        // [SCENARIO] A one-entry list joins to that entry with no line ending around it
        SoloLine := Any.AlphabeticText(12);
        Lines.Add(SoloLine);

        AssertExactText(SoloLine, LineBreaks.JoinLines(Lines),
            'A single line joins to itself - no separator before or after it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyListJoinsToEmptyText()
    var
        LineBreaks: Codeunit "Line Breaks";
        Lines: List of [Text];
    begin
        // [SCENARIO] Nothing to join
        AssertExactText('', LineBreaks.JoinLines(Lines),
            'An empty list must join to the empty text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JoinKeepsAnEmptyMiddleLine()
    var
        LineBreaks: Codeunit "Line Breaks";
        Lines: List of [Text];
    begin
        // [SCENARIO] An empty entry between two lines is a blank line and keeps both of its separators
        Lines.AddRange('head', '', 'tail');

        AssertExactText('head' + Crlf() + Crlf() + 'tail', LineBreaks.JoinLines(Lines),
            'A blank middle line must produce two CR LF pairs in a row');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitsCrLfSeparatedBody()
    var
        LineBreaks: Codeunit "Line Breaks";
        Expected: List of [Text];
    begin
        // [SCENARIO] A Windows-style body separates lines with CRLF
        Expected.AddRange('north', 'south', 'east');

        AssertExactLines(Expected, LineBreaks.SplitLines('north' + Crlf() + 'south' + Crlf() + 'east'),
            'A CR LF pair ends a line, and neither character may remain in the returned lines');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitsLfSeparatedBody()
    var
        LineBreaks: Codeunit "Line Breaks";
        Expected: List of [Text];
    begin
        // [SCENARIO] A Unix-style body separates lines with bare LF
        Expected.AddRange('alpha', 'beta', 'gamma');

        AssertExactLines(Expected, LineBreaks.SplitLines('alpha' + Lf() + 'beta' + Lf() + 'gamma'),
            'A bare LF ends a line just like a CR LF pair does');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitsBodyMixingCrLfAndLf()
    var
        LineBreaks: Codeunit "Line Breaks";
        Any: Codeunit Any;
        Expected: List of [Text];
        Line1: Text;
        Line2: Text;
        Line3: Text;
        Line4: Text;
    begin
        // [SCENARIO] CRLF and LF alternate inside one body of generated line texts
        Line1 := Any.AlphabeticText(8);
        Line2 := Any.AlphabeticText(9);
        Line3 := Any.AlphabeticText(10);
        Line4 := Any.AlphabeticText(11);
        Expected.AddRange(Line1, Line2, Line3, Line4);

        AssertExactLines(Expected, LineBreaks.SplitLines(Line1 + Crlf() + Line2 + Lf() + Line3 + Crlf() + Line4),
            'CRLF and LF endings mixed in the same body must each end exactly one line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitKeepsAnEmptyMiddleLine()
    var
        LineBreaks: Codeunit "Line Breaks";
        Expected: List of [Text];
    begin
        // [SCENARIO] Two CRLF pairs in a row enclose a blank line
        Expected.AddRange('head', '', 'tail');

        AssertExactLines(Expected, LineBreaks.SplitLines('head' + Crlf() + Crlf() + 'tail'),
            'A blank line between two lines must come back as an empty entry, not vanish');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitOfBodyWithoutLineEndingIsOneLine()
    var
        LineBreaks: Codeunit "Line Breaks";
        Any: Codeunit Any;
        Expected: List of [Text];
        SoloLine: Text;
    begin
        // [SCENARIO] A generated body with no line ending at all is one line
        SoloLine := Any.AlphabeticText(12);
        Expected.Add(SoloLine);

        AssertExactLines(Expected, LineBreaks.SplitLines(SoloLine),
            'A body with no line ending is exactly one line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitOfEmptyBodyIsEmptyList()
    var
        LineBreaks: Codeunit "Line Breaks";
        Expected: List of [Text];
    begin
        // [SCENARIO] The body is the empty text
        AssertExactLines(Expected, LineBreaks.SplitLines(''),
            'An empty body has no lines, so the list must be empty - not one empty entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackslashNInContentIsNotALineEnding()
    var
        LineBreaks: Codeunit "Line Breaks";
        Expected: List of [Text];
    begin
        // [SCENARIO] A Windows path contains the two characters backslash and n twice
        Expected.Add('C:\new\notes.txt');

        AssertExactLines(Expected, LineBreaks.SplitLines('C:\new\notes.txt'),
            'A backslash followed by n is ordinary text in AL, not a line ending - the path must stay one line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundTripPreservesABlankMiddleLine()
    var
        LineBreaks: Codeunit "Line Breaks";
        Any: Codeunit Any;
        Lines: List of [Text];
    begin
        // [SCENARIO] A list with a blank middle line survives JoinLines followed by SplitLines
        Lines.AddRange(Any.AlphabeticText(7), '', Any.AlphabeticText(9));

        AssertExactLines(Lines, LineBreaks.SplitLines(LineBreaks.JoinLines(Lines)),
            'Splitting the text that JoinLines produced must give back the original list, blank line included');
    end;

    local procedure Crlf(): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.CRLFSeparator());
    end;

    local procedure Lf(): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.LFSeparator());
    end;

    local procedure CharCodeAt(Value: Text; Index: Integer): Integer
    var
        Character: Char;
    begin
        Character := Value[Index];
        exit(Character);
    end;

    local procedure AssertExactText(Expected: Text; Actual: Text; Context: Text)
    var
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(Expected, Actual,
            StrSubstNo('%1. Expected "%2" but your JoinLines returned "%3"',
                Context, MakeControlCharsVisible(Expected), MakeControlCharsVisible(Actual)));
    end;

    local procedure AssertExactLines(Expected: List of [Text]; Actual: List of [Text]; Context: Text)
    var
        Assert: Codeunit Assert;
        Index: Integer;
    begin
        Assert.AreEqual(Expected.Count(), Actual.Count(),
            StrSubstNo('%1. Wrong number of lines: expected %2 but your SplitLines returned %3',
                Context, Describe(Expected), Describe(Actual)));
        for Index := 1 to Expected.Count() do
            Assert.AreEqual(Expected.Get(Index), Actual.Get(Index),
                StrSubstNo('%1. Line %2 is wrong: expected %3 but your SplitLines returned %4',
                    Context, Index, Describe(Expected), Describe(Actual)));
    end;

    local procedure Describe(Lines: List of [Text]): Text
    var
        LineList: TextBuilder;
        Line: Text;
    begin
        LineList.Append('[');
        foreach Line in Lines do begin
            if LineList.Length() > 1 then
                LineList.Append(', ');
            LineList.Append('"' + MakeControlCharsVisible(Line) + '"');
        end;
        LineList.Append(']');
        exit(LineList.ToText());
    end;

    // CR and LF render invisibly, so a wrong separator would make expected
    // and actual look identical in the failure message without this.
    local procedure MakeControlCharsVisible(Value: Text): Text
    var
        VisibleText: TextBuilder;
        CurrentChar: Char;
        Index: Integer;
    begin
        for Index := 1 to StrLen(Value) do begin
            CurrentChar := Value[Index];
            case CurrentChar of
                13:
                    VisibleText.Append('<CR>');
                10:
                    VisibleText.Append('<LF>');
                else
                    VisibleText.Append(Format(CurrentChar));
            end;
        end;
        exit(VisibleText.ToText());
    end;
}
