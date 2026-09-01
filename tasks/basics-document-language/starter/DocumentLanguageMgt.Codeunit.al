codeunit 50100 "Document Language Mgt."
{
    procedure GreetingInSessionLanguage(): Text
    begin
        // TODO: return the greeting for the language the session is running in
        // right now — nothing but GlobalLanguage() says which one that is.
        exit('');
    end;

    procedure ConfirmationLineFor(CustomerNo: Code[20]): Text
    begin
        // TODO: resolve the customer's "Language Code", build "<Name>: <greeting>"
        // in that language, reject a line longer than 100 characters, and leave
        // the session language exactly as you found it — error path included.
        exit('');
    end;

    procedure WireTagFor(CustomerNo: Code[20]): Text
    begin
        // TODO: the two-letter ISO name of the customer's resolved language.
        exit('');
    end;

    procedure AuditLineFor(CustomerNo: Code[20]): Text
    begin
        // TODO: the same line, always in the default application language.
        exit('');
    end;
}
