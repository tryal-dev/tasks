codeunit 50100 "Customer Name Search"
{
    procedure CountExactName(NameToFind: Text): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: NameToFind is parsed as a filter EXPRESSION here — a name
        // like O'Brien & Sons breaks the search instead of being found.
        Customer.SetFilter(Name, NameToFind);
        exit(Customer.Count());
    end;

    procedure CountNamesContaining(Fragment: Text): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: same trap — symbols inside Fragment still act as operators.
        Customer.SetFilter(Name, '*' + Fragment + '*');
        exit(Customer.Count());
    end;
}
