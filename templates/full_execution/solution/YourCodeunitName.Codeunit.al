// Reference solution — never served to users; used by lint/CI as proof the
// task is solvable. It must be a valid submission (<= 6 files, <= 70 KB each,
// .al only) and must pass every test in tests/.
codeunit 50100 "Your Codeunit Name"
{
    procedure YourProcedure(Input: Decimal): Decimal
    begin
        exit(Input * 2);
    end;
}
