namespace TryAL.Dispatch;

codeunit 50903 DispatchMeterHandler
{
    TableNo = "Dispatch Job";

    trigger OnRun()
    var
        ProbeMeter: Record DispatchProbeMeter;
        TargetRecRef: RecordRef;
    begin
        TargetRecRef.Get(Rec."Current Record ID");
        TargetRecRef.SetTable(ProbeMeter);
        ProbeMeter.Reading := ProbeMeter.Reading * 2;
        ProbeMeter.Modify();
    end;
}
