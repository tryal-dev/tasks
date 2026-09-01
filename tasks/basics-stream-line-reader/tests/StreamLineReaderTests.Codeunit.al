codeunit 50900 "Stream Line Reader Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitsCrlfSeparatedLines()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        PayloadStream: InStream;
        Expected: List of [Text];
    begin
        // [SCENARIO] A Windows-style payload separates lines with CRLF
        OpenPayloadStream('alpha' + Crlf() + 'beta' + Crlf() + 'gamma', PayloadBlob, PayloadStream);
        Expected.AddRange('alpha', 'beta', 'gamma');

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'A CRLF pair separates two lines');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitsLfSeparatedLines()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        PayloadStream: InStream;
        Expected: List of [Text];
    begin
        // [SCENARIO] A Unix-style payload separates lines with bare LF
        OpenPayloadStream('north' + Lf() + 'south' + Lf() + 'east', PayloadBlob, PayloadStream);
        Expected.AddRange('north', 'south', 'east');

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'A bare LF separates two lines just like a CRLF pair does');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HandlesMixedLineEndingsInOnePayload()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        Any: Codeunit Any;
        PayloadStream: InStream;
        Expected: List of [Text];
        Line1: Text;
        Line2: Text;
        Line3: Text;
        Line4: Text;
    begin
        // [SCENARIO] CRLF and LF alternate inside one payload of generated line texts
        Line1 := Any.AlphabeticText(8);
        Line2 := Any.AlphabeticText(9);
        Line3 := Any.AlphabeticText(10);
        Line4 := Any.AlphabeticText(11);
        OpenPayloadStream(Line1 + Crlf() + Line2 + Lf() + Line3 + Crlf() + Line4, PayloadBlob, PayloadStream);
        Expected.AddRange(Line1, Line2, Line3, Line4);

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'CRLF and LF endings mixed in the same stream must each close exactly one line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PreservesSpacesPunctuationAndCaseExactly()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        PayloadStream: InStream;
        Expected: List of [Text];
    begin
        // [SCENARIO] Lines carry leading/trailing spaces, digits, punctuation, and mixed case
        OpenPayloadStream('  Amount: 1,250.00 EUR ' + Crlf() + 'ref#42' + Lf() + ' Mixed CASE tail', PayloadBlob, PayloadStream);
        Expected.AddRange('  Amount: 1,250.00 EUR ', 'ref#42', ' Mixed CASE tail');

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'Line content must be returned byte for byte — leading and trailing spaces, digits, punctuation, and letter case all preserved');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsABlankLineBetweenTwoLines()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        PayloadStream: InStream;
        Expected: List of [Text];
    begin
        // [SCENARIO] Two CRLF pairs in a row enclose an empty logical line
        OpenPayloadStream('head' + Crlf() + Crlf() + 'tail', PayloadBlob, PayloadStream);
        Expected.AddRange('head', '', 'tail');

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'A blank line between two lines must appear as an empty entry, not vanish');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsConsecutiveBlankLines()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        PayloadStream: InStream;
        Expected: List of [Text];
    begin
        // [SCENARIO] Three LFs in a row produce two consecutive empty logical lines
        OpenPayloadStream('top' + Lf() + Lf() + Lf() + 'bottom', PayloadBlob, PayloadStream);
        Expected.AddRange('top', '', '', 'bottom');

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'Consecutive blank lines must each appear as their own empty entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrailingLineEndingAddsNoExtraLine()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        PayloadStream: InStream;
        Expected: List of [Text];
    begin
        // [SCENARIO] The payload ends with a CRLF that closes the last line
        OpenPayloadStream('first' + Crlf() + 'second' + Crlf(), PayloadBlob, PayloadStream);
        Expected.AddRange('first', 'second');

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'A line ending at the very end of the stream closes the last line and must not add an extra empty entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheUnterminatedFinalLine()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        Any: Codeunit Any;
        PayloadStream: InStream;
        Expected: List of [Text];
        SoloLine: Text;
    begin
        // [SCENARIO] A generated payload with no line ending at all is one line
        SoloLine := Any.AlphabeticText(12);
        OpenPayloadStream(SoloLine, PayloadBlob, PayloadStream);
        Expected.Add(SoloLine);

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'Content after the last line ending — here the whole payload — is still a line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineEndingOnlyPayloadIsOneBlankLine()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        PayloadStream: InStream;
        Expected: List of [Text];
    begin
        // [SCENARIO] The payload is a single LF and nothing else
        OpenPayloadStream(Lf(), PayloadBlob, PayloadStream);
        Expected.Add('');

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'A payload of one LF is one blank line: the LF closes an empty line and adds nothing after it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyPayloadYieldsNoLines()
    var
        LineReader: Codeunit "Stream Line Reader";
        PayloadBlob: Codeunit "Temp Blob";
        PayloadStream: InStream;
        Expected: List of [Text];
    begin
        // [SCENARIO] Nothing was written to the blob at all
        OpenPayloadStream('', PayloadBlob, PayloadStream);

        AssertExactLines(LineReader.ReadLines(PayloadStream), Expected,
            'An empty stream has no lines, so the list must be empty');
    end;

    // The blob is owned by the test method: an InStream whose Temp Blob has gone
    // out of scope reads as empty (microsoft/AL issue #7329). The payloads are
    // plain ASCII, so the default encoding writes them byte for byte with no BOM.
    local procedure OpenPayloadStream(Payload: Text; var PayloadBlob: Codeunit "Temp Blob"; var PayloadStream: InStream)
    var
        PayloadOutStream: OutStream;
    begin
        PayloadBlob.CreateOutStream(PayloadOutStream);
        if Payload <> '' then
            PayloadOutStream.WriteText(Payload);
        PayloadBlob.CreateInStream(PayloadStream);
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

    local procedure AssertExactLines(Actual: List of [Text]; Expected: List of [Text]; Context: Text)
    var
        Assert: Codeunit Assert;
        Index: Integer;
    begin
        Assert.AreEqual(Expected.Count(), Actual.Count(),
            StrSubstNo('%1. Wrong number of logical lines: expected %2 but your reader returned %3',
                Context, Describe(Expected), Describe(Actual)));
        for Index := 1 to Expected.Count() do
            Assert.AreEqual(Expected.Get(Index), Actual.Get(Index),
                StrSubstNo('%1. Line %2 is wrong: expected %3 but your reader returned %4',
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

    // CR and LF render invisibly, so a leaked line ending would make expected
    // and actual look identical in the failure message without this.
    local procedure MakeControlCharsVisible(Line: Text): Text
    var
        VisibleLine: TextBuilder;
        CurrentChar: Char;
        Index: Integer;
    begin
        for Index := 1 to StrLen(Line) do begin
            CurrentChar := Line[Index];
            case CurrentChar of
                13:
                    VisibleLine.Append('<CR>');
                10:
                    VisibleLine.Append('<LF>');
                else
                    VisibleLine.Append(Format(CurrentChar));
            end;
        end;
        exit(VisibleLine.ToText());
    end;
}
