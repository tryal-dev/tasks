codeunit 50100 "Receipt Correction"
{
    procedure UndoReceiptLine(ReceiptNo: Code[20]; LineNo: Integer): Decimal
    begin
        // TODO: refuse a missing, already reversed or already invoiced line with
        // the messages from the statement, otherwise reverse exactly this posted
        // receipt line — silently — and return the quantity that was reversed.
    end;

    procedure IsReversible(ReceiptNo: Code[20]; LineNo: Integer): Boolean
    begin
        // TODO: report whether UndoReceiptLine would proceed for this line.
    end;
}
