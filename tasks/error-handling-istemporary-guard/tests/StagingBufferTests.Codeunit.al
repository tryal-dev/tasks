codeunit 50900 "Staging Buffer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddLineRefusesARecordThatIsNotTemporary()
    var
        ImportStagingLine: Record "Import Staging Line";
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
    begin
        asserterror StagingBuffer.AddLine(ImportStagingLine, 'TRYAL-REAL', 1);

        Assert.ExpectedError('must be temporary');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ProcessBufferRefusesARecordThatIsNotTemporary()
    var
        ImportStagingLine: Record "Import Staging Line";
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
    begin
        asserterror StagingBuffer.ProcessBuffer(ImportStagingLine);

        Assert.ExpectedError('must be temporary');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddLineInsertsTheFirstLineIntoTheBuffer()
    var
        TempImportStagingLine: Record "Import Staging Line" temporary;
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemCode: Code[20];
        Quantity: Decimal;
    begin
        ItemCode := CopyStr(UpperCase(Any.AlphanumericText(MaxStrLen(ItemCode))), 1, MaxStrLen(ItemCode));
        Quantity := Any.DecimalInRange(1, 999, 2);

        StagingBuffer.AddLine(TempImportStagingLine, ItemCode, Quantity);

        TempImportStagingLine.Reset();
        Assert.AreEqual(1, TempImportStagingLine.Count(), 'Expected exactly one line in the buffer after the first AddLine');
        Assert.IsTrue(TempImportStagingLine.Get(1), 'Expected the first line added to an empty buffer to get "Line No." 1');
        Assert.AreEqual(ItemCode, TempImportStagingLine."Item Code", 'Expected AddLine to store the given item code on the buffer line');
        Assert.AreEqual(Quantity, TempImportStagingLine.Quantity, 'Expected AddLine to store the given quantity on the buffer line');
        Assert.IsFalse(TempImportStagingLine.Processed, 'Expected a freshly added buffer line to start with Processed = false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddLineContinuesNumberingFromTheHighestLine()
    var
        TempImportStagingLine: Record "Import Staging Line" temporary;
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
    begin
        SeedBufferLine(TempImportStagingLine, 2, 1);
        SeedBufferLine(TempImportStagingLine, 5, 1);
        // Reposition away from the highest row: rule 2 promises highest + 1, not current position + 1.
        TempImportStagingLine.Get(2);

        StagingBuffer.AddLine(TempImportStagingLine, 'TRYAL-NEXT', 1);

        TempImportStagingLine.Reset();
        Assert.AreEqual(3, TempImportStagingLine.Count(), 'Expected AddLine to append one line to the buffer that already held lines 2 and 5');
        TempImportStagingLine.FindLast();
        Assert.AreEqual(6, TempImportStagingLine."Line No.", 'Expected the new line to continue from the highest existing "Line No." (5 + 1 = 6), regardless of which row the variable was positioned on');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddLineKeepsThePhysicalTableEmpty()
    var
        ImportStagingLine: Record "Import Staging Line";
        TempImportStagingLine: Record "Import Staging Line" temporary;
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        StagingBuffer.AddLine(TempImportStagingLine, 'TRYAL-MEM', Any.DecimalInRange(1, 999, 2));

        Assert.IsTrue(ImportStagingLine.IsEmpty(),
            StrSubstNo('Expected the physical Import Staging Line table to stay empty after AddLine, found %1 row(s) — the API must write only to the in-memory buffer', ImportStagingLine.Count()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ProcessBufferMarksEveryBufferRowProcessed()
    var
        TempImportStagingLine: Record "Import Staging Line" temporary;
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineNo: Integer;
    begin
        for LineNo := 1 to 3 do
            SeedBufferLine(TempImportStagingLine, LineNo, Any.DecimalInRange(1, 999, 2));

        StagingBuffer.ProcessBuffer(TempImportStagingLine);

        TempImportStagingLine.Reset();
        TempImportStagingLine.FindSet();
        repeat
            Assert.IsTrue(TempImportStagingLine.Processed,
                StrSubstNo('Expected ProcessBuffer to set Processed on every buffer row, but line %1 is still unprocessed', TempImportStagingLine."Line No."));
        until TempImportStagingLine.Next() = 0;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ProcessBufferReturnsTheTotalQuantity()
    var
        TempImportStagingLine: Record "Import Staging Line" temporary;
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Quantity: Decimal;
        ExpectedTotal: Decimal;
        LineNo: Integer;
    begin
        for LineNo := 1 to 3 do begin
            Quantity := Any.DecimalInRange(1, 999, 2);
            ExpectedTotal += Quantity;
            SeedBufferLine(TempImportStagingLine, LineNo, Quantity);
        end;

        Assert.AreEqual(ExpectedTotal, StagingBuffer.ProcessBuffer(TempImportStagingLine),
            'Expected ProcessBuffer to return the sum of Quantity over all buffer rows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ProcessBufferReturnsZeroForAnEmptyBuffer()
    var
        TempImportStagingLine: Record "Import Staging Line" temporary;
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
    begin
        // Called directly: an error raised for the empty buffer fails the test — rule 3 says an empty buffer is not an error.
        Assert.AreEqual(0.0, StagingBuffer.ProcessBuffer(TempImportStagingLine),
            'Expected ProcessBuffer to return 0 for an empty buffer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ProcessBufferKeepsThePhysicalTableEmpty()
    var
        ImportStagingLine: Record "Import Staging Line";
        TempImportStagingLine: Record "Import Staging Line" temporary;
        StagingBuffer: Codeunit "Staging Buffer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineNo: Integer;
    begin
        for LineNo := 1 to 3 do
            SeedBufferLine(TempImportStagingLine, LineNo, Any.DecimalInRange(1, 999, 2));

        StagingBuffer.ProcessBuffer(TempImportStagingLine);

        Assert.IsTrue(ImportStagingLine.IsEmpty(),
            StrSubstNo('Expected the physical Import Staging Line table to stay empty after ProcessBuffer, found %1 row(s) — the API must modify only the in-memory buffer', ImportStagingLine.Count()));
    end;

    local procedure SeedBufferLine(var TempImportStagingLine: Record "Import Staging Line" temporary; LineNo: Integer; Quantity: Decimal)
    begin
        TempImportStagingLine.Init();
        TempImportStagingLine."Line No." := LineNo;
        TempImportStagingLine."Item Code" := 'TRYAL-SEED';
        TempImportStagingLine.Quantity := Quantity;
        TempImportStagingLine.Insert();
    end;
}
