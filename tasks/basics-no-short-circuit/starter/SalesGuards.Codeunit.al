codeunit 50100 "Sales Guards"
{
    procedure IsOverLimit(Total: Decimal; Qty: Decimal; Limit: Decimal): Boolean
    begin
        // TODO: the guard on the left does not stop the division on the right —
        // AL evaluates both operands of `and`, so a zero Qty still divides by zero.
        exit((Qty <> 0) and (Total / Qty > Limit));
    end;

    procedure HasOpenOrder(CustomerNo: Code[20]): Boolean
    begin
        // TODO: same trap — OpenOrderExists runs for a blank CustomerNo as well,
        // and its Get fails because no customer has a blank number.
        exit((CustomerNo <> '') and OpenOrderExists(CustomerNo));
    end;

    // Written for a customer that exists: the bare Get raises an error otherwise.
    local procedure OpenOrderExists(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Customer.Get(CustomerNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.SetRange(Status, SalesHeader.Status::Open);
        exit(not SalesHeader.IsEmpty());
    end;
}
