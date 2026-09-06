codeunit 50100 "Notification Flags"
{
    procedure HasFlag(Value: Integer; Bit: Integer): Boolean
    begin
        // TODO: AL has no bitwise operators — `and` and `or` only take Booleans.
        // Decide with div and mod whether the flag Bit is part of Value.
    end;

    procedure SetFlag(Value: Integer; Bit: Integer): Integer
    begin
        // TODO: adding unconditionally double-counts a flag that is already set —
        // 9 + 8 = 17 means Email + Urgent first, not Email + Post.
        exit(Value + Bit);
    end;

    procedure ClearFlag(Value: Integer; Bit: Integer): Integer
    begin
        // TODO: subtracting unconditionally borrows from other flags when Bit is
        // not set — 9 - 2 = 7 means Email + SMS + Portal.
        exit(Value - Bit);
    end;

    procedure Channels(Value: Integer): List of [Text]
    var
        Result: List of [Text];
    begin
        // TODO: collect the names of the set channel flags in ascending order,
        // reversed when the Urgent first flag (16) is set.
        exit(Result);
    end;
}
