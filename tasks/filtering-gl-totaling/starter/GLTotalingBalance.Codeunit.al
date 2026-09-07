codeunit 50100 "G/L Totaling Balance"
{
    procedure TotalingBalance(AccountNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        // TODO: return the net change, from FromDate through ToDate, of the posting
        // accounts named by GLAccount.Totaling — see the task statement for the rules.
        exit(0);
    end;
}
