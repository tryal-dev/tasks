codeunit 50101 "Import Line Validator"
{
    procedure ValidateLine(ImportOrderLine: Record "Import Order Line")
    begin
        // TODO: raise an error with the exact message of the FIRST broken
        // rule from the task statement; return silently for a valid line.
    end;

    procedure ValidateBatch(BatchCode: Code[20]; var Problems: List of [Text])
    begin
        // TODO: report EVERY broken line of the batch in Problems, in
        // Line No. order — without raising a single error yourself.
    end;
}
