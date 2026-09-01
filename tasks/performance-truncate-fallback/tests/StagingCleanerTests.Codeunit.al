codeunit 50900 "Staging Cleaner Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnfilteredClearRemovesEveryRow()
    var
        StagingEntry: Record "Staging Entry";
        StagingCleaner: Codeunit "Staging Cleaner";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SeedCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] An unfiltered clear leaves the staging table with zero rows
        // The test runner executes every test inside a try function, one of the states in
        // which the platform's bulk truncation is unavailable — so this call, like every
        // graded call, only gets through a cleaner that falls back when truncation is refused.
        // [GIVEN] a staging table holding a handful of rows
        StagingEntry.DeleteAll();
        SeedCount := Any.IntegerInRange(5, 9);
        for i := 1 to SeedCount do
            SeedRow('TRYAL-A', StrSubstNo('row %1 of %2', i, SeedCount));

        // [WHEN] clearing without filters
        StagingCleaner.ClearStaging(StagingEntry, true);

        // [THEN] not a single row is left
        StagingEntry.Reset();
        Assert.AreEqual(0, StagingEntry.Count(),
            'Expected ClearStaging on an unfiltered record to leave the Staging Entry table completely empty — and to get there without an error wherever the fast wipe is refused');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PreservingClearContinuesNumberingAboveTheOldMaximum()
    var
        StagingEntry: Record "Staging Entry";
        StagingCleaner: Codeunit "Staging Cleaner";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SeedCount: Integer;
        MaxEntryNo: Integer;
        ProbeEntryNo: Integer;
        i: Integer;
    begin
        // [SCENARIO] After a ResetNumbering=false clear, the numbering keeps counting upward
        // [GIVEN] a staging table holding rows numbered up to some maximum
        StagingEntry.DeleteAll();
        SeedCount := Any.IntegerInRange(3, 7);
        for i := 1 to SeedCount do
            MaxEntryNo := SeedRow('TRYAL-C', 'consumes one entry number');

        // [WHEN] clearing with ResetNumbering = false
        StagingCleaner.ClearStaging(StagingEntry, false);

        // [THEN] the table is empty and a fresh insert continues above the old maximum
        StagingEntry.Reset();
        Assert.AreEqual(0, StagingEntry.Count(),
            'Expected the ResetNumbering=false clear to empty the table before the numbering is judged');
        ProbeEntryNo := SeedRow('TRYAL-C', 'probe row after the preserving clear');
        Assert.IsTrue(ProbeEntryNo > MaxEntryNo,
            StrSubstNo('Expected numbering to continue above the old maximum %1 after a ResetNumbering=false clear, but the fresh insert got "Entry No." %2 — the counter must be preserved, not rewound', MaxEntryNo, ProbeEntryNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FilteredClearRemovesOnlyTheFilteredRows()
    var
        StagingEntry: Record "Staging Entry";
        StagingCleaner: Codeunit "Staging Cleaner";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        KeepEntryNos: List of [Integer];
        DropCount: Integer;
        KeepCount: Integer;
        EntryNo: Integer;
        i: Integer;
    begin
        // [SCENARIO] A clear on a filtered record removes exactly the rows inside the filter
        // [GIVEN] rows of two source codes, the filter selecting only one of them
        StagingEntry.DeleteAll();
        KeepCount := Any.IntegerInRange(2, 4);
        DropCount := Any.IntegerInRange(3, 6);
        for i := 1 to KeepCount do
            KeepEntryNos.Add(SeedRow('TRYAL-KEEP', StrSubstNo('survivor %1', i)));
        for i := 1 to DropCount do
            SeedRow('TRYAL-DROP', 'row inside the filter');
        StagingEntry.SetRange("Source Code", 'TRYAL-DROP');

        // [WHEN] clearing the filtered record
        StagingCleaner.ClearStaging(StagingEntry, false);

        // [THEN] the filtered rows are gone and every row outside the filter survives untouched
        StagingEntry.Reset();
        StagingEntry.SetRange("Source Code", 'TRYAL-DROP');
        Assert.AreEqual(0, StagingEntry.Count(),
            'Expected every row inside the "Source Code" filter to be removed by the filtered clear');
        StagingEntry.Reset();
        Assert.AreEqual(KeepCount, StagingEntry.Count(),
            'Expected exactly the rows outside the filter to survive a filtered clear — the clear must respect the filters on the record it is handed');
        foreach EntryNo in KeepEntryNos do begin
            Assert.IsTrue(StagingEntry.Get(EntryNo),
                StrSubstNo('Expected the row outside the filter with "Entry No." %1 to survive the filtered clear', EntryNo));
            Assert.AreEqual('TRYAL-KEEP', StagingEntry."Source Code",
                StrSubstNo('Expected the surviving row %1 to keep its "Source Code" untouched', EntryNo));
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TemporaryInstanceIsEmptiedWithoutError()
    var
        StagingEntry: Record "Staging Entry";
        TempStagingEntry: Record "Staging Entry" temporary;
        StagingCleaner: Codeunit "Staging Cleaner";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SurvivorEntryNo: Integer;
        TempCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] A temporary instance is emptied by the same call, without a runtime error
        // [GIVEN] one real row and a temporary instance holding its own rows
        StagingEntry.DeleteAll();
        SurvivorEntryNo := SeedRow('TRYAL-REAL', 'real row the temp clear must not touch');
        TempCount := Any.IntegerInRange(3, 6);
        for i := 1 to TempCount do begin
            // AutoIncrement is inactive on temporary instances - assign the keys by hand
            TempStagingEntry.Init();
            TempStagingEntry."Entry No." := i;
            TempStagingEntry."Source Code" := 'TRYAL-TEMP';
            TempStagingEntry.Insert();
        end;

        // [WHEN] clearing the temporary instance
        StagingCleaner.ClearStaging(TempStagingEntry, true);

        // [THEN] the temp rows are gone — bulk truncation is unsupported there, so a cleaner
        // that does not read the capability answer dies with a runtime error instead
        TempStagingEntry.Reset();
        Assert.AreEqual(0, TempStagingEntry.Count(),
            'Expected ClearStaging to empty a temporary instance without raising an error — an instance the fast wipe cannot handle must still end up empty');
        Assert.IsTrue(StagingEntry.Get(SurvivorEntryNo),
            'Expected the real Staging Entry row to survive a clear of a temporary instance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlockedTableIsStillEmptiedWithoutError()
    var
        StagingEntry: Record "Staging Entry";
        StagingCleaner: Codeunit "Staging Cleaner";
        DeleteEventBlocker: Codeunit "Delete Event Blocker";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SeedCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] With an active delete-event subscriber on the table, the clear still empties it
        // [GIVEN] staged rows and a bound subscriber to the table's delete event — one of the
        // states in which the platform refuses bulk truncation, so only a cleaner that probes
        // the capability (instead of assuming or guessing it) gets through without an error
        StagingEntry.DeleteAll();
        SeedCount := Any.IntegerInRange(4, 8);
        for i := 1 to SeedCount do
            SeedRow('TRYAL-BLK', 'row behind a delete-event subscriber');
        BindSubscription(DeleteEventBlocker);

        // [WHEN] clearing while the subscriber is active
        StagingCleaner.ClearStaging(StagingEntry, false);

        // [THEN] no error was raised and the table is empty
        UnbindSubscription(DeleteEventBlocker);
        StagingEntry.Reset();
        Assert.AreEqual(0, StagingEntry.Count(),
            'Expected ClearStaging to empty the table without an error even while a delete-event subscriber blocks the fast wipe');
    end;

    local procedure SeedRow(SourceCode: Code[20]; Description: Text): Integer
    var
        StagingEntry: Record "Staging Entry";
    begin
        StagingEntry.Init();
        StagingEntry."Entry No." := 0;
        StagingEntry."Source Code" := SourceCode;
        StagingEntry.Description := CopyStr(Description, 1, MaxStrLen(StagingEntry.Description));
        StagingEntry.Insert();
        exit(StagingEntry."Entry No.");
    end;
}
