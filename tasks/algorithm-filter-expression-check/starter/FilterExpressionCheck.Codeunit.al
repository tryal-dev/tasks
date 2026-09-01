codeunit 50100 "Filter Expression Check"
{
    procedure IsValid(Expression: Text): Boolean
    begin
        // TODO: validate the expression against the seven grammar rules.
        // Right now anything non-empty is waved through — exactly how
        // '1000..2000|' reached the nightly job.
        exit(Expression <> '');
    end;
}
