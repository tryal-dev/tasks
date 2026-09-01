namespace TryAL.Dispatch;

using System.TestLibraries.Utilities;

codeunit 50905 "Qualified Dispatch Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RunsTheConfiguredHandlerOverEveryRowOfTheTargetTable()
    var
        ProbeTicket: Record DispatchProbeTicket;
        Engine: Codeunit "Qualified Dispatch Engine";
    begin
        Initialize();
        SeedTicket('TRYAL-A1', false);
        SeedTicket('TRYAL-A2', false);
        SeedTicket('TRYAL-A3', false);
        CreateJob('T-ALL', ProbeTicket.FullyQualifiedName(), TicketHandlerName());
        Commit();

        Engine.RunJob('T-ALL');

        AssertTicketProcessed('TRYAL-A1');
        AssertTicketProcessed('TRYAL-A2');
        AssertTicketProcessed('TRYAL-A3');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RunsTheHandlerTheJobNamesAgainstASecondTableShape()
    var
        ProbeMeter: Record DispatchProbeMeter;
        Engine: Codeunit "Qualified Dispatch Engine";
        Any: Codeunit Any;
        Reading1: Decimal;
        Reading2: Decimal;
    begin
        Initialize();
        Reading1 := Any.DecimalInRange(1, 500, 2);
        Reading2 := Any.DecimalInRange(1, 500, 2);
        SeedMeter(910001, Reading1);
        SeedMeter(910002, Reading2);
        CreateJob('M-ALL', ProbeMeter.FullyQualifiedName(), MeterHandlerName());
        Commit();

        Engine.RunJob('M-ALL');

        ProbeMeter.Get(910001);
        Assert.AreEqual(Reading1 * 2, ProbeMeter.Reading, 'Expected the meter handler named in the job to double the reading of meter 910001');
        ProbeMeter.Get(910002);
        Assert.AreEqual(Reading2 * 2, ProbeMeter.Reading, 'Expected the meter handler named in the job to double the reading of meter 910002');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure TouchesOnlyTheTableTheJobNames()
    var
        ProbeTicket: Record DispatchProbeTicket;
        ProbeMeter: Record DispatchProbeMeter;
        DispatchRunLog: Record "Dispatch Run Log";
        Engine: Codeunit "Qualified Dispatch Engine";
        Any: Codeunit Any;
        MeterReading: Decimal;
    begin
        Initialize();
        MeterReading := Any.DecimalInRange(1, 500, 2);
        SeedTicket('TRYAL-B1', false);
        SeedMeter(910101, MeterReading);
        CreateJob('T-ISO', ProbeTicket.FullyQualifiedName(), TicketHandlerName());
        CreateJob('M-ISO', ProbeMeter.FullyQualifiedName(), MeterHandlerName());
        Commit();

        Engine.RunJob('T-ISO');

        AssertTicketProcessed('TRYAL-B1');
        ProbeMeter.Get(910101);
        Assert.AreEqual(MeterReading, ProbeMeter.Reading, 'Expected running the ticket job to leave the meter table untouched');
        DispatchRunLog.SetRange("Job Code", 'M-ISO');
        Assert.RecordIsEmpty(DispatchRunLog);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LogsASucceededOutcomeForEachProcessedRow()
    var
        ProbeTicket: Record DispatchProbeTicket;
        DispatchRunLog: Record "Dispatch Run Log";
        Engine: Codeunit "Qualified Dispatch Engine";
    begin
        Initialize();
        SeedTicket('TRYAL-L1', false);
        SeedTicket('TRYAL-L2', false);
        CreateJob('T-LOG', ProbeTicket.FullyQualifiedName(), TicketHandlerName());
        Commit();

        Engine.RunJob('T-LOG');

        DispatchRunLog.SetRange("Job Code", 'T-LOG');
        Assert.RecordCount(DispatchRunLog, 2);
        FindOutcome(DispatchRunLog, 'T-LOG', TicketRecordId('TRYAL-L1'));
        Assert.IsTrue(DispatchRunLog.Succeeded, StrSubstNo('Expected the outcome logged for ticket TRYAL-L1 to be marked Succeeded, got %1', DispatchRunLog.Succeeded));
        Assert.AreEqual('', DispatchRunLog."Error Message", 'Expected an empty Error Message on the succeeded outcome for ticket TRYAL-L1');
        FindOutcome(DispatchRunLog, 'T-LOG', TicketRecordId('TRYAL-L2'));
        Assert.IsTrue(DispatchRunLog.Succeeded, StrSubstNo('Expected the outcome logged for ticket TRYAL-L2 to be marked Succeeded, got %1', DispatchRunLog.Succeeded));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ContinuesPastAFailingRowAndKeepsEarlierWork()
    var
        ProbeTicket: Record DispatchProbeTicket;
        Engine: Codeunit "Qualified Dispatch Engine";
    begin
        Initialize();
        SeedTicket('TRYAL-C1', false);
        SeedTicket('TRYAL-C2', true);
        SeedTicket('TRYAL-C3', false);
        CreateJob('T-CONT', ProbeTicket.FullyQualifiedName(), TicketHandlerName());
        Commit();

        Engine.RunJob('T-CONT');

        AssertTicketProcessed('TRYAL-C1');
        AssertTicketProcessed('TRYAL-C3');
        ProbeTicket.Get('TRYAL-C2');
        Assert.AreEqual('', ProbeTicket.Status, 'Expected the corrupted ticket TRYAL-C2 to be left unprocessed after its handler run failed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LogsTheFailingRowWithTheHandlersErrorText()
    var
        ProbeTicket: Record DispatchProbeTicket;
        DispatchRunLog: Record "Dispatch Run Log";
        Engine: Codeunit "Qualified Dispatch Engine";
    begin
        Initialize();
        SeedTicket('TRYAL-E1', true);
        SeedTicket('TRYAL-E2', false);
        CreateJob('T-ERR', ProbeTicket.FullyQualifiedName(), TicketHandlerName());
        Commit();

        Engine.RunJob('T-ERR');

        DispatchRunLog.SetRange("Job Code", 'T-ERR');
        Assert.RecordCount(DispatchRunLog, 2);
        FindOutcome(DispatchRunLog, 'T-ERR', TicketRecordId('TRYAL-E1'));
        Assert.IsFalse(DispatchRunLog.Succeeded, 'Expected the outcome logged for the corrupted ticket TRYAL-E1 to be marked as failed');
        Assert.IsTrue(DispatchRunLog."Error Message".Contains('TRYAL-E1 is corrupted'),
            StrSubstNo('Expected the Error Message of the failed outcome to carry the handler''s error text, got "%1"', DispatchRunLog."Error Message"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailsWithTheContractErrorForAnUnknownTableName()
    var
        DispatchRunLog: Record "Dispatch Run Log";
        Engine: Codeunit "Qualified Dispatch Engine";
    begin
        Initialize();
        CreateJob('T-BAD', 'TryAL.Dispatch.NoSuchProbeTable', TicketHandlerName());
        Commit();

        asserterror Engine.RunJob('T-BAD');

        Assert.ExpectedError('Dispatch job T-BAD cannot open target table TryAL.Dispatch.NoSuchProbeTable');
        DispatchRunLog.SetRange("Job Code", 'T-BAD');
        Assert.RecordIsEmpty(DispatchRunLog);
    end;

    local procedure Initialize()
    var
        DispatchJob: Record "Dispatch Job";
        DispatchRunLog: Record "Dispatch Run Log";
        ProbeTicket: Record DispatchProbeTicket;
        ProbeMeter: Record DispatchProbeMeter;
    begin
        DispatchJob.DeleteAll();
        DispatchRunLog.DeleteAll();
        ProbeTicket.DeleteAll();
        ProbeMeter.DeleteAll();
    end;

    local procedure CreateJob(JobCode: Code[20]; TargetTableName: Text; HandlerName: Text)
    var
        DispatchJob: Record "Dispatch Job";
    begin
        DispatchJob.Init();
        DispatchJob.Code := JobCode;
        DispatchJob."Target Table Name" := CopyStr(TargetTableName, 1, MaxStrLen(DispatchJob."Target Table Name"));
        DispatchJob."Handler Name" := CopyStr(HandlerName, 1, MaxStrLen(DispatchJob."Handler Name"));
        DispatchJob.Insert();
    end;

    local procedure SeedTicket(TicketNo: Code[20]; IsCorrupted: Boolean)
    var
        ProbeTicket: Record DispatchProbeTicket;
    begin
        ProbeTicket.Init();
        ProbeTicket."Ticket No." := TicketNo;
        ProbeTicket.Corrupted := IsCorrupted;
        ProbeTicket.Insert();
    end;

    local procedure SeedMeter(MeterNo: Integer; MeterReading: Decimal)
    var
        ProbeMeter: Record DispatchProbeMeter;
    begin
        ProbeMeter.Init();
        ProbeMeter."Meter No." := MeterNo;
        ProbeMeter.Reading := MeterReading;
        ProbeMeter.Insert();
    end;

    local procedure TicketHandlerName(): Text
    begin
        exit('TryAL.Dispatch.DispatchTicketHandler');
    end;

    local procedure MeterHandlerName(): Text
    begin
        exit('TryAL.Dispatch.DispatchMeterHandler');
    end;

    local procedure TicketRecordId(TicketNo: Code[20]): RecordId
    var
        ProbeTicket: Record DispatchProbeTicket;
    begin
        ProbeTicket.Get(TicketNo);
        exit(ProbeTicket.RecordId());
    end;

    local procedure AssertTicketProcessed(TicketNo: Code[20])
    var
        ProbeTicket: Record DispatchProbeTicket;
    begin
        ProbeTicket.Get(TicketNo);
        Assert.AreEqual('PROCESSED', ProbeTicket.Status, StrSubstNo('Expected ticket %1 to have been processed by the handler the job names', TicketNo));
    end;

    local procedure FindOutcome(var DispatchRunLog: Record "Dispatch Run Log"; JobCode: Code[20]; TargetRecId: RecordId)
    begin
        DispatchRunLog.SetRange("Job Code", JobCode);
        DispatchRunLog.SetRange("Target Record ID", TargetRecId);
        Assert.IsTrue(DispatchRunLog.FindFirst(), StrSubstNo('Expected a Dispatch Run Log entry for job %1 and record %2, but none was written', JobCode, TargetRecId));
    end;
}
