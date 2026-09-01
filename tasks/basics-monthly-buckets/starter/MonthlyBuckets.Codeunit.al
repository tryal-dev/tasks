codeunit 50100 "Monthly Buckets"
{
    procedure MonthlySales(CustomerNo: Code[20]; Year: Integer; var Buckets: array[12] of Decimal)
    begin
        // TODO: reset every bucket, then add each ledger entry's "Sales (LCY)" to the bucket of its posting month.
    end;

    procedure AddToMonth(var Buckets: array[12] of Decimal; Month: Integer; Amount: Decimal)
    begin
        // TODO: refuse a month outside 1 to 12, then add the amount to that month's bucket.
    end;

    procedure QuarterTotals(Buckets: array[12] of Decimal; var Quarters: array[4] of Decimal)
    begin
        // TODO: fold every three months into one quarter.
    end;

    procedure ShiftWindow(var Buckets: array[12] of Decimal; NewMonthTotal: Decimal)
    begin
        // TODO: drop the oldest month, move the rest one slot towards the front, and put the new month last.
    end;

    procedure NonEmptyMonthLabels(Buckets: array[12] of Decimal; var Labels: array[12] of Text): Integer
    begin
        // TODO: label every non-empty month, pack the labels to the front, and return how many there are.
    end;
}
