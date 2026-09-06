codeunit 50100 "Customer Phone Update"
{
    procedure UpdatePhone(CustomerNo: Code[20]; Phone: Text[30])
    var
        Customer: Record Customer;
    begin
        // TODO: this variable was never loaded from the database, so Modify
        // writes its blanks over the customer's name, address and everything else.
        Customer."No." := CustomerNo;
        Customer."Phone No." := Phone;
        Customer.Modify();
    end;
}
