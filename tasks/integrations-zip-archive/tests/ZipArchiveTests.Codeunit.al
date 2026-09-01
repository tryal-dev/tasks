codeunit 50900 "Zip Archive Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildArchiveProducesARealZipPayload()
    var
        Manager: Codeunit "Zip Archive Manager";
        ArchiveBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        Assert: Codeunit Assert;
        Documents: Dictionary of [Text, Text];
        ArchiveInStr: InStream;
    begin
        Documents.Add('manifest.txt', 'batch 2026-07');
        Documents.Add('invoices/INV-1001.txt', 'first invoice');

        Manager.BuildArchive(Documents, ArchiveBlob);

        ArchiveBlob.CreateInStream(ArchiveInStr);
        Assert.IsTrue(DataCompression.IsZip(ArchiveInStr),
            StrSubstNo('Expected BuildArchive to produce a payload an independent zip reader recognizes as a zip archive, got %1 bytes that are not one', ArchiveBlob.Length()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuiltArchiveContainsExactlyTheGivenEntryPaths()
    var
        Manager: Codeunit "Zip Archive Manager";
        ArchiveBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        Assert: Codeunit Assert;
        Documents: Dictionary of [Text, Text];
        EntryList: List of [Text];
        ArchiveInStr: InStream;
        ExpectedPath: Text;
    begin
        Documents.Add('invoices/2026/INV-1001.txt', 'first invoice');
        Documents.Add('invoices/2026/INV-1002.txt', 'second invoice');
        Documents.Add('manifest.txt', 'two invoices');

        Manager.BuildArchive(Documents, ArchiveBlob);

        ArchiveBlob.CreateInStream(ArchiveInStr);
        DataCompression.OpenZipArchive(ArchiveInStr, false);
        DataCompression.GetEntryList(EntryList);
        DataCompression.CloseZipArchive();
        Assert.AreEqual(3, EntryList.Count(),
            StrSubstNo('Expected the built archive to hold exactly one entry per document, got the entries: %1', JoinEntries(EntryList)));
        foreach ExpectedPath in Documents.Keys() do
            Assert.IsTrue(EntryList.Contains(ExpectedPath),
                StrSubstNo('Expected the built archive to hold an entry at the exact path %1 (folder separators included), got the entries: %2', ExpectedPath, JoinEntries(EntryList)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuiltArchiveEntriesRoundTripTheirContent()
    var
        Manager: Codeunit "Zip Archive Manager";
        ArchiveBlob: Codeunit "Temp Blob";
        EntryBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Documents: Dictionary of [Text, Text];
        ArchiveInStr: InStream;
        EntryOutStr: OutStream;
        EntryPath: Text;
    begin
        Documents.Add('contracts/2026/CON-77.txt', Any.AlphanumericText(64));
        Documents.Add('contracts/readme.txt', Any.AlphanumericText(37));
        // Non-ASCII content grades the "written as UTF-8" rule: a single-byte
        // codepage round-trip garbles these characters while passing ASCII.
        Documents.Add('contracts/notes.txt', 'Bücher — 42 €');

        Manager.BuildArchive(Documents, ArchiveBlob);

        ArchiveBlob.CreateInStream(ArchiveInStr);
        DataCompression.OpenZipArchive(ArchiveInStr, false);
        foreach EntryPath in Documents.Keys() do begin
            Clear(EntryBlob);
            EntryBlob.CreateOutStream(EntryOutStr);
            DataCompression.ExtractEntry(EntryPath, EntryOutStr);
            Assert.AreEqual(Documents.Get(EntryPath), ReadBlobText(EntryBlob),
                StrSubstNo('Expected the entry %1 to round-trip its document content through the archive unchanged', EntryPath));
        end;
        DataCompression.CloseZipArchive();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildingAnEmptyDocumentSetYieldsAnArchiveWithNoEntries()
    var
        Manager: Codeunit "Zip Archive Manager";
        ArchiveBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        Assert: Codeunit Assert;
        Documents: Dictionary of [Text, Text];
        EntryList: List of [Text];
        ArchiveInStr: InStream;
    begin
        Manager.BuildArchive(Documents, ArchiveBlob);

        ArchiveBlob.CreateInStream(ArchiveInStr);
        DataCompression.OpenZipArchive(ArchiveInStr, false);
        DataCompression.GetEntryList(EntryList);
        DataCompression.CloseZipArchive();
        Assert.AreEqual(0, EntryList.Count(),
            StrSubstNo('Expected an empty document set to build a valid archive with zero entries, got the entries: %1', JoinEntries(EntryList)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListsEntriesOfAForeignZipInArchiveOrder()
    var
        Manager: Codeunit "Zip Archive Manager";
        ZipBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Paths: List of [Text];
        Contents: List of [Text];
        EntryList: List of [Text];
        i: Integer;
    begin
        Paths.Add('inbox/' + Any.AlphabeticText(8) + '/first.txt');
        Paths.Add('inbox/second.txt');
        Paths.Add('third.txt');
        for i := 1 to Paths.Count() do
            Contents.Add(Any.AlphanumericText(30));
        BuildZipWithTextEntries(Paths, Contents, ZipBlob);

        EntryList := Manager.ListEntries(ZipBlob);

        Assert.AreEqual(3, EntryList.Count(),
            StrSubstNo('Expected ListEntries to report every entry of an archive it did not build, got: %1', JoinEntries(EntryList)));
        for i := 1 to Paths.Count() do
            Assert.AreEqual(Paths.Get(i), EntryList.Get(i),
                StrSubstNo('Expected entry %1 of the list to be the full path in archive order, got the entries: %2', i, JoinEntries(EntryList)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtractsANamedDocumentWithExactContentAndByteCount()
    var
        Manager: Codeunit "Zip Archive Manager";
        ZipBlob: Codeunit "Temp Blob";
        DocumentBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Paths: List of [Text];
        Contents: List of [Text];
        ExtractedLength: Integer;
    begin
        Paths.Add('reports/summary.txt');
        Paths.Add('reports/details/full.txt');
        Contents.Add(Any.AlphanumericText(52));
        Contents.Add(Any.AlphanumericText(41));
        BuildZipWithTextEntries(Paths, Contents, ZipBlob);

        ExtractedLength := Manager.ExtractDocument(ZipBlob, 'reports/details/full.txt', DocumentBlob);

        Assert.AreEqual(Contents.Get(2), ReadBlobText(DocumentBlob),
            'Expected ExtractDocument to reproduce the named entry''s content exactly — not another entry''s');
        Assert.AreEqual(41, ExtractedLength,
            'Expected ExtractDocument to return the exact uncompressed byte count of the extracted entry');
        Assert.AreEqual(41, DocumentBlob.Length(),
            'Expected the extracted document blob to hold exactly the entry''s uncompressed bytes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtractsABinaryDocumentByteForByte()
    var
        Manager: Codeunit "Zip Archive Manager";
        ZipBlob: Codeunit "Temp Blob";
        EntryBlob: Codeunit "Temp Blob";
        DocumentBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        Base64Convert: Codeunit "Base64 Convert";
        Assert: Codeunit Assert;
        EntryInStr: InStream;
        DocInStr: InStream;
        EntryOutStr: OutStream;
        ExtractedLength: Integer;
    begin
        // Seeds 4 bytes (FE FF FE FF) that are not valid UTF-8 text.
        EntryBlob.CreateOutStream(EntryOutStr);
        Base64Convert.FromBase64('/v/+/w==', EntryOutStr);
        EntryBlob.CreateInStream(EntryInStr);
        DataCompression.CreateZipArchive();
        DataCompression.AddEntry(EntryInStr, 'scans/label.bin');
        DataCompression.SaveZipArchive(ZipBlob);
        DataCompression.CloseZipArchive();

        ExtractedLength := Manager.ExtractDocument(ZipBlob, 'scans/label.bin', DocumentBlob);

        Assert.AreEqual(4, ExtractedLength,
            'Expected ExtractDocument to return 4 for a 4-byte binary entry — raw bytes must not be reinterpreted through a text encoding');
        Assert.AreEqual(4, DocumentBlob.Length(),
            'Expected the extracted binary document to keep exactly its 4 raw bytes');
        DocumentBlob.CreateInStream(DocInStr);
        Assert.AreEqual('/v/+/w==', Base64Convert.ToBase64(DocInStr),
            'Expected the 4 binary bytes to survive extraction untouched (compared as base64), got a different byte sequence');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsAPlainTextPayloadUnchanged()
    var
        Manager: Codeunit "Zip Archive Manager";
        PayloadBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Content: Text;
    begin
        Content := 'Bücher — 42 € — ' + Any.AlphanumericText(80);
        WriteBlobText(PayloadBlob, Content);

        Assert.AreEqual(Content, Manager.GetDocumentText(PayloadBlob),
            'Expected a payload that is neither zip nor gzip to come back as its own text, unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecompressesAGZipPayloadToItsText()
    var
        Manager: Codeunit "Zip Archive Manager";
        SourceBlob: Codeunit "Temp Blob";
        PayloadBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SourceInStr: InStream;
        PayloadOutStr: OutStream;
        Content: Text;
    begin
        Content := Any.AlphanumericText(120);
        WriteBlobText(SourceBlob, Content);
        SourceBlob.CreateInStream(SourceInStr);
        PayloadBlob.CreateOutStream(PayloadOutStr);
        DataCompression.GZipCompress(SourceInStr, PayloadOutStr);

        Assert.AreEqual(Content, Manager.GetDocumentText(PayloadBlob),
            'Expected a gzip-compressed payload to be detected from its bytes and decompressed back to the original text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtractsTheDocumentTextFromAZipPayload()
    var
        Manager: Codeunit "Zip Archive Manager";
        PayloadBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Paths: List of [Text];
        Contents: List of [Text];
    begin
        Paths.Add('payload/document.txt');
        Contents.Add(Any.AlphanumericText(90));
        BuildZipWithTextEntries(Paths, Contents, PayloadBlob);

        Assert.AreEqual(Contents.Get(1), Manager.GetDocumentText(PayloadBlob),
            'Expected a zip payload to be detected from its bytes and its single document''s text returned');
    end;

    local procedure BuildZipWithTextEntries(Paths: List of [Text]; Contents: List of [Text]; var ZipBlob: Codeunit "Temp Blob")
    var
        DataCompression: Codeunit "Data Compression";
        EntryBlob: Codeunit "Temp Blob";
        EntryInStr: InStream;
        EntryOutStr: OutStream;
        i: Integer;
    begin
        DataCompression.CreateZipArchive();
        for i := 1 to Paths.Count() do begin
            Clear(EntryBlob);
            EntryBlob.CreateOutStream(EntryOutStr, TextEncoding::UTF8);
            EntryOutStr.WriteText(Contents.Get(i));
            EntryBlob.CreateInStream(EntryInStr);
            DataCompression.AddEntry(EntryInStr, Paths.Get(i));
        end;
        DataCompression.SaveZipArchive(ZipBlob);
        DataCompression.CloseZipArchive();
    end;

    local procedure WriteBlobText(var TargetBlob: Codeunit "Temp Blob"; Content: Text)
    var
        TargetOutStr: OutStream;
    begin
        // UTF-8 explicitly: one payload carries non-ASCII characters that a default single-byte encoding would garble.
        TargetBlob.CreateOutStream(TargetOutStr, TextEncoding::UTF8);
        TargetOutStr.WriteText(Content);
    end;

    local procedure ReadBlobText(var SourceBlob: Codeunit "Temp Blob"): Text
    var
        SourceInStr: InStream;
        Content: Text;
    begin
        SourceBlob.CreateInStream(SourceInStr, TextEncoding::UTF8);
        SourceInStr.ReadText(Content);
        exit(Content);
    end;

    local procedure JoinEntries(EntryList: List of [Text]): Text
    var
        EntryPath: Text;
        Joined: Text;
    begin
        foreach EntryPath in EntryList do begin
            if Joined <> '' then
                Joined += ', ';
            Joined += EntryPath;
        end;
        if Joined = '' then
            Joined := '(none)';
        exit(Joined);
    end;
}
