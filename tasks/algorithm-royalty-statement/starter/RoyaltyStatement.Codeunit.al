codeunit 50102 "Royalty Statement"
{
    procedure LineAmount(Category: Code[20]; Audience: Integer): Decimal
    begin
        // TODO: the per-category fee — tragedy and comedy each have a base fee
        // and a threshold surcharge; any other category must raise an error
        // (see the task statement).
    end;

    procedure LineCredits(Category: Code[20]; Audience: Integer): Integer
    begin
        // TODO: one credit per attendee above 30; a comedy adds one credit per
        // full group of 5 attendees; any other category must raise an error.
    end;

    procedure BuildStatement(AgreementNo: Code[20]; var RoyaltyStatementLine: Record "Royalty Statement Line" temporary; var TotalAmount: Decimal; var TotalCredits: Integer)
    begin
        // TODO: clear the buffer and both totals, then add one numbered line
        // per performance of the agreement and accumulate the totals.
    end;
}
