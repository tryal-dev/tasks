codeunit 50900 "CSV Line Parser Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitsPlainFieldsOnCommas()
    var
        Expected: List of [Text];
    begin
        Expected.Add('alpha');
        Expected.Add('beta');
        Expected.Add('gamma');

        VerifyParsedLine('alpha,beta,gamma', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyFieldBetweenCommasIsKept()
    var
        Expected: List of [Text];
    begin
        Expected.Add('first');
        Expected.Add('');
        Expected.Add('last');

        VerifyParsedLine('first,,last', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeadingAndTrailingCommasYieldEmptyEdgeFields()
    var
        Expected: List of [Text];
    begin
        Expected.Add('');
        Expected.Add('mid');
        Expected.Add('');

        VerifyParsedLine(',mid,', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpacesAreNeverTrimmed()
    var
        Expected: List of [Text];
    begin
        Expected.Add(' padded ');
        Expected.Add('  x');

        VerifyParsedLine(' padded ,  x', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyLineIsASingleEmptyField()
    var
        Expected: List of [Text];
    begin
        Expected.Add('');

        VerifyParsedLine('', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotedFieldKeepsItsCommas()
    var
        Expected: List of [Text];
    begin
        Expected.Add('Davis, Sam');
        Expected.Add('42');

        VerifyParsedLine('"Davis, Sam",42', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotesAreStrippedFromQuotedFields()
    var
        Expected: List of [Text];
    begin
        Expected.Add('plain');

        VerifyParsedLine('"plain"', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoubledQuoteBecomesOneLiteralQuote()
    var
        Expected: List of [Text];
    begin
        Expected.Add('He said "stop" twice');
        Expected.Add('ok');

        VerifyParsedLine('"He said ""stop"" twice",ok', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FieldOfOnlyAnEscapedQuoteIsOneQuoteCharacter()
    var
        Expected: List of [Text];
    begin
        Expected.Add('"');

        VerifyParsedLine('""""', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotedEmptyFieldIsEmpty()
    var
        Expected: List of [Text];
    begin
        Expected.Add('x');
        Expected.Add('');

        VerifyParsedLine('x,""', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdjacentQuotedFieldsStaySeparate()
    var
        Expected: List of [Text];
    begin
        Expected.Add('one');
        Expected.Add('two');
        Expected.Add('three');

        VerifyParsedLine('"one","two","three"', Expected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnterminatedQuotedFieldRaisesError()
    var
        CsvLineParser: Codeunit "CSV Line Parser";
        Assert: Codeunit Assert;
    begin
        asserterror CsvLineParser.ParseLine('"abc,def');

        Assert.ExpectedError('unterminated quoted field');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedLineRoundTrips()
    var
        Any: Codeunit Any;
        Expected: List of [Text];
    begin
        Expected.Add(Any.AlphabeticText(8));
        Expected.Add(Any.AlphabeticText(4) + ',' + Any.AlphabeticText(5));
        Expected.Add(Any.AlphabeticText(3) + '"' + Any.AlphabeticText(6));
        Expected.Add('');
        Expected.Add(Any.AlphanumericText(10));

        VerifyParsedLine(EncodeCsvLine(Expected), Expected);
    end;

    local procedure VerifyParsedLine(Line: Text; Expected: List of [Text])
    var
        CsvLineParser: Codeunit "CSV Line Parser";
        Assert: Codeunit Assert;
        Actual: List of [Text];
        i: Integer;
    begin
        Actual := CsvLineParser.ParseLine(Line);

        Assert.AreEqual(Expected.Count(), Actual.Count(), StrSubstNo('Expected the line <%1> to parse into this many fields', Line));
        for i := 1 to Expected.Count() do
            Assert.AreEqual(Expected.Get(i), Actual.Get(i), StrSubstNo('Expected this exact value for field %1 of the line <%2>', i, Line));
    end;

    local procedure EncodeCsvLine(Fields: List of [Text]) Line: Text
    var
        FieldValue: Text;
        i: Integer;
    begin
        for i := 1 to Fields.Count() do begin
            if i > 1 then
                Line += ',';
            FieldValue := Fields.Get(i);
            if FieldValue.Contains(',') or FieldValue.Contains('"') then
                Line += '"' + FieldValue.Replace('"', '""') + '"'
            else
                Line += FieldValue;
        end;
    end;
}
