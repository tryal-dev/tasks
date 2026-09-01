codeunit 50102 "Wallet Statement Builder"
{
    procedure RecordTransaction(AccountNo: Code[20]; PostingDate: Date; Amount: Decimal; Description: Text[100]): Integer
    begin
        // TODO: insert a "Wallet Transaction" carrying these values under the next
        // entry number in the ledger-wide sequence, and return that entry number.
        exit(0);
    end;

    procedure BuildStatement(AccountNo: Code[20]; var WalletStatementLine: Record "Wallet Statement Line" temporary)
    begin
        // TODO: empty the buffer, then fill it with the account's transactions
        // newest first, line numbers 1..n, each line carrying the running balance
        // the wallet had right after that transaction.
    end;
}
