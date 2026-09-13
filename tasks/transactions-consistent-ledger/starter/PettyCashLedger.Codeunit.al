codeunit 50101 "Petty Cash Ledger"
{
    procedure PostEntry(DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        PettyCashEntry: Record "Petty Cash Entry";
    begin
        // TODO: refuse a zero amount — and make sure a transaction that
        // leaves the ledger unbalanced can never be committed. Writing the
        // leg is the easy part; as it stands, a lone leg sails through Commit.
    end;

    procedure PostTransfer(DocumentNo: Code[20]; FromAccount: Code[20]; ToAccount: Code[20]; Amount: Decimal)
    begin
        // TODO: refuse an amount that is not positive, then post the two
        // legs of the transfer.
    end;

}
