codeunit 50100 "Storage Meter"
{
    procedure TotalBytes(Sizes: List of [Decimal]): BigInteger
    var
        Size: Decimal;
        Total: Integer;
    begin
        // TODO: Total tops out at 2,147,483,647 — the meter crashes with an overflow
        // the moment an archive passes 2 GB, although the result type is wide enough.
        foreach Size in Sizes do
            Total += Size;
        exit(Total);
    end;

    procedure QuotaBytes(Gigabytes: Integer): BigInteger
    begin
        // TODO: Integer × Integer is evaluated as an Integer before it reaches the
        // BigInteger result — 2 × 1,073,741,824 already overflows.
        exit(Gigabytes * 1073741824);
    end;
}
