codeunit 50100 "Phone E164 Formatter"
{
    procedure ToE164(Raw: Text; DefaultCountryPrefix: Text): Text
    begin
        // TODO: normalize Raw into +<country code><subscriber number> following the
        // steps in the statement, or raise the matching error; for example
        // '(0)151 234-5678' with '+49' becomes '+491512345678'.
    end;
}
