codeunit 50101 "Dimension Precheck"
{
    procedure CheckSalesDocument(SalesHeader: Record "Sales Header"; var Violation: Record "Dimension Precheck Violation"): Integer
    begin
        // TODO: empty Violation, then report one row per broken default-dimension
        // rule — for the document header (line no. 0) and for every sales line —
        // and return how many rows you wrote.
        Violation.Reset();
        Violation.DeleteAll();
        exit(0);
    end;
}
