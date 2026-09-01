codeunit 50100 "Order Release Manager"
{
    procedure ReleaseOrder(var SalesHeader: Record "Sales Header"): Boolean
    begin
        // TODO: an order without an external document number deserves a question
        // first — and an order that has one must release without any dialog.
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Modify();
        exit(true);
    end;
}
