codeunit 50900 "DateTime Tolerance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IdenticalTimestampsAreTheSameMoment()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        Moment: DateTime;
    begin
        // [SCENARIO] A timestamp compared with itself is the same moment
        Moment := RandomMoment();

        Assert.IsTrue(Detector.IsSameMoment(Moment, Moment),
            StrSubstNo('Expected IsSameMoment to return true for two identical timestamps (%1)', Moment));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ThreeMillisecondDriftIsTheSameMoment()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        Moment: DateTime;
    begin
        // [SCENARIO] 3 ms apart — typical SQL datetime rounding — compares equal
        Moment := RandomMoment();

        Assert.IsTrue(Detector.IsSameMoment(Moment, Moment + 3),
            'Expected timestamps 3 ms apart to be the same moment — SQL datetime rounding moves stored values to the nearest .000/.003/.007');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NineMillisecondDriftIsStillTheSameMoment()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        Moment: DateTime;
    begin
        // [SCENARIO] 9 ms apart, later value passed first, still compares equal
        Moment := RandomMoment();

        Assert.IsTrue(Detector.IsSameMoment(Moment + 9, Moment),
            'Expected timestamps 9 ms apart to be the same moment in either argument order — anything under 10 ms is SQL rounding noise');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TenMillisecondGapIsADifferentMoment()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        Moment: DateTime;
    begin
        // [SCENARIO] Exactly 10 ms apart is beyond the tolerance and compares different
        Moment := RandomMoment();

        Assert.IsFalse(Detector.IsSameMoment(Moment, Moment + 10),
            'Expected timestamps exactly 10 ms apart to be different moments — the tolerance is strictly less than 10 ms');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AClearEditIsADifferentMoment()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Moment: DateTime;
        GapMs: Integer;
    begin
        // [SCENARIO] A gap of 20+ ms is a real change, not rounding noise
        Moment := RandomMoment();
        GapMs := Any.IntegerInRange(20, 500);

        Assert.IsFalse(Detector.IsSameMoment(Moment, Moment + GapMs),
            StrSubstNo('Expected timestamps %1 ms apart to be different moments — gaps of 10 ms or more are real changes', GapMs));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ARealGapIsADifferentMomentInReversedOrder()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Moment: DateTime;
        GapMs: Integer;
    begin
        // [SCENARIO] A gap of 10+ ms is a different moment with the later value passed first
        Moment := RandomMoment();
        GapMs := Any.IntegerInRange(10, 500);

        Assert.IsFalse(Detector.IsSameMoment(Moment + GapMs, Moment),
            StrSubstNo('Expected timestamps %1 ms apart to be different moments with the later value as the first argument — the 10 ms tolerance applies in either direction', GapMs));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UndefinedTimestampNeverMatchesARealOne()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        Moment: DateTime;
    begin
        // [SCENARIO] 0DT against a real timestamp is different, whichever side it is on
        Moment := RandomMoment();

        Assert.IsFalse(Detector.IsSameMoment(0DT, Moment),
            'Expected an undefined timestamp (0DT) as the first argument to differ from a real timestamp');
        Assert.IsFalse(Detector.IsSameMoment(Moment, 0DT),
            'Expected an undefined timestamp (0DT) as the second argument to differ from a real timestamp');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoUndefinedTimestampsAreTheSameMoment()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Two undefined timestamps compare equal
        Assert.IsTrue(Detector.IsSameMoment(0DT, 0DT),
            'Expected two undefined timestamps (0DT) to be the same moment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SqlDriftAloneDoesNotTriggerAResync()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        StoredStamp: DateTime;
    begin
        // [SCENARIO] A 7 ms round-trip drift must not re-emit the record
        StoredStamp := RandomMoment();

        Assert.IsFalse(Detector.ShouldResync(StoredStamp + 7, StoredStamp),
            'Expected no resync for a 7 ms drift — that is SQL rounding noise, not a real change');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ATenMillisecondChangeTriggersAResync()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        StoredStamp: DateTime;
    begin
        // [SCENARIO] A modification 10 ms after the synced stamp is a real change
        StoredStamp := RandomMoment();

        Assert.IsTrue(Detector.ShouldResync(StoredStamp + 10, StoredStamp),
            'Expected a resync for a 10 ms difference — 10 ms or more is a real change, not rounding noise');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AStampThatMovedBackwardsTriggersAResync()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        StoredStamp: DateTime;
    begin
        // [SCENARIO] A current stamp 20 ms behind the synced one is a real change too
        StoredStamp := RandomMoment();

        Assert.IsTrue(Detector.ShouldResync(StoredStamp, StoredStamp + 20),
            'Expected a resync when the current stamp is 20 ms earlier than the synced one — a 10 ms or larger gap is a real change in either direction');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnUndefinedCurrentStampTriggersAResync()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0DT as the current stamp against a real stored stamp is not the same moment
        Assert.IsTrue(Detector.ShouldResync(0DT, RandomMoment()),
            'Expected a resync when the current stamp is undefined (0DT) but the stored stamp is real — they are not the same moment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ANeverSyncedRecordIsAlwaysEmitted()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A stored stamp of 0DT means never synced — always emit
        Assert.IsTrue(Detector.ShouldResync(RandomMoment(), 0DT),
            'Expected a resync when the stored stamp is 0DT — a record that has never been synced is always emitted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SyncPassReEmitsOnlyRealChanges()
    var
        Detector: Codeunit "DateTime Change Detector";
        Assert: Codeunit Assert;
        StoredStamp: DateTime;
        DriftsMs: List of [Integer];
        DriftMs: Integer;
        EmittedCount: Integer;
    begin
        // [SCENARIO] A sync pass over drifted and changed records emits only the real changes
        // [GIVEN] five records whose current stamps drifted 0, 3, 9, 20 and 250 ms plus one never-synced record
        StoredStamp := RandomMoment();
        DriftsMs.Add(0);
        DriftsMs.Add(3);
        DriftsMs.Add(9);
        DriftsMs.Add(20);
        DriftsMs.Add(250);

        // [WHEN] running the sync decision over the whole batch
        foreach DriftMs in DriftsMs do
            if Detector.ShouldResync(StoredStamp + DriftMs, StoredStamp) then
                EmittedCount += 1;
        if Detector.ShouldResync(RandomMoment(), 0DT) then
            EmittedCount += 1;

        // [THEN] only the 20 ms and 250 ms changes and the never-synced record are emitted
        Assert.AreEqual(3, EmittedCount,
            'Expected the sync pass to emit exactly the two really changed records (20 and 250 ms) and the never-synced one — drifts of 0, 3 and 9 ms must not be re-emitted');
    end;

    local procedure RandomMoment(): DateTime
    var
        Any: Codeunit Any;
    begin
        exit(CreateDateTime(Any.DateInRange(20240101D, 1, 700), 093000T) + Any.IntegerInRange(0, 999));
    end;
}
