codeunit 50100 "Luhn Validator"
{
    procedure IsValid(Input: Text): Boolean
    begin
        // TODO: ignore spaces, reject anything else that is not a digit and
        // inputs shorter than two characters, then run the checksum from the
        // rightmost digit.
        exit(false);
    end;
}
