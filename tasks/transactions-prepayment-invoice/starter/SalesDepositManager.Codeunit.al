codeunit 50100 "Sales Deposit Manager"
{
    procedure SetDeposit(var SalesHeader: Record "Sales Header"; DepositPct: Decimal; CompressLines: Boolean)
    begin
        // TODO: put the deposit percentage on the order AND on every one of its
        // lines, record whether the prepayment invoice should be compressed, and
        // leave all of it in the database.
    end;

    procedure PostDeposit(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        // TODO: post the order's prepayment invoice without committing, and
        // return the number of the posted prepayment invoice.
    end;

    procedure PostFinalInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        // TODO: ship and invoice the whole order without committing, and return
        // the number of the posted sales invoice.
    end;

    procedure RemoveLine(var SalesLine: Record "Sales Line")
    begin
        // TODO: take the line off the order, letting the prepayment guard refuse
        // a line whose deposit has already been invoiced.
    end;
}
