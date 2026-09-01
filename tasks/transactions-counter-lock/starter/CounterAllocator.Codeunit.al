codeunit 50101 "Counter Allocator"
{
    procedure NextValue(CounterCode: Code[20]): Integer
    begin
        // TODO: return the counter's next number and save it back to the row,
        // reading the row's current state safely on every call.
    end;

    procedure ReserveBlock(CounterCode: Code[20]; BlockSize: Integer): Integer
    begin
        // TODO: reject a non-positive block size, then hand out BlockSize
        // consecutive numbers: return the first, advance the row to the last.
    end;
}
