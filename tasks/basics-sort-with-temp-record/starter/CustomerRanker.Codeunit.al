codeunit 50100 "Customer Ranker"
{
    procedure RankCustomers(Scores: Dictionary of [Code[20], Decimal]): List of [Code[20]]
    var
        Ranked: List of [Code[20]];
    begin
        // TODO: copy every score into a "Customer Score Buffer" record, read the
        // buffer back sorted by score (highest first, ties by customer number)
        // and collect the customer numbers in that order.
        exit(Ranked);
    end;
}
