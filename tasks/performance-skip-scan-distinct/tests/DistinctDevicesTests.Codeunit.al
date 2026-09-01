codeunit 50900 "Distinct Devices Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CollectsEachDeviceCodeExactlyOnce()
    var
        DeviceDirectory: Codeunit "Device Directory";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DeviceCodes: List of [Code[20]];
        DeviceA: Code[20];
        DeviceB: Code[20];
        DeviceC: Code[20];
        EntryNo: Integer;
        i: Integer;
    begin
        DeviceA := CopyStr(StrSubstNo('TRYAL-%1', Any.IntegerInRange(100, 399)), 1, MaxStrLen(DeviceA));
        DeviceB := CopyStr(StrSubstNo('TRYAL-%1', Any.IntegerInRange(400, 699)), 1, MaxStrLen(DeviceB));
        DeviceC := CopyStr(StrSubstNo('TRYAL-%1', Any.IntegerInRange(700, 999)), 1, MaxStrLen(DeviceC));
        EntryNo := 1000;
        for i := 1 to Any.IntegerInRange(2, 4) do begin
            MockReading(EntryNo, DeviceB);
            MockReading(EntryNo, DeviceA);
            MockReading(EntryNo, DeviceC);
        end;

        DeviceDirectory.GetDeviceCodes(DeviceCodes);

        Assert.AreEqual(3, DeviceCodes.Count(),
            'Expected exactly one list entry per distinct device, however many readings each device has');
        Assert.IsTrue(DeviceCodes.Contains(DeviceA),
            StrSubstNo('Expected device %1 to be in the list — it has readings', DeviceA));
        Assert.IsTrue(DeviceCodes.Contains(DeviceB),
            StrSubstNo('Expected device %1 to be in the list — it has readings', DeviceB));
        Assert.IsTrue(DeviceCodes.Contains(DeviceC),
            StrSubstNo('Expected device %1 to be in the list — it has readings', DeviceC));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsCodesInAscendingOrderWhateverTheInsertOrder()
    var
        DeviceDirectory: Codeunit "Device Directory";
        Assert: Codeunit Assert;
        DeviceCodes: List of [Code[20]];
        EntryNo: Integer;
        i: Integer;
    begin
        // the device that sorts first is inserted last, so "Entry No." order is not sorted order
        EntryNo := 2000;
        for i := 1 to 2 do
            MockReading(EntryNo, 'TRYAL-O-CHARLIE');
        for i := 1 to 2 do
            MockReading(EntryNo, 'TRYAL-O-BRAVO');
        for i := 1 to 2 do
            MockReading(EntryNo, 'TRYAL-O-ALPHA');

        DeviceDirectory.GetDeviceCodes(DeviceCodes);

        Assert.AreEqual(3, DeviceCodes.Count(),
            'Expected exactly one list entry per distinct device before judging the order');
        Assert.AreEqual('TRYAL-O-ALPHA', Format(DeviceCodes.Get(1)),
            'Expected position 1 to hold the code that sorts first — the list must be ascending regardless of insert order');
        Assert.AreEqual('TRYAL-O-BRAVO', Format(DeviceCodes.Get(2)),
            'Expected position 2 to hold the middle code — the list must be ascending regardless of insert order');
        Assert.AreEqual('TRYAL-O-CHARLIE', Format(DeviceCodes.Get(3)),
            'Expected position 3 to hold the code that sorts last — the list must be ascending regardless of insert order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnoresReadingsWithABlankDeviceCode()
    var
        DeviceDirectory: Codeunit "Device Directory";
        Assert: Codeunit Assert;
        DeviceCodes: List of [Code[20]];
        EntryNo: Integer;
    begin
        EntryNo := 3000;
        MockReading(EntryNo, '');
        MockReading(EntryNo, 'TRYAL-REAL');
        MockReading(EntryNo, '');

        DeviceDirectory.GetDeviceCodes(DeviceCodes);

        Assert.AreEqual(1, DeviceCodes.Count(),
            'Expected only the one real device — readings with a blank "Device Code" are malformed and must not contribute a list entry');
        Assert.AreEqual('TRYAL-REAL', Format(DeviceCodes.Get(1)),
            'Expected the only list entry to be the real device''s code, not the blank one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsAnEmptyListWhenThereAreNoReadings()
    var
        DeviceDirectory: Codeunit "Device Directory";
        Assert: Codeunit Assert;
        DeviceCodes: List of [Code[20]];
    begin
        DeviceDirectory.GetDeviceCodes(DeviceCodes);

        Assert.AreEqual(0, DeviceCodes.Count(),
            'Expected an empty list when the Sensor Reading table holds no readings — and no error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DiscardsAnyPriorContentOfThePassedList()
    var
        DeviceDirectory: Codeunit "Device Directory";
        Assert: Codeunit Assert;
        DeviceCodes: List of [Code[20]];
        EntryNo: Integer;
    begin
        EntryNo := 4000;
        DeviceCodes.Add('TRYAL-STALE');
        MockReading(EntryNo, 'TRYAL-FRESH');

        DeviceDirectory.GetDeviceCodes(DeviceCodes);

        Assert.AreEqual(1, DeviceCodes.Count(),
            'Expected the list to be rebuilt from scratch — leftover entries from the caller must not survive the call');
        Assert.AreEqual('TRYAL-FRESH', Format(DeviceCodes.Get(1)),
            'Expected the only list entry to be the device actually present in the table, not the caller''s stale leftover');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheRowBudgetOnALargeLedger()
    var
        DeviceDirectory: Codeunit "Device Directory";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DeviceCodes: List of [Code[20]];
        DeviceCount: Integer;
        ReadingsPerDevice: Integer;
        MaxRows: Integer;
        EntryNo: Integer;
        i: Integer;
        j: Integer;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        MaxRows := 3000;
        DeviceCount := Any.IntegerInRange(18, 20);
        ReadingsPerDevice := 500;
        EntryNo := 100000;
        for i := 1 to DeviceCount do
            for j := 1 to ReadingsPerDevice do
                MockReading(EntryNo, BulkDeviceCode(i));

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        DeviceDirectory.GetDeviceCodes(DeviceCodes);
        // A device that first reports between the two calls: an answer replayed
        // from the codeunit's own memory instead of the table misses it and is
        // stale, so memoizing the first call's list cannot pass the budget check.
        MockReading(EntryNo, LateDeviceCode());
        InvalidateDataCache();
        RowsBefore := SessionInformation.SqlRowsRead();
        DeviceDirectory.GetDeviceCodes(DeviceCodes);
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(DeviceCount + 1, DeviceCodes.Count(),
            'Expected the cheap call to still find every device exactly once — including one that first reported after the previous call; the right answer first, then the right cost');
        Assert.AreEqual(Format(LateDeviceCode()), Format(DeviceCodes.Get(1)),
            StrSubstNo('Expected position 1 to hold %1, the device that first reported between two calls — the list must be rebuilt from the table every time, not replayed from memory', LateDeviceCode()));
        for i := 1 to DeviceCount do
            Assert.AreEqual(Format(BulkDeviceCode(i)), Format(DeviceCodes.Get(i + 1)),
                StrSubstNo('Expected position %1 of the list to hold device %2 — every device exactly once, ascending', i + 1, BulkDeviceCode(i)));
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected the call to read at most %1 rows, but it read %2 for %3 readings across %4 devices — dragging every reading across the wire to collect %4 codes does not scale; sorted by "Device Code", a whole group can be skipped in one jump', MaxRows, RowsUsed, DeviceCount * ReadingsPerDevice, DeviceCount));
    end;

    local procedure MockReading(var EntryNo: Integer; DeviceCode: Code[20])
    var
        SensorReading: Record "Sensor Reading";
    begin
        EntryNo += 1;
        SensorReading.Init();
        SensorReading."Entry No." := EntryNo;
        SensorReading."Device Code" := DeviceCode;
        SensorReading."Value" := 1;
        SensorReading.Insert();
    end;

    local procedure BulkDeviceCode(Index: Integer): Code[20]
    begin
        // 100 + Index keeps the numeric suffix fixed-width, so ascending index = ascending Code sort
        exit(CopyStr(StrSubstNo('TRYAL-B%1', 100 + Index), 1, 20));
    end;

    local procedure LateDeviceCode(): Code[20]
    begin
        // B090 sorts before every bulk code (B101...), pinning it to position 1
        exit('TRYAL-B090');
    end;

    local procedure InvalidateDataCache()
    var
        DecoyEntryNo: Integer;
    begin
        // The warm-up call leaves the table's result sets in the server data cache,
        // and a cached read costs zero SQL — the graded call would measure nothing
        // and a full scan would sail under the budget. A write bumps the table's
        // version and forces real reads again; SelectLatestVersion alone is not
        // enough for rows this transaction has locked. The decoy carries a blank
        // "Device Code", which the contract excludes, so the graded list is untouched.
        DecoyEntryNo := 999999;
        MockReading(DecoyEntryNo, '');
        SelectLatestVersion();
    end;
}
