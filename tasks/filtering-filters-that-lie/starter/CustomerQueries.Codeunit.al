codeunit 50100 "Customer Queries"
{
    procedure CountWithoutSalesperson(): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: meant to keep only the customers whose "Salesperson Code" is
        // blank, yet it counts every customer in the company.
        Customer.SetFilter("Salesperson Code", '');
        exit(Customer.Count());
    end;

    procedure CountInRange(FromNo: Code[20]; ToNo: Code[20]): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: meant to keep the customers numbered FromNo through ToNo, yet
        // it always counts 0.
        Customer.SetRange("No.", FromNo + '..' + ToNo);
        exit(Customer.Count());
    end;
}
