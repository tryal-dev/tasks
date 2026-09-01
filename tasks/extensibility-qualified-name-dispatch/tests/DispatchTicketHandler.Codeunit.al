namespace TryAL.Dispatch;

codeunit 50902 DispatchTicketHandler
{
    TableNo = "Dispatch Job";

    var
        CorruptedTicketErr: Label 'Probe ticket %1 is corrupted.', Comment = '%1 - ticket number';

    trigger OnRun()
    var
        ProbeTicket: Record DispatchProbeTicket;
        TargetRecRef: RecordRef;
    begin
        TargetRecRef.Get(Rec."Current Record ID");
        TargetRecRef.SetTable(ProbeTicket);
        if ProbeTicket.Corrupted then
            Error(CorruptedTicketErr, ProbeTicket."Ticket No.");
        ProbeTicket.Status := 'PROCESSED';
        ProbeTicket.Modify();
    end;
}
