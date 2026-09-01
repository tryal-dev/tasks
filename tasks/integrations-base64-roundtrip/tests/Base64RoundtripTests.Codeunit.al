codeunit 50900 "Base64 Roundtrip Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodesKnownDocumentToTheExactBase64Text()
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
    begin
        WriteToBlob(TempBlob, 'Hello, World!');

        Assert.AreEqual('SGVsbG8sIFdvcmxkIQ==', Codec.EncodeDocument(TempBlob),
            'Expected the exact Base64 text for the 13-byte document "Hello, World!" — mind the two = padding characters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodesEveryPaddingShapeCorrectly()
    begin
        VerifyEncoding('M', 'TQ==');
        VerifyEncoding('Ma', 'TWE=');
        VerifyEncoding('Man', 'TWFu');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesKnownPayloadToTheOriginalBytes()
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
    begin
        Codec.DecodeDocument('SGVsbG8sIFdvcmxkIQ==', TempBlob);

        Assert.AreEqual('Hello, World!', ReadFromBlob(TempBlob),
            'Expected decoding SGVsbG8sIFdvcmxkIQ== to reproduce the original document "Hello, World!"');
        Assert.AreEqual(13, TempBlob.Length(),
            'Expected the decoded document to hold exactly 13 bytes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesEveryPaddingShapeCorrectly()
    begin
        VerifyDecoding('TQ==', 'M');
        VerifyDecoding('TWE=', 'Ma');
        VerifyDecoding('TWFu', 'Man');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesBinaryPayloadByteForByte()
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
    begin
        Codec.DecodeDocument('/////w==', TempBlob);

        Assert.AreEqual(4, TempBlob.Length(),
            'Expected decoding /////w== to produce exactly 4 raw bytes — the payload is binary, not text, and must not be reinterpreted through a text encoding');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodesBinaryDocumentToTheExactBase64Text()
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
    begin
        WriteBinaryToBlob(TempBlob, '/v/+/w==');

        Assert.AreEqual('/v/+/w==', Codec.EncodeDocument(TempBlob),
            'Expected the exact Base64 text for a 4-byte binary document — raw bytes that are not valid text must survive encoding untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodedPayloadIsASingleLineOfExactLength()
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Encoded: Text;
        CrLf: Text[2];
    begin
        CrLf := '  ';
        CrLf[1] := 13;
        CrLf[2] := 10;
        WriteToBlob(TempBlob, Any.AlphanumericText(300));

        Encoded := Codec.EncodeDocument(TempBlob);

        Assert.AreEqual(400, StrLen(Encoded),
            'Expected a 300-byte document to encode to exactly 400 Base64 characters');
        Assert.AreEqual(DelChr(Encoded, '=', CrLf), Encoded,
            'Expected the Base64 payload to be a single line — no CR or LF characters anywhere');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundTripReproducesAGeneratedDocumentByteForByte()
    var
        Codec: Codeunit "Base64 Document Codec";
        SourceBlob: Codeunit "Temp Blob";
        TargetBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Payload: Text;
    begin
        Payload := Any.AlphanumericText(250);
        WriteToBlob(SourceBlob, Payload);

        Codec.DecodeDocument(Codec.EncodeDocument(SourceBlob), TargetBlob);

        Assert.AreEqual(Payload, ReadFromBlob(TargetBlob),
            'Expected encode followed by decode to reproduce the original document exactly');
        Assert.AreEqual(SourceBlob.Length(), TargetBlob.Length(),
            'Expected the round-tripped document to keep the exact byte count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodingAnEmptyDocumentYieldsEmptyText()
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', Codec.EncodeDocument(TempBlob),
            'Expected an empty document to encode to an empty Base64 text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodingEmptyTextYieldsAnEmptyDocument()
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
    begin
        Codec.DecodeDocument('', TempBlob);

        Assert.AreEqual(0, TempBlob.Length(),
            'Expected decoding an empty payload to leave the document empty — zero bytes');
    end;

    local procedure VerifyEncoding(Content: Text; ExpectedBase64: Text)
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
    begin
        WriteToBlob(TempBlob, Content);
        Assert.AreEqual(ExpectedBase64, Codec.EncodeDocument(TempBlob),
            StrSubstNo('Expected the %1-byte document %2 to encode with the correct = padding', StrLen(Content), Content));
    end;

    local procedure VerifyDecoding(Base64Payload: Text; ExpectedContent: Text)
    var
        Codec: Codeunit "Base64 Document Codec";
        TempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
    begin
        Codec.DecodeDocument(Base64Payload, TempBlob);
        Assert.AreEqual(ExpectedContent, ReadFromBlob(TempBlob),
            StrSubstNo('Expected decoding %1 to yield %2', Base64Payload, ExpectedContent));
        Assert.AreEqual(StrLen(ExpectedContent), TempBlob.Length(),
            StrSubstNo('Expected decoding %1 to produce exactly %2 bytes', Base64Payload, StrLen(ExpectedContent)));
    end;

    local procedure WriteToBlob(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        OutStr: OutStream;
    begin
        // UTF-8 so the graded byte counts are exactly the ASCII character counts.
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);
    end;

    local procedure WriteBinaryToBlob(var TempBlob: Codeunit "Temp Blob"; Base64Bytes: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
    begin
        // Seeds bytes that are not valid UTF-8 without going through the codec under test.
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(Base64Bytes, OutStr);
    end;

    local procedure ReadFromBlob(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Content: Text;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Content);
        exit(Content);
    end;
}
