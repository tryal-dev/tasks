codeunit 50102 "Order Import Batch"
{
    procedure ImportBatch(BatchCode: Code[20])
    begin
        // TODO: walk the batch's pending lines in ascending Line No. order,
        // guard each one, turn it into an Imported Order and mark it
        // Imported — and make sure a line that fails cannot undo the lines
        // already imported before it.
    end;
}
