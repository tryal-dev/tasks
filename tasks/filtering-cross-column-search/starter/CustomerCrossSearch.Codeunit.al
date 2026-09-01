codeunit 50100 "Customer Cross Search"
{
    procedure CountMatches(SearchText: Text): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: two filters set this way must BOTH hold — this counts the
        // customers carrying the text in Name AND City, not in either one.
        Customer.SetFilter(Name, '@*' + SearchText + '*');
        Customer.SetFilter(City, '@*' + SearchText + '*');
        exit(Customer.Count());
    end;

    procedure CountContactableMatches(SearchText: Text): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: same intersection trap — and the e-mail rule is missing entirely.
        Customer.SetFilter(Name, '@*' + SearchText + '*');
        Customer.SetFilter(City, '@*' + SearchText + '*');
        exit(Customer.Count());
    end;
}
