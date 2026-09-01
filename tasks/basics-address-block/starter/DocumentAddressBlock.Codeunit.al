codeunit 50100 "Document Address Block"
{
    procedure BuildAddressBlock(var AddressBlock: array[8] of Text[100]; Name: Text[100]; Name2: Text[100]; ContactName: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; CountryCode: Code[10]; LanguageCode: Code[10])
    begin
        // TODO: fill AddressBlock[1] .. AddressBlock[8] with the printed address
        // block for CountryCode, in the language given by LanguageCode.
    end;
}
