codeunit 50103 "Mini Jnl.-Post Batch"
{
    procedure PostBatch(BatchName: Code[10])
    begin
        // TODO: find the batch's open lines, guard each one, prove the batch
        // balances, then turn every line into a numbered ledger entry and
        // mark it Posted.
    end;
}
