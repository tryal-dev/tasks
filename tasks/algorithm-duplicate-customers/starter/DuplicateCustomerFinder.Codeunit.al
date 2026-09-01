codeunit 50100 "Duplicate Customer Finder"
{
    procedure Normalize(Value: Text): Text
    begin
        // TODO: keep only letters and digits, uppercase the letters,
        // and drop everything else — spaces, tabs, punctuation, symbols.
        exit(Value);
    end;

    procedure FindDuplicatesOf(CustomerNo: Code[20]): List of [Code[20]]
    var
        Duplicates: List of [Code[20]];
    begin
        // TODO: return every other customer whose normalized Name or
        // normalized "VAT Registration No." matches this customer's —
        // empty keys never match, each duplicate once, ascending by "No.".
        exit(Duplicates);
    end;
}
