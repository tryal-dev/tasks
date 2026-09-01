codeunit 50100 "Return Line Registrar"
{
    procedure RegisterReturnLine(var SalesLine: Record "Sales Line"; ReturnReasonCode: Code[10])
    begin
        // TODO: the code lands on the line, but the reason's policies never run —
        // the line keeps its old location and its full cost.
        SalesLine."Return Reason Code" := ReturnReasonCode;
        SalesLine.Modify(true);
    end;
}
