// Reference solution — never served to users; the proof the task is solvable.
// It must be a valid submission (<= 6 files, <= 70 KB each, .al only) and must
// pass every test in tests/. Whether it is committed depends on the catalog:
// in a public catalog tasks/*/solution/ is gitignored and the maintainers keep
// the reference copy privately (CONTRIBUTING.md, "Reference solutions").
codeunit 50100 "Your Codeunit Name"
{
    procedure YourProcedure(Input: Decimal): Decimal
    begin
        exit(Input * 2);
    end;
}
