codeunit 50100 "IBAN Verifier"
{
    procedure IsValid(IBAN: Text): Boolean
    begin
        // TODO: normalize the input, apply the structure gate, then the mod-97
        // check from the statement, for example 'GB82 WEST 1234 5698 7654 32' is valid.
    end;
}
