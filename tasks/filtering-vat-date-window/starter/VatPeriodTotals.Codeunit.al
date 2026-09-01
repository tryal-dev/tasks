codeunit 50100 "VAT Period Totals"
{
    procedure VatTotalsForPeriod(VatBusPostingGroup: Code[20]; VatProdPostingGroup: Code[20]; FromDate: Date; ToDate: Date; var TotalBase: Decimal; var TotalAmount: Decimal)
    var
        VatEntry: Record "VAT Entry";
    begin
        // TODO: the VAT return is cut by the VAT date, not the posting date —
        // this misfiles every document whose two dates fall in different periods,
        // and entries with a blank VAT date are handled wrong too.
        VatEntry.SetRange("VAT Bus. Posting Group", VatBusPostingGroup);
        VatEntry.SetRange("VAT Prod. Posting Group", VatProdPostingGroup);
        VatEntry.SetRange("Posting Date", FromDate, ToDate);
        VatEntry.CalcSums(Base, Amount);
        TotalBase := VatEntry.Base;
        TotalAmount := VatEntry.Amount;
    end;
}
