codeunit 50100 "Customer Lookup"
{
    procedure CountInCity(CityName: Text): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: count only the customers whose City equals CityName —
        // right now every customer in the company is counted.
        exit(Customer.Count());
    end;

    procedure CountInEitherCity(FirstCity: Text; SecondCity: Text): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: count the customers whose City is FirstCity or SecondCity,
        // each customer once.
        exit(Customer.Count());
    end;

    procedure CountWithEmailInCity(CityName: Text): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: count the customers in CityName whose "E-Mail" is not blank.
        exit(Customer.Count());
    end;
}
