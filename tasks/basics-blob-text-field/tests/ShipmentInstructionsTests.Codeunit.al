codeunit 50900 "Shipment Instructions Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        UnicodeSampleTxt: Label 'Zürich — O''Brien & Søn, Łódź (€25 COD)', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoresFiveThousandCharactersInTheBlob()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
        LongText: Text;
    begin
        // [SCENARIO] SetInstructions stores a text far beyond the 2,048-character ceiling of a Text field
        // [GIVEN] a shipment note and a generated 5,000-character text
        CreateNote('TRYAL-B1');
        LongText := GenerateWords(5000);

        // [WHEN] storing the text
        ShipmentInstructions.SetInstructions('TRYAL-B1', LongText);

        // [THEN] the Blob, read straight from the table as UTF-8, holds the whole text
        AssertSameText(LongText, ReadBlobDirectly('TRYAL-B1'),
            'Expected SetInstructions to write all 5,000 characters into "Delivery Instructions" and save the record — writing to the stream changes only your record variable until Modify');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesTheRestOfTheNoteUntouched()
    var
        ShipmentNote: Record "Shipment Note";
        ShipmentInstructions: Codeunit "Shipment Instructions";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] SetInstructions changes only the Blob — the note's other fields survive the save
        // [GIVEN] a shipment note with a ship-to name
        CreateNote('TRYAL-B11');

        // [WHEN] storing instructions on it
        ShipmentInstructions.SetInstructions('TRYAL-B11', 'Leave at the loading bay.');

        // [THEN] the ship-to name is still on the note
        ShipmentNote.Get('TRYAL-B11');
        Assert.AreEqual('TRYAL Northgate Depot', ShipmentNote."Ship-to Name",
            'Expected SetInstructions to change only "Delivery Instructions" — the rest of the note must stay as it was. Fetch the row with Get before writing to it; a record variable built from the number alone saves blanks into every other field on Modify');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadsTheStoredBlobFromTheTable()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
        StoredText: Text;
    begin
        // [SCENARIO] GetInstructions returns what the Blob holds in the table, not what a record variable happens to carry
        // [GIVEN] a note whose Blob was filled straight from the table with a 3,000-character text
        CreateNote('TRYAL-B2');
        StoredText := GenerateWords(3000);
        WriteBlobDirectly('TRYAL-B2', StoredText);

        // [WHEN] reading the instructions
        // [THEN] the whole stored text comes back
        AssertSameText(StoredText, ShipmentInstructions.GetInstructions('TRYAL-B2'),
            'Expected GetInstructions to return the 3,000-character text stored in the Blob — a record fetched with Get carries an empty Blob until CalcFields loads it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoresNonAsciiCharactersAsUtf8()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
    begin
        // [SCENARIO] Characters outside ASCII survive the write because the Blob is written as UTF-8
        // [GIVEN] a shipment note
        CreateNote('TRYAL-B3');

        // [WHEN] storing a text with an umlaut, an em dash, an apostrophe, Nordic and Polish letters and a euro sign
        ShipmentInstructions.SetInstructions('TRYAL-B3', UnicodeSampleTxt);

        // [THEN] the Blob, read straight from the table as UTF-8, holds exactly that text
        AssertSameText(UnicodeSampleTxt, ReadBlobDirectly('TRYAL-B3'),
            'Expected the non-ASCII characters to be stored intact — the Blob is read back as UTF-8, and a stream created without TextEncoding::UTF8 (the default is MSDos) stores different bytes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadsNonAsciiCharactersAsUtf8()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
    begin
        // [SCENARIO] Characters outside ASCII survive the read because the Blob is read as UTF-8
        // [GIVEN] a note whose Blob was filled straight from the table as UTF-8
        CreateNote('TRYAL-B4');
        WriteBlobDirectly('TRYAL-B4', UnicodeSampleTxt);

        // [WHEN] reading the instructions
        // [THEN] every character comes back as written
        AssertSameText(UnicodeSampleTxt, ShipmentInstructions.GetInstructions('TRYAL-B4'),
            'Expected GetInstructions to decode the UTF-8 bytes in the Blob — an InStream created without TextEncoding::UTF8 reads them as MSDos and mangles every non-ASCII character');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundTripsLineBreaksExactly()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
        Any: Codeunit Any;
        MultiLineText: Text;
    begin
        // [SCENARIO] A multi-line text comes back with every line break in place
        // [GIVEN] a note and a text with CRLF breaks, an empty line and a bare LF
        CreateNote('TRYAL-B5');
        MultiLineText := 'Ring twice and wait.' + Crlf()
            + 'If nobody answers, leave the parcel with the neighbour at no. 12.' + Crlf()
            + Crlf()
            + 'Gate code: ' + Format(Any.IntegerInRange(1000, 9999)) + Lf()
            + 'Do not ring after 20:00.';

        // [WHEN] storing the text and reading it back
        ShipmentInstructions.SetInstructions('TRYAL-B5', MultiLineText);

        // [THEN] the text is identical, line breaks included
        AssertSameText(MultiLineText, ShipmentInstructions.GetInstructions('TRYAL-B5'),
            'Expected every line break to come back exactly as stored — ReadText stops at the first line ending, while Read into a Text variable reads to the end of the stream');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReplacesEarlierInstructions()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
    begin
        // [SCENARIO] A second SetInstructions on the same note replaces the first text entirely
        // [GIVEN] a note that already holds a long generated text
        CreateNote('TRYAL-B6');
        ShipmentInstructions.SetInstructions('TRYAL-B6', GenerateWords(300));

        // [WHEN] storing a shorter text on the same note
        ShipmentInstructions.SetInstructions('TRYAL-B6', 'Fragile, this way up.');

        // [THEN] only the new text is stored
        AssertSameText('Fragile, this way up.', ShipmentInstructions.GetInstructions('TRYAL-B6'),
            'Expected the second SetInstructions to replace the first text entirely — nothing of the earlier text may remain');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyTextClearsTheInstructions()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Storing an empty text removes the instructions from the note
        // [GIVEN] a note that holds instructions
        CreateNote('TRYAL-B7');
        ShipmentInstructions.SetInstructions('TRYAL-B7', 'Call on arrival.');

        // [WHEN] storing an empty text
        ShipmentInstructions.SetInstructions('TRYAL-B7', '');

        // [THEN] the note has no instructions any more
        Assert.IsFalse(ShipmentInstructions.HasInstructions('TRYAL-B7'),
            'Expected HasInstructions to be false after storing an empty text — an empty text must clear the Blob, not leave a value behind');
        AssertSameText('', ShipmentInstructions.GetInstructions('TRYAL-B7'),
            'Expected GetInstructions to return the empty text after the instructions were cleared');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasInstructionsIsTrueWhenTheBlobHoldsText()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] HasInstructions sees text that was stored in the Blob
        // [GIVEN] a note whose Blob was filled straight from the table
        CreateNote('TRYAL-B8');
        WriteBlobDirectly('TRYAL-B8', 'Call on arrival.');

        // [WHEN] asking whether the note has instructions
        // [THEN] the answer is true
        Assert.IsTrue(ShipmentInstructions.HasInstructions('TRYAL-B8'),
            'Expected HasInstructions to be true for a note whose Blob holds text — HasValue is false on a record variable that never fetched the Blob with CalcFields');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasInstructionsIsFalseForANoteWithoutInstructions()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A note that never received instructions reports none
        // [GIVEN] a bare note
        CreateNote('TRYAL-B9');

        // [WHEN] asking whether the note has instructions
        // [THEN] the answer is false
        Assert.IsFalse(ShipmentInstructions.HasInstructions('TRYAL-B9'),
            'Expected HasInstructions to be false for a note whose Blob was never written');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetInstructionsReturnsEmptyTextForANoteWithoutInstructions()
    var
        ShipmentInstructions: Codeunit "Shipment Instructions";
    begin
        // [SCENARIO] Reading a note that never received instructions yields the empty text, not an error
        // [GIVEN] a bare note
        CreateNote('TRYAL-B10');

        // [WHEN] reading the instructions
        // [THEN] the result is the empty text
        AssertSameText('', ShipmentInstructions.GetInstructions('TRYAL-B10'),
            'Expected GetInstructions to return the empty text for a note whose Blob was never written');
    end;

    local procedure CreateNote(NoteNo: Code[20])
    var
        ShipmentNote: Record "Shipment Note";
    begin
        ShipmentNote.Init();
        ShipmentNote."No." := NoteNo;
        ShipmentNote."Ship-to Name" := 'TRYAL Northgate Depot';
        ShipmentNote.Insert();
    end;

    // The tests write and read the Blob themselves so that each procedure is graded
    // against the table: a text kept in a codeunit variable instead of the Blob
    // would pass a plain Set-then-Get round trip.
    local procedure WriteBlobDirectly(NoteNo: Code[20]; Instructions: Text)
    var
        ShipmentNote: Record "Shipment Note";
        BlobOutStream: OutStream;
    begin
        ShipmentNote.Get(NoteNo);
        ShipmentNote."Delivery Instructions".CreateOutStream(BlobOutStream, TextEncoding::UTF8);
        BlobOutStream.WriteText(Instructions);
        ShipmentNote.Modify();
    end;

    local procedure ReadBlobDirectly(NoteNo: Code[20]): Text
    var
        ShipmentNote: Record "Shipment Note";
        BlobInStream: InStream;
        Stored: Text;
    begin
        ShipmentNote.Get(NoteNo);
        ShipmentNote.CalcFields("Delivery Instructions");
        if not ShipmentNote."Delivery Instructions".HasValue() then
            exit('');
        ShipmentNote."Delivery Instructions".CreateInStream(BlobInStream, TextEncoding::UTF8);
        BlobInStream.Read(Stored);
        exit(Stored);
    end;

    local procedure GenerateWords(Length: Integer): Text
    var
        Any: Codeunit Any;
        Words: TextBuilder;
    begin
        while Words.Length() < Length do begin
            Words.Append(Any.AlphabeticText(Any.IntegerInRange(2, 9)));
            Words.Append(' ');
        end;
        exit(CopyStr(Words.ToText(), 1, Length));
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

    // Assert.AreEqual would print both texts in full — 5,000 characters twice — so
    // the failure reports the lengths and a window around the first difference.
    local procedure AssertSameText(Expected: Text; Actual: Text; Context: Text)
    var
        Assert: Codeunit Assert;
        Position: Integer;
    begin
        Position := FirstDifference(Expected, Actual);
        if Position = 0 then
            exit;
        Assert.Fail(StrSubstNo('%1. Expected %2 characters but got %3; the texts first differ at position %4: expected "%5" but got "%6"',
            Context, StrLen(Expected), StrLen(Actual), Position, Excerpt(Expected, Position), Excerpt(Actual, Position)));
    end;

    local procedure FirstDifference(Expected: Text; Actual: Text): Integer
    var
        Index: Integer;
        SharedLength: Integer;
    begin
        SharedLength := StrLen(Expected);
        if StrLen(Actual) < SharedLength then
            SharedLength := StrLen(Actual);
        for Index := 1 to SharedLength do
            if Expected[Index] <> Actual[Index] then
                exit(Index);
        if StrLen(Expected) <> StrLen(Actual) then
            exit(SharedLength + 1);
        exit(0);
    end;

    local procedure Excerpt(Value: Text; Position: Integer): Text
    var
        StartAt: Integer;
    begin
        StartAt := Position - 15;
        if StartAt < 1 then
            StartAt := 1;
        if StartAt > StrLen(Value) then
            exit('');
        exit(MakeControlCharsVisible(CopyStr(Value, StartAt, 40)));
    end;

    // CR and LF render invisibly, so a lost or added line break would make expected
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
