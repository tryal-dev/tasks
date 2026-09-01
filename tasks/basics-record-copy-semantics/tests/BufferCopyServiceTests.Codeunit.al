codeunit 50900 "Buffer Copy Service Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SnapshotHoldsEveryRowTheSourceHadWhenTaken()
    var
        SourceBuffer: Record "Name/Value Buffer" temporary;
        SnapshotBuffer: Record "Name/Value Buffer" temporary;
        Service: Codeunit "Buffer Copy Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstValue: Text;
        SecondValue: Text;
    begin
        // [SCENARIO] Right after TakeSnapshot, the snapshot carries every source row
        FirstValue := Any.AlphanumericText(20);
        SecondValue := Any.AlphanumericText(20);
        AddRow(SourceBuffer, 1, 'First', FirstValue);
        AddRow(SourceBuffer, 2, 'Second', SecondValue);

        Service.TakeSnapshot(SourceBuffer, SnapshotBuffer);

        SnapshotBuffer.Reset();
        Assert.AreEqual(2, SnapshotBuffer.Count(),
            'Expected the snapshot to hold every row the source had when it was taken — a plain Copy never carries a temporary data set');
        Assert.IsTrue(SnapshotBuffer.Get(1), 'Expected the snapshot to contain the source row with ID 1');
        Assert.AreEqual('First', SnapshotBuffer.Name, 'Expected snapshot row 1 to carry the source row''s Name');
        Assert.AreEqual(FirstValue, SnapshotBuffer.Value, 'Expected snapshot row 1 to carry the source row''s Value');
        Assert.IsTrue(SnapshotBuffer.Get(2), 'Expected the snapshot to contain the source row with ID 2');
        Assert.AreEqual(SecondValue, SnapshotBuffer.Value, 'Expected snapshot row 2 to carry the source row''s Value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SnapshotIgnoresARowInsertedIntoTheSourceAfterwards()
    var
        SourceBuffer: Record "Name/Value Buffer" temporary;
        SnapshotBuffer: Record "Name/Value Buffer" temporary;
        Service: Codeunit "Buffer Copy Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A row inserted into the source after the snapshot stays invisible in it
        AddRow(SourceBuffer, 1, 'First', Any.AlphanumericText(20));
        AddRow(SourceBuffer, 2, 'Second', Any.AlphanumericText(20));
        Service.TakeSnapshot(SourceBuffer, SnapshotBuffer);

        AddRow(SourceBuffer, 3, 'Late', Any.AlphanumericText(20));

        SnapshotBuffer.Reset();
        Assert.AreEqual(2, SnapshotBuffer.Count(),
            'Expected the snapshot to keep the row count it had when it was taken — a ShareTable copy is a shared view, not a snapshot');
        Assert.IsFalse(SnapshotBuffer.Get(3),
            'Expected the row inserted into the source after the snapshot to be invisible in the snapshot');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SnapshotKeepsTheValueASourceRowHadWhenTaken()
    var
        SourceBuffer: Record "Name/Value Buffer" temporary;
        SnapshotBuffer: Record "Name/Value Buffer" temporary;
        Service: Codeunit "Buffer Copy Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OriginalValue: Text;
        ChangedValue: Text;
    begin
        // [SCENARIO] Modifying a source row after the snapshot leaves the snapshot's value frozen
        OriginalValue := Any.AlphanumericText(20);
        ChangedValue := Any.AlphanumericText(20);
        AddRow(SourceBuffer, 10, 'Rate', OriginalValue);
        Service.TakeSnapshot(SourceBuffer, SnapshotBuffer);

        SourceBuffer.Get(10);
        SourceBuffer.Value := CopyStr(ChangedValue, 1, MaxStrLen(SourceBuffer.Value));
        SourceBuffer.Modify();

        Assert.IsTrue(SnapshotBuffer.Get(10), 'Expected the snapshot to contain the source row with ID 10');
        Assert.AreEqual(OriginalValue, SnapshotBuffer.Value,
            'Expected the snapshot to keep the value the row had when the snapshot was taken, not the value the source was changed to afterwards');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SnapshotKeepsARowLaterDeletedFromTheSource()
    var
        SourceBuffer: Record "Name/Value Buffer" temporary;
        SnapshotBuffer: Record "Name/Value Buffer" temporary;
        Service: Codeunit "Buffer Copy Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] Deleting a source row after the snapshot does not remove it from the snapshot
        AddRow(SourceBuffer, 20, 'Keep', Any.AlphanumericText(20));
        AddRow(SourceBuffer, 21, 'Doomed', Any.AlphanumericText(20));
        Service.TakeSnapshot(SourceBuffer, SnapshotBuffer);

        SourceBuffer.Get(21);
        SourceBuffer.Delete();

        SnapshotBuffer.Reset();
        Assert.AreEqual(2, SnapshotBuffer.Count(),
            'Expected the snapshot to keep both rows it was taken with, even after one was deleted from the source');
        Assert.IsTrue(SnapshotBuffer.Get(21),
            'Expected the row deleted from the source after the snapshot to still exist in the snapshot');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TakingASnapshotLeavesTheSourceRowsInPlace()
    var
        SourceBuffer: Record "Name/Value Buffer" temporary;
        SnapshotBuffer: Record "Name/Value Buffer" temporary;
        Service: Codeunit "Buffer Copy Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        MiddleValue: Text;
    begin
        // [SCENARIO] TakeSnapshot only reads the source — it must not move or delete its rows
        MiddleValue := Any.AlphanumericText(20);
        AddRow(SourceBuffer, 1, 'First', Any.AlphanumericText(20));
        AddRow(SourceBuffer, 2, 'Middle', MiddleValue);
        AddRow(SourceBuffer, 3, 'Last', Any.AlphanumericText(20));

        Service.TakeSnapshot(SourceBuffer, SnapshotBuffer);

        SourceBuffer.Reset();
        Assert.AreEqual(3, SourceBuffer.Count(),
            'Expected every source row to still be there after taking a snapshot — a snapshot reads the source, it must not move or delete its rows');
        Assert.IsTrue(SourceBuffer.Get(2), 'Expected the source row with ID 2 to survive taking a snapshot');
        Assert.AreEqual(MiddleValue, SourceBuffer.Value, 'Expected the source row values to be untouched by taking a snapshot');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SharedViewSeesARowInsertedIntoTheSourceAfterAttaching()
    var
        SourceBuffer: Record "Name/Value Buffer" temporary;
        SharedViewBuffer: Record "Name/Value Buffer" temporary;
        Service: Codeunit "Buffer Copy Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LateValue: Text;
    begin
        // [SCENARIO] A row inserted into the source after attaching shows through the shared view
        AddRow(SourceBuffer, 1, 'Seed', Any.AlphanumericText(20));
        Service.AttachSharedView(SourceBuffer, SharedViewBuffer);

        LateValue := Any.AlphanumericText(20);
        AddRow(SourceBuffer, 2, 'Late', LateValue);

        SharedViewBuffer.Reset();
        Assert.AreEqual(2, SharedViewBuffer.Count(),
            'Expected the shared view to see the row inserted into the source after attaching — the view and the source must share one data set');
        Assert.IsTrue(SharedViewBuffer.Get(2), 'Expected the shared view to reach the row inserted into the source after attaching');
        Assert.AreEqual(LateValue, SharedViewBuffer.Value, 'Expected the shared view to read the inserted row''s Value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SharedViewSeesAModificationMadeThroughTheSource()
    var
        SourceBuffer: Record "Name/Value Buffer" temporary;
        SharedViewBuffer: Record "Name/Value Buffer" temporary;
        Service: Codeunit "Buffer Copy Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NewValue: Text;
    begin
        // [SCENARIO] A value changed through the source after attaching shows through the shared view
        AddRow(SourceBuffer, 30, 'Status', Any.AlphanumericText(20));
        Service.AttachSharedView(SourceBuffer, SharedViewBuffer);

        NewValue := Any.AlphanumericText(20);
        SourceBuffer.Get(30);
        SourceBuffer.Value := CopyStr(NewValue, 1, MaxStrLen(SourceBuffer.Value));
        SourceBuffer.Modify();

        Assert.IsTrue(SharedViewBuffer.Get(30), 'Expected the shared view to reach the row the source holds');
        Assert.AreEqual(NewValue, SharedViewBuffer.Value,
            'Expected the shared view to read the value the source row was changed to after attaching — an independent copy would still show the old value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AWriteThroughTheSharedViewReachesTheSource()
    var
        SourceBuffer: Record "Name/Value Buffer" temporary;
        SharedViewBuffer: Record "Name/Value Buffer" temporary;
        Service: Codeunit "Buffer Copy Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NewValue: Text;
    begin
        // [SCENARIO] A modification written through the shared view is visible in the source
        AddRow(SourceBuffer, 40, 'Target', Any.AlphanumericText(20));
        Service.AttachSharedView(SourceBuffer, SharedViewBuffer);

        NewValue := Any.AlphanumericText(20);
        Assert.IsTrue(SharedViewBuffer.Get(40), 'Expected the shared view to reach the row the source holds');
        SharedViewBuffer.Value := CopyStr(NewValue, 1, MaxStrLen(SharedViewBuffer.Value));
        SharedViewBuffer.Modify();

        SourceBuffer.Get(40);
        Assert.AreEqual(NewValue, SourceBuffer.Value,
            'Expected a change written through the shared view to be visible in the source — same data set, two variables');
    end;

    local procedure AddRow(var Buffer: Record "Name/Value Buffer" temporary; RowID: Integer; RowName: Text; RowValue: Text)
    begin
        Buffer.Init();
        Buffer.ID := RowID;
        Buffer.Name := CopyStr(RowName, 1, MaxStrLen(Buffer.Name));
        Buffer.Value := CopyStr(RowValue, 1, MaxStrLen(Buffer.Value));
        Buffer.Insert();
    end;
}
