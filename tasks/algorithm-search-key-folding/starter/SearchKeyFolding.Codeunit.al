codeunit 50100 "Search Key Folding"
{
    procedure ToSearchKey(Input: Text): Text
    begin
        // TODO: UpperCase turns ü into Ü, not into U — accents stay unfolded,
        // and punctuation and whitespace pass straight through.
        exit(UpperCase(Input));
    end;

    procedure CountCustomersMatching(Query: Text): Integer
    var
        Customer: Record Customer;
    begin
        // TODO: an exact Name filter only hits the stored spelling —
        // MÜLLER, muller and Müller never meet on a folded key here.
        Customer.SetRange(Name, Query);
        exit(Customer.Count());
    end;
}
