codeunit 50100 "Vendor Code Suggestion"
{
    procedure SuggestVendorNo(Name: Text): Code[20]
    begin
        // TODO: build the code from the initials of Name — spaces and hyphens
        // split words, other punctuation is dropped, the result is cut to 20.
    end;

    procedure UniqueVendorNo(Name: Text): Code[20]
    begin
        // TODO: start from SuggestVendorNo(Name) and append -2, -3, ... while a
        // Vendor with that number exists, keeping every candidate within 20 characters.
    end;
}
