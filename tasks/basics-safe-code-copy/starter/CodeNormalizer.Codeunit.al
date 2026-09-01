codeunit 50100 "Code Normalizer"
{
    procedure ToCode20(Input: Text): Code[20]
    begin
        // TODO: this naive conversion crashes on input longer than
        // 20 characters — trim, truncate safely, then return.
        exit(Input);
    end;
}
