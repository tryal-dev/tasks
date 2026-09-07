codeunit 50100 "Order Counter"
{
    var
        SalesHeader: Record "Sales Header";

    procedure CountOpenOrders(CustomerNo: Code[20]): Integer
    begin
        // TODO: all three procedures share this one SalesHeader variable, and
        // whatever the previous call left on it is still there when the next
        // call starts — the counts drift with the order of the calls.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange(Status, SalesHeader.Status::Open);
        exit(SalesHeader.Count());
    end;

    procedure CountOrdersForCustomers(CustomerNos: List of [Code[20]]): Integer
    var
        CustomerNo: Code[20];
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        foreach CustomerNo in CustomerNos do begin
            SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
            if SalesHeader.FindSet() then
                repeat
                    SalesHeader.Mark(true);
                until SalesHeader.Next() = 0;
        end;
        SalesHeader.SetRange("Sell-to Customer No.");
        SalesHeader.MarkedOnly(true);
        exit(SalesHeader.Count());
    end;

    procedure CountAllOrders(): Integer
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        exit(SalesHeader.Count());
    end;
}
