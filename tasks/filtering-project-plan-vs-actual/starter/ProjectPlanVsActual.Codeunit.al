codeunit 50100 "Project Plan vs Actual"
{
    procedure PlannedQty(ProjectNo: Code[20]; ProjectTaskNo: Code[20]): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // TODO: this sums EVERY planning line — but not every line type is budget.
        JobPlanningLine.SetRange("Job No.", ProjectNo);
        JobPlanningLine.SetRange("Job Task No.", ProjectTaskNo);
        JobPlanningLine.CalcSums(Quantity);
        exit(JobPlanningLine.Quantity);
    end;

    procedure PostedQty(ProjectNo: Code[20]; ProjectTaskNo: Code[20]): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // TODO: "Qty. Posted" looks like exactly the right field — yet the tests
        // report zero posted on some projects. Where does posting always land?
        JobPlanningLine.SetRange("Job No.", ProjectNo);
        JobPlanningLine.SetRange("Job Task No.", ProjectTaskNo);
        JobPlanningLine.CalcSums("Qty. Posted");
        exit(JobPlanningLine."Qty. Posted");
    end;

    procedure RemainingQty(ProjectNo: Code[20]; ProjectTaskNo: Code[20]): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // TODO: same trap — this field only moves on some projects.
        JobPlanningLine.SetRange("Job No.", ProjectNo);
        JobPlanningLine.SetRange("Job Task No.", ProjectTaskNo);
        JobPlanningLine.CalcSums("Remaining Qty.");
        exit(JobPlanningLine."Remaining Qty.");
    end;
}
