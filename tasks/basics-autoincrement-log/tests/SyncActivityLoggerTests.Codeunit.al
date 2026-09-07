codeunit 50900 "Sync Activity Logger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectInsertWithZeroEntryNoGetsANumberFromTheDatabase()
    var
        ActivityLog: Record "Sync Activity Log";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The table numbers its own rows: a row inserted with "Entry No." = 0 comes back numbered
        // [WHEN] inserting a row directly with "Entry No." left at 0
        ActivityLog.Init();
        ActivityLog."Entry No." := 0;
        ActivityLog.Message := 'TRYAL-T1 direct insert';
        ActivityLog.Insert();

        // [THEN] the record variable holds the number the database assigned
        Assert.IsTrue(ActivityLog."Entry No." > 0,
            StrSubstNo('Expected the database to assign a positive "Entry No." to a row inserted with 0, got %1 - the field needs AutoIncrement = true', ActivityLog."Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogReturnsTheNumberUnderWhichTheMessageIsStored()
    var
        ActivityLog: Record "Sync Activity Log";
        StoredActivityLog: Record "Sync Activity Log";
        ActivityLogger: Codeunit "Sync Activity Logger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        MessageText: Text[250];
        EntryNo: Integer;
    begin
        // [SCENARIO] Log returns the assigned number, and the message is stored under it
        // [GIVEN] a generated message
        MessageText := CopyStr('TRYAL-T2 ' + Any.AlphabeticText(20), 1, MaxStrLen(MessageText));

        // [WHEN] logging it
        EntryNo := ActivityLogger.Log(ActivityLog, MessageText);

        // [THEN] the returned number is positive and finds a row carrying the message
        Assert.IsTrue(EntryNo > 0,
            StrSubstNo('Expected Log to return the positive "Entry No." the database assigned, got %1', EntryNo));
        Assert.IsTrue(StoredActivityLog.Get(EntryNo),
            StrSubstNo('Expected an Sync Activity Log row with "Entry No." %1 - the number Log returned - to exist in the table', EntryNo));
        Assert.AreEqual(MessageText, StoredActivityLog.Message,
            'Expected the row under the returned "Entry No." to carry the logged message');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogLeavesTheRecordVariableOnTheNewEntry()
    var
        ActivityLog: Record "Sync Activity Log";
        ActivityLogger: Codeunit "Sync Activity Logger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        MessageText: Text[250];
        EntryNo: Integer;
    begin
        // [SCENARIO] The assigned number is read back from the record variable the caller passed in
        // [GIVEN] a generated message
        MessageText := CopyStr('TRYAL-T3 ' + Any.AlphabeticText(20), 1, MaxStrLen(MessageText));

        // [WHEN] logging it
        EntryNo := ActivityLogger.Log(ActivityLog, MessageText);

        // [THEN] the variable sits on the new row: same number, same message
        Assert.AreEqual(EntryNo, ActivityLog."Entry No.",
            'Expected the record variable passed to Log to hold the returned "Entry No." when the call returns - the number is read back from the variable after Insert');
        Assert.AreEqual(MessageText, ActivityLog.Message,
            'Expected the record variable passed to Log to carry the logged message when the call returns');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ThreeLogsWithOneVariableReturnStrictlyIncreasingNumbers()
    var
        ActivityLog: Record "Sync Activity Log";
        ActivityLogger: Codeunit "Sync Activity Logger";
        Assert: Codeunit Assert;
        FirstNo: Integer;
        SecondNo: Integer;
        ThirdNo: Integer;
    begin
        // [SCENARIO] Repeated calls with the same record variable get ever higher numbers
        // [WHEN] logging three messages through one record variable
        FirstNo := ActivityLogger.Log(ActivityLog, 'TRYAL-T4 first');
        SecondNo := ActivityLogger.Log(ActivityLog, 'TRYAL-T4 second');
        ThirdNo := ActivityLogger.Log(ActivityLog, 'TRYAL-T4 third');

        // [THEN] the numbers strictly increase and three rows exist
        Assert.IsTrue(SecondNo > FirstNo,
            StrSubstNo('Expected the second Log call to return a higher "Entry No." than the first, got %1 after %2', SecondNo, FirstNo));
        Assert.IsTrue(ThirdNo > SecondNo,
            StrSubstNo('Expected the third Log call to return a higher "Entry No." than the second, got %1 after %2', ThirdNo, SecondNo));
        ActivityLog.Reset();
        ActivityLog.SetFilter(Message, 'TRYAL-T4*');
        Assert.AreEqual(3, ActivityLog.Count(),
            'Expected exactly three Sync Activity Log rows after three Log calls - each call inserts one row');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogNeverHandsOutADeletedNumberAgain()
    var
        DeletedActivityLog: Record "Sync Activity Log";
        ActivityLog: Record "Sync Activity Log";
        ActivityLogger: Codeunit "Sync Activity Logger";
        Assert: Codeunit Assert;
        DeletedNo: Integer;
        NewNo: Integer;
    begin
        // [SCENARIO] A number the database handed out once is gone for good, even after its row is deleted
        // [GIVEN] a row the database numbered, deleted again, leaving the table empty
        DeletedActivityLog.Init();
        DeletedActivityLog."Entry No." := 0;
        DeletedActivityLog.Message := 'TRYAL-T5 deleted';
        DeletedActivityLog.Insert();
        DeletedNo := DeletedActivityLog."Entry No.";
        DeletedActivityLog.Delete();

        // [WHEN] logging after the delete, with a fresh record variable
        NewNo := ActivityLogger.Log(ActivityLog, 'TRYAL-T5 after delete');

        // [THEN] the new entry is numbered above the deleted one
        Assert.IsTrue(NewNo > DeletedNo,
            StrSubstNo('Expected the entry logged after deleting entry %1 to get a higher number, got %2 - the database never hands out an AutoIncrement value twice, but a number computed in AL (highest existing plus one) starts over once the highest row is gone', DeletedNo, NewNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogStoresAFullLengthMessage()
    var
        ActivityLog: Record "Sync Activity Log";
        StoredActivityLog: Record "Sync Activity Log";
        ActivityLogger: Codeunit "Sync Activity Logger";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        MessageText: Text[250];
        EntryNo: Integer;
    begin
        // [SCENARIO] A message of the full 250 characters is stored without loss
        // [GIVEN] a generated 250-character message
        MessageText := CopyStr(Any.AlphanumericText(MaxStrLen(MessageText)), 1, MaxStrLen(MessageText));

        // [WHEN] logging it
        EntryNo := ActivityLogger.Log(ActivityLog, MessageText);

        // [THEN] the stored row carries all 250 characters
        Assert.IsTrue(StoredActivityLog.Get(EntryNo),
            StrSubstNo('Expected an Sync Activity Log row with "Entry No." %1 - the number Log returned - to exist in the table', EntryNo));
        Assert.AreEqual(MessageText, StoredActivityLog.Message,
            'Expected a 250-character message to be stored in full');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogRefusesATemporaryRecord()
    var
        TempActivityLog: Record "Sync Activity Log" temporary;
        ActivityLogger: Codeunit "Sync Activity Logger";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A temporary record variable is refused before anything is written to it
        // [WHEN] logging into a temporary record variable
        asserterror ActivityLogger.Log(TempActivityLog, 'TRYAL-T7 temporary');

        // [THEN] the promised error is raised and the buffer is still empty
        Assert.ExpectedError('must not be temporary');
        Assert.IsTrue(TempActivityLog.IsEmpty(),
            StrSubstNo('Expected Log to refuse the temporary record before writing anything to it, but the buffer holds %1 row(s)', TempActivityLog.Count()));
    end;
}
