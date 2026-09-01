codeunit 50900 "Payment File Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Flat file XMLports]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritesEveryColumnOfAPaymentLineAtItsFixedPosition()
    var
        Assert: Codeunit Assert;
        Lines: List of [Text];
    begin
        // [SCENARIO] One payment line becomes one 63-character PMT record
        Initialize();
        AddPaymentLine(10, 'CUST01', 'Nordwind Handel AS', 1234.56, DMY2Date(15, 1, 2026));

        Lines := ExportedFileLines();

        Assert.AreEqual(
            'PMT' + PadStr('CUST01', 10) + PadStr('Nordwind Handel AS', 30) + '000000123456' + '20260115',
            LineAt(Lines, 1),
            'Expected the payment record to be PMT, the recipient no. in columns 4-13, the name in columns 14-43, the amount in cents in columns 44-55 and the due date in columns 56-63');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RightPadsTheRecipientColumnsToTheirFullWidth()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Lines: List of [Text];
        RecipientNo: Code[10];
        RecipientName: Text[30];
    begin
        // [SCENARIO] Values shorter than their column keep the later columns in place
        Initialize();
        RecipientNo := CopyStr(UpperCase(Any.AlphabeticText(4)), 1, 10);
        RecipientName := CopyStr(Any.AlphabeticText(7), 1, 30);
        AddPaymentLine(10, RecipientNo, RecipientName, 5.0, DMY2Date(1, 2, 2026));

        Lines := ExportedFileLines();

        Assert.AreEqual(PadStr(RecipientNo, 10), Column(LineAt(Lines, 1), 4, 10),
            'Expected the recipient no. column to be filled up to its full 10 characters with spaces');
        Assert.AreEqual(PadStr(RecipientName, 30), Column(LineAt(Lines, 1), 14, 30),
            'Expected the recipient name column to be filled up to its full 30 characters with spaces');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritesTheAmountAsTwelveDigitsOfCents()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Lines: List of [Text];
        Cents: Integer;
    begin
        // [SCENARIO] The amount column carries cents only, padded with leading zeros
        Initialize();
        Cents := Any.IntegerInRange(1, 999999);
        AddPaymentLine(10, 'CUST01', 'Nordwind Handel AS', Cents / 100, DMY2Date(15, 1, 2026));

        Lines := ExportedFileLines();

        Assert.AreEqual(ZeroPadded(Cents, 12), Column(LineAt(Lines, 1), 44, 12),
            'Expected the amount column to be the amount multiplied by 100, written as 12 digits with leading zeros and no separators');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritesTheDueDateAsEightDigits()
    var
        Assert: Codeunit Assert;
        Lines: List of [Text];
    begin
        // [SCENARIO] The due date column is yyyymmdd, with single-digit months and days padded
        Initialize();
        AddPaymentLine(10, 'CUST01', 'Nordwind Handel AS', 1234.56, DMY2Date(7, 3, 2026));

        Lines := ExportedFileLines();

        Assert.AreEqual('20260307', Column(LineAt(Lines, 1), 56, 8),
            'Expected the due date column to be the four-digit year, the two-digit month and the two-digit day, with no separators');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritesOnePaymentRecordPerLineInLineNumberOrder()
    var
        Assert: Codeunit Assert;
        Lines: List of [Text];
    begin
        // [SCENARIO] Three payment lines inserted out of order come out sorted by "Line No."
        Initialize();
        AddPaymentLine(30, 'THIRD', 'Bergen Marine', 30.0, DMY2Date(3, 3, 2026));
        AddPaymentLine(10, 'FIRST', 'Nordwind Handel AS', 10.0, DMY2Date(1, 3, 2026));
        AddPaymentLine(20, 'SECOND', 'Lakeview Ltd', 20.0, DMY2Date(2, 3, 2026));

        Lines := ExportedFileLines();

        Assert.AreEqual(4, Lines.Count(),
            StrSubstNo('Expected three payment records followed by one trailer record, got %1', DescribeLines(Lines)));
        Assert.AreEqual(PadStr('FIRST', 10), Column(LineAt(Lines, 1), 4, 10),
            StrSubstNo('Expected the payment record with the lowest "Line No." first, got %1', DescribeLines(Lines)));
        Assert.AreEqual(PadStr('SECOND', 10), Column(LineAt(Lines, 2), 4, 10),
            StrSubstNo('Expected the payment records in ascending "Line No." order, got %1', DescribeLines(Lines)));
        Assert.AreEqual(PadStr('THIRD', 10), Column(LineAt(Lines, 3), 4, 10),
            StrSubstNo('Expected the payment record with the highest "Line No." last, got %1', DescribeLines(Lines)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndsTheFileWithATrailerCountingAndTotallingThePaymentLines()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Lines: List of [Text];
        FirstCents: Integer;
        SecondCents: Integer;
        ThirdCents: Integer;
    begin
        // [SCENARIO] The last record of the file is the TRL trailer over three payment lines
        Initialize();
        FirstCents := Any.IntegerInRange(1, 99999);
        SecondCents := Any.IntegerInRange(1, 99999);
        ThirdCents := Any.IntegerInRange(1, 99999);
        AddPaymentLine(10, 'FIRST', 'Nordwind Handel AS', FirstCents / 100, DMY2Date(1, 3, 2026));
        AddPaymentLine(20, 'SECOND', 'Lakeview Ltd', SecondCents / 100, DMY2Date(2, 3, 2026));
        AddPaymentLine(30, 'THIRD', 'Bergen Marine', ThirdCents / 100, DMY2Date(3, 3, 2026));

        Lines := ExportedFileLines();

        Assert.AreEqual(
            'TRL' + ZeroPadded(3, 6) + ZeroPadded(FirstCents + SecondCents + ThirdCents, 12),
            LineAt(Lines, 4),
            StrSubstNo('Expected the file to end with TRL, the number of payment records as 6 digits and the total cents as 12 digits. Exported file: %1', DescribeLines(Lines)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WritesTheTrailerEvenWhenThereAreNoPaymentLines()
    var
        Assert: Codeunit Assert;
        Lines: List of [Text];
    begin
        // [SCENARIO] An empty payment batch still produces the trailer record
        Initialize();

        Lines := ExportedFileLines();

        Assert.AreEqual(1, Lines.Count(),
            StrSubstNo('Expected an empty payment batch to export exactly one record — the trailer — got %1', DescribeLines(Lines)));
        Assert.AreEqual('TRL' + ZeroPadded(0, 6) + ZeroPadded(0, 12), LineAt(Lines, 1),
            'Expected the trailer of an empty payment batch to report a count of zero and a total of zero');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportsOneReturnRecordPerLineOfTheFile()
    var
        BankReturnLine: Record "Bank Return Line";
        Assert: Codeunit Assert;
        Payload: TextBuilder;
    begin
        // [SCENARIO] A three-line return file becomes three "Bank Return Line" records
        Initialize();
        Payload.AppendLine('TRYAL-R801;Nordwind Handel AS;0000012345;ACCP;Booked');
        Payload.AppendLine('TRYAL-R802;Lakeview Ltd;0000000099;ACCP;Booked');
        Payload.Append('TRYAL-R803;Bergen Marine;0000450000;RJCT;Account closed');

        ImportReturnFile(Payload.ToText());

        Assert.RecordCount(BankReturnLine, 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsTheLeadingZerosOfTheReferenceColumn()
    var
        BankReturnLine: Record "Bank Return Line";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A reference number written as ten digits keeps its leading zeros
        Initialize();

        ImportReturnFile('0000004217;Nordwind Handel AS;0000012345;ACCP;Booked');

        Assert.RecordCount(BankReturnLine, 1);
        BankReturnLine.FindFirst();
        Assert.AreEqual('0000004217', BankReturnLine."Reference No.",
            'Expected the reference column to be stored character for character, leading zeros included');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadsTheAmountColumnAsAWholeNumberOfCents()
    var
        BankReturnLine: Record "Bank Return Line";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Cents: Integer;
    begin
        // [SCENARIO] The zero-padded amount column lands in the integer field as a number
        Initialize();
        Cents := Any.IntegerInRange(1, 99999);

        ImportReturnFile('TRYAL-R810;Lakeview Ltd;' + ZeroPadded(Cents, 10) + ';ACCP;Booked');

        GetReturnLine('TRYAL-R810', BankReturnLine);
        Assert.AreEqual(Cents, BankReturnLine."Amount (Cents)",
            'Expected the amount column to be read as the number of cents it spells out');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TreatsADelimitedValueContainingTheSeparatorAsOneColumn()
    var
        BankReturnLine: Record "Bank Return Line";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A payer name wrapped in double quotes may contain the field separator
        Initialize();

        ImportReturnFile('TRYAL-R811;"Meyer; Sons GmbH";0000000500;ACCP;Booked');

        GetReturnLine('TRYAL-R811', BankReturnLine);
        Assert.AreEqual('Meyer; Sons GmbH', BankReturnLine."Payer Name",
            'Expected the quoted payer name to arrive as one value, without its surrounding quotes and with the semicolon inside it intact');
        Assert.AreEqual('ACCP', BankReturnLine."Status Code",
            'Expected the columns after the quoted payer name to keep their positions');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadsNonAsciiCharactersOfTheUtf8File()
    var
        BankReturnLine: Record "Bank Return Line";
        Assert: Codeunit Assert;
        PayerName: Text;
    begin
        // [SCENARIO] A payer name carrying a u-umlaut survives the import unchanged
        Initialize();
        PayerName := 'Z' + Umlaut() + 'rich S' + Umlaut() + 'd AG';

        ImportReturnFile('TRYAL-R812;' + PayerName + ';0000000600;ACCP;Booked');

        GetReturnLine('TRYAL-R812', BankReturnLine);
        Assert.AreEqual(PayerName, BankReturnLine."Payer Name",
            'Expected the payer name to be read back exactly as written, so the file must be read as UTF-8');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesAnEmptyColumnEmpty()
    var
        BankReturnLine: Record "Bank Return Line";
        Assert: Codeunit Assert;
        Payload: TextBuilder;
    begin
        // [SCENARIO] An accepted line carries no bank message at all
        Initialize();
        Payload.AppendLine('TRYAL-R813;Lakeview Ltd;0000000750;ACCP;');
        Payload.Append('TRYAL-R814;Bergen Marine;0000000900;RJCT;Account closed');

        ImportReturnFile(Payload.ToText());

        GetReturnLine('TRYAL-R813', BankReturnLine);
        Assert.AreEqual('', BankReturnLine."Bank Message",
            'Expected a column with nothing between its separators to arrive as an empty value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoresTheBankMessageOfARejectedLine()
    var
        BankReturnLine: Record "Bank Return Line";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        BankMessage: Text;
    begin
        // [SCENARIO] The fifth column of a rejected line is stored as the bank message
        Initialize();
        BankMessage := 'Account closed ' + Any.AlphabeticText(8);

        ImportReturnFile('TRYAL-R815;Bergen Marine;0000000900;RJCT;' + BankMessage);

        GetReturnLine('TRYAL-R815', BankReturnLine);
        Assert.AreEqual(BankMessage, BankReturnLine."Bank Message",
            'Expected the fifth column of the return file line to be stored in "Bank Message"');
    end;

    local procedure Initialize()
    var
        PaymentBatchLine: Record "Payment Batch Line";
        BankReturnLine: Record "Bank Return Line";
    begin
        PaymentBatchLine.DeleteAll();
        BankReturnLine.DeleteAll();
    end;

    local procedure AddPaymentLine(LineNo: Integer; RecipientNo: Code[10]; RecipientName: Text[30]; AmountToPay: Decimal; DueDate: Date)
    var
        PaymentBatchLine: Record "Payment Batch Line";
    begin
        PaymentBatchLine.Init();
        PaymentBatchLine."Line No." := LineNo;
        PaymentBatchLine."Recipient No." := RecipientNo;
        PaymentBatchLine."Recipient Name" := RecipientName;
        PaymentBatchLine.Amount := AmountToPay;
        PaymentBatchLine."Due Date" := DueDate;
        PaymentBatchLine.Insert();
    end;

    local procedure ExportedFileLines(): List of [Text]
    var
        TempBlob: Codeunit "Temp Blob";
        FileOutStream: OutStream;
        FileInStream: InStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"Payment Batch Export", FileOutStream);
        TempBlob.CreateInStream(FileInStream, TextEncoding::UTF8);
        exit(NonEmptyLines(FileInStream));
    end;

    local procedure ImportReturnFile(Payload: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileOutStream: OutStream;
        FileInStream: InStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);
        FileOutStream.WriteText(Payload);
        TempBlob.CreateInStream(FileInStream, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"Bank Return Import", FileInStream);
    end;

    local procedure GetReturnLine(ReferenceNo: Code[20]; var BankReturnLine: Record "Bank Return Line")
    var
        Assert: Codeunit Assert;
        AllReturnLines: Record "Bank Return Line";
    begin
        Assert.IsTrue(BankReturnLine.Get(ReferenceNo),
            StrSubstNo('Expected the return file line with reference %1 to be imported as a "Bank Return Line"; the import created %2 record(s)',
                ReferenceNo, AllReturnLines.Count()));
    end;

    // The record separator of the exported file is not part of the contract, so
    // blank lines and a trailing line break are dropped before comparing. Neither
    // is the encoding: an XMLport exporting as UTF8 opens the stream with a byte
    // order mark, which is skipped instead of becoming part of the first record.
    local procedure NonEmptyLines(var FileInStream: InStream): List of [Text]
    var
        Lines: List of [Text];
        CurrentLine: TextBuilder;
        FirstBytes: array[3] of Byte;
        FirstByteCount: Integer;
        Position: Integer;
        NextByte: Byte;
    begin
        while (FirstByteCount < 3) and not FileInStream.EOS() do begin
            FirstByteCount += 1;
            FileInStream.Read(FirstBytes[FirstByteCount]);
        end;
        if not IsByteOrderMark(FirstBytes, FirstByteCount) then
            for Position := 1 to FirstByteCount do
                AppendFileByte(FirstBytes[Position], CurrentLine, Lines);
        while not FileInStream.EOS() do begin
            FileInStream.Read(NextByte);
            AppendFileByte(NextByte, CurrentLine, Lines);
        end;
        if CurrentLine.Length() > 0 then
            Lines.Add(CurrentLine.ToText());
        exit(Lines);
    end;

    local procedure IsByteOrderMark(FirstBytes: array[3] of Byte; FirstByteCount: Integer): Boolean
    begin
        exit((FirstByteCount = 3) and (FirstBytes[1] = 239) and (FirstBytes[2] = 187) and (FirstBytes[3] = 191));
    end;

    local procedure AppendFileByte(NextByte: Byte; var CurrentLine: TextBuilder; var Lines: List of [Text])
    var
        NextChar: Char;
    begin
        if NextByte = 10 then begin
            if CurrentLine.Length() > 0 then
                Lines.Add(CurrentLine.ToText());
            CurrentLine.Clear();
            exit;
        end;
        if NextByte = 13 then
            exit;
        NextChar := NextByte;
        CurrentLine.Append(Format(NextChar));
    end;

    local procedure LineAt(Lines: List of [Text]; Index: Integer): Text
    begin
        if (Index < 1) or (Index > Lines.Count()) then
            exit(StrSubstNo('<the exported file has no record %1 — it holds %2>', Index, DescribeLines(Lines)));
        exit(Lines.Get(Index));
    end;

    local procedure Column(Line: Text; StartPosition: Integer; ColumnWidth: Integer): Text
    begin
        if StrLen(Line) < StartPosition then
            exit('');
        exit(CopyStr(Line, StartPosition, ColumnWidth));
    end;

    local procedure DescribeLines(Lines: List of [Text]): Text
    var
        Description: TextBuilder;
        Line: Text;
        IsFirst: Boolean;
    begin
        Description.Append(StrSubstNo('%1 record(s): [', Lines.Count()));
        IsFirst := true;
        foreach Line in Lines do begin
            if not IsFirst then
                Description.Append(', ');
            Description.Append('"' + Line + '"');
            IsFirst := false;
        end;
        Description.Append(']');
        exit(Description.ToText());
    end;

    local procedure ZeroPadded(Value: Integer; ColumnWidth: Integer): Text
    var
        Digits: Text;
    begin
        Digits := Format(Value, 0, 9);
        exit(PadStr('', ColumnWidth - StrLen(Digits), '0') + Digits);
    end;

    local procedure Umlaut(): Text
    var
        UmlautChar: Char;
    begin
        UmlautChar := 252;
        exit(Format(UmlautChar));
    end;
}
