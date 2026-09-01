codeunit 50900 "Init Keeps Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SuspectReadingTxt: Label 'Suspect reading', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportStoresEveryValueInOrder()
    var
        MeterReading: Record "Meter Reading";
        MeterReadingImport: Codeunit "Meter Reading Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Values: List of [Decimal];
        ReadOn: Date;
        i: Integer;
    begin
        MeterReading.DeleteAll();
        for i := 1 to 3 do
            Values.Add(Any.DecimalInRange(1, 9999, 2));
        ReadOn := Any.DateInRange(365);

        MeterReadingImport.Import(Values, ReadOn);

        Assert.AreEqual(3, MeterReading.Count(), 'Expected Import to insert exactly one "Meter Reading" row per value in the list');
        for i := 1 to 3 do begin
            Assert.IsTrue(MeterReading.Get(i), StrSubstNo('Expected a "Meter Reading" row with Entry No. %1 — an empty table numbers its rows 1, 2, 3', i));
            Assert.AreEqual(Values.Get(i), MeterReading."Reading Value", StrSubstNo('Expected row %1 to carry element %1 of the list — rows follow list order', i));
            Assert.AreEqual(ReadOn, MeterReading."Read On", StrSubstNo('Expected row %1 to be stamped with the ReadOn date passed to Import', i));
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroOrNegativeReadingGetsTheSuspectRemark()
    var
        MeterReading: Record "Meter Reading";
        MeterReadingImport: Codeunit "Meter Reading Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Values: List of [Decimal];
    begin
        MeterReading.DeleteAll();
        Values.Add(0.01);
        Values.Add(0);
        Values.Add(-Any.DecimalInRange(1, 500, 2));

        MeterReadingImport.Import(Values, WorkDate());

        MeterReading.Get(1);
        Assert.AreEqual('', MeterReading.Remark, 'Expected no remark on a reading just above zero (0.01) — only zero or less is suspect');
        MeterReading.Get(2);
        Assert.AreEqual(SuspectReadingTxt, MeterReading.Remark, 'Expected a reading of exactly zero to get the remark "Suspect reading"');
        MeterReading.Get(3);
        Assert.AreEqual(SuspectReadingTxt, MeterReading.Remark, 'Expected a negative reading to get the remark "Suspect reading"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemarkDoesNotLeakIntoTheFollowingRow()
    var
        MeterReading: Record "Meter Reading";
        MeterReadingImport: Codeunit "Meter Reading Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Values: List of [Decimal];
    begin
        MeterReading.DeleteAll();
        Values.Add(Any.DecimalInRange(1, 9999, 2));
        Values.Add(0);
        Values.Add(Any.DecimalInRange(1, 9999, 2));

        MeterReadingImport.Import(Values, WorkDate());

        MeterReading.Get(3);
        Assert.AreEqual('', MeterReading.Remark, 'Expected the third row to have a blank Remark — only the second reading was suspect. A remark that survives into the next row means the record variable is not reset between rows: Init() clears every non-key field');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitAlonePutsStatusAtPending()
    var
        MeterReading: Record "Meter Reading";
        Assert: Codeunit Assert;
    begin
        MeterReading.Init();

        Assert.IsTrue(MeterReading.Status = "Meter Reading Status"::Pending,
            StrSubstNo('Expected Init() on a bare "Meter Reading" record to yield Status = Pending — declare InitValue = Pending on the Status field. Got "%1" (ordinal %2)', MeterReading.Status, MeterReading.Status.AsInteger()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EveryImportedRowIsPending()
    var
        MeterReading: Record "Meter Reading";
        MeterReadingImport: Codeunit "Meter Reading Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Values: List of [Decimal];
        i: Integer;
    begin
        MeterReading.DeleteAll();
        for i := 1 to 3 do
            Values.Add(Any.DecimalInRange(1, 9999, 2));

        MeterReadingImport.Import(Values, WorkDate());

        Assert.AreEqual(3, MeterReading.Count(), 'Expected Import to insert exactly one "Meter Reading" row per value in the list');
        MeterReading.FindSet();
        repeat
            Assert.IsTrue(MeterReading.Status = "Meter Reading Status"::Pending,
                StrSubstNo('Expected every imported row to have Status = Pending, but row %1 has "%2" (ordinal %3)', MeterReading."Entry No.", MeterReading.Status, MeterReading.Status.AsInteger()));
        until MeterReading.Next() = 0;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NumberingContinuesAfterTheHighestExistingEntry()
    var
        MeterReading: Record "Meter Reading";
        MeterReadingImport: Codeunit "Meter Reading Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Values: List of [Decimal];
    begin
        MeterReading.DeleteAll();
        SeedReading(4);
        SeedReading(9);
        Values.Add(Any.DecimalInRange(1, 9999, 2));
        Values.Add(Any.DecimalInRange(1, 9999, 2));

        MeterReadingImport.Import(Values, WorkDate());

        Assert.AreEqual(4, MeterReading.Count(), 'Expected the two seeded rows plus the two imported ones — an import that reuses an existing Entry No. or skips a value is wrong');
        MeterReading.FindLast();
        Assert.AreEqual(11, MeterReading."Entry No.", 'Expected numbering to continue after the highest existing Entry No. (9), so the imported rows are 10 and 11');
        MeterReading.Get(10);
        Assert.AreEqual(Values.Get(1), MeterReading."Reading Value", 'Expected the first imported value on Entry No. 10');
        MeterReading.Get(11);
        Assert.AreEqual(Values.Get(2), MeterReading."Reading Value", 'Expected the second imported value on Entry No. 11');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondImportContinuesAfterTheFirst()
    var
        MeterReading: Record "Meter Reading";
        MeterReadingImport: Codeunit "Meter Reading Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstBatch: List of [Decimal];
        SecondBatch: List of [Decimal];
        i: Integer;
    begin
        MeterReading.DeleteAll();
        for i := 1 to 3 do
            FirstBatch.Add(Any.DecimalInRange(1, 9999, 2));
        for i := 1 to 2 do
            SecondBatch.Add(Any.DecimalInRange(1, 9999, 2));
        MeterReadingImport.Import(FirstBatch, WorkDate());

        MeterReadingImport.Import(SecondBatch, WorkDate());

        Assert.AreEqual(5, MeterReading.Count(), 'Expected the second Import call to add its two rows to the three from the first call');
        Assert.IsTrue(MeterReading.Get(4), 'Expected the second Import call to continue at Entry No. 4 instead of restarting at 1');
        Assert.AreEqual(SecondBatch.Get(1), MeterReading."Reading Value", 'Expected the first value of the second batch on Entry No. 4');
        Assert.IsTrue(MeterReading.Get(5), 'Expected the second Import call to produce Entry No. 5 for its second value');
        Assert.AreEqual(SecondBatch.Get(2), MeterReading."Reading Value", 'Expected the second value of the second batch on Entry No. 5');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyListInsertsNothing()
    var
        MeterReading: Record "Meter Reading";
        MeterReadingImport: Codeunit "Meter Reading Import";
        Assert: Codeunit Assert;
        Values: List of [Decimal];
    begin
        MeterReading.DeleteAll();

        MeterReadingImport.Import(Values, WorkDate());

        Assert.AreEqual(0, MeterReading.Count(), 'Expected an empty list to insert no rows and raise no error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusOrdinalsMatchTheStatement()
    var
        Status: Enum "Meter Reading Status";
        Assert: Codeunit Assert;
    begin
        Status := "Meter Reading Status"::" ";
        Assert.AreEqual(0, Status.AsInteger(), 'Expected the blank value to be declared with ordinal 0');
        Status := "Meter Reading Status"::Pending;
        Assert.AreEqual(1, Status.AsInteger(), 'Expected Pending to be declared with ordinal 1 — not 0, or InitValue would have nothing to do');
        Status := "Meter Reading Status"::Verified;
        Assert.AreEqual(2, Status.AsInteger(), 'Expected Verified to be declared with ordinal 2');
    end;

    local procedure SeedReading(EntryNo: Integer)
    var
        MeterReading: Record "Meter Reading";
    begin
        MeterReading.Init();
        MeterReading."Entry No." := EntryNo;
        MeterReading."Reading Value" := 1;
        MeterReading.Insert();
    end;
}
