codeunit 50100 "Scanner Intake"
{
    procedure ResolveScannedCode(var SalesLine: Record "Sales Line"; ScannedCode: Code[50]; IntakeDate: Date)
    begin
        // TODO: find the reference active on IntakeDate by tier, apply it to the line
        // and save it — or raise an error naming the code when nothing qualifies.
    end;
}
