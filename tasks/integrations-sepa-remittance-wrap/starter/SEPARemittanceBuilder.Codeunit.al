codeunit 50100 "SEPA Remittance Builder"
{
    procedure AddInvoice(InvoiceNo: Text; Amount: Decimal)
    begin
        // TODO: compose the entry — invoice number, one space, the amount with
        // exactly two decimals and a dot — refuse entries that could never fit within
        // 140 characters, and remember the rest in order.
    end;

    procedure GetRemittanceText(): Text
    begin
        // TODO: join the entries with ', ' and cap the text at 140 characters;
        // when the full join does not fit, end with 'and N more' — remember the
        // suffix takes space too.
        exit('');
    end;
}
