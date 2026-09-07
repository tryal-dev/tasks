codeunit 50100 "Date Filter Describer"
{
    var
        FromToLbl: Label 'from %1 to %2', Comment = '%1 = first day, %2 = last day, both as yyyy-mm-dd', Locked = true;

    procedure DescribeDateFilter(var CustLedgerEntry: Record "Cust. Ledger Entry"): Text
    var
        FromDate: Date;
        ToDate: Date;
    begin
        // TODO: this is the export's current code — it reads the bounds as if every
        // filter were a range. Make it honour all six rules of the statement.
        FromDate := CustLedgerEntry.GetRangeMin("Posting Date");
        ToDate := CustLedgerEntry.GetRangeMax("Posting Date");
        exit(StrSubstNo(FromToLbl, Format(FromDate, 0, 9), Format(ToDate, 0, 9)));
    end;
}
