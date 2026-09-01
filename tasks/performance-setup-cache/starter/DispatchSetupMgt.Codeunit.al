codeunit 50101 "Dispatch Setup Mgt."
{
    procedure GetSetup(var DispatchSetup: Record "Dispatch Setup")
    begin
        // TODO: right answers, wrong cost — this reads the table on every call,
        // and the grading budget allows 0 SQL statements for a whole burst of calls.
        // It also shows a direct table change immediately, where the contract
        // demands it stays hidden until Invalidate is called.
        if not DispatchSetup.Get() then begin
            DispatchSetup.Init();
            DispatchSetup.Insert();
        end;
    end;

    procedure Invalidate()
    begin
        // TODO: drop the cached copy so the next GetSetup reads the table again
    end;
}
