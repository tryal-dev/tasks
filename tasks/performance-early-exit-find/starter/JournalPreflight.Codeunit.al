codeunit 50101 "Journal Preflight"
{
    procedure CheckBatch(BatchName: Code[10]): Integer
    var
        DraftJournalLine: Record "Draft Journal Line";
    begin
        // TODO: the verdict is right — the cost is not. This read hauls the
        // whole batch across the wire even when the third line already fails,
        // and the grading budget allows 2,000 rows for a 20,000-line batch.
        DraftJournalLine.SetRange("Batch Name", BatchName);
        if DraftJournalLine.FindSet() then
            repeat
                if IsDefective(DraftJournalLine) then
                    exit(DraftJournalLine."Line No.");
            until DraftJournalLine.Next() = 0;
        exit(0);
    end;

    procedure CountDefects(BatchName: Code[10]): Integer
    begin
        // TODO: count the batch's defective lines. Decide for yourself what
        // kind of read this answer deserves — it is not the same decision
        // as in CheckBatch.
        exit(0);
    end;

    local procedure IsDefective(var DraftJournalLine: Record "Draft Journal Line"): Boolean
    begin
        exit((DraftJournalLine."Account No." = '') or (DraftJournalLine.Amount = 0));
    end;
}
