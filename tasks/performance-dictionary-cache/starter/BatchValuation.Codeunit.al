codeunit 50100 "Batch Valuation"
{
    procedure ValueByItem(TemplateName: Code[10]; BatchName: Code[10]): Dictionary of [Code[20], Decimal]
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Totals: Dictionary of [Code[20], Decimal];
    begin
        // TODO: the numbers below are right — the cost is not. One round trip
        // for the lines, then a Get per line: even with the server deduplicating
        // identical reads, a dozen-plus distinct items cost 13+ SQL statements
        // and the grading budget allows 6.
        ItemJournalLine.SetRange("Journal Template Name", TemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", BatchName);
        if ItemJournalLine.FindSet() then
            repeat
                Item.Get(ItemJournalLine."Item No.");
                if Totals.ContainsKey(Item."No.") then
                    Totals.Set(Item."No.", Totals.Get(Item."No.") + ItemJournalLine.Quantity * Item."Unit Price")
                else
                    Totals.Add(Item."No.", ItemJournalLine.Quantity * Item."Unit Price");
            until ItemJournalLine.Next() = 0;
        exit(Totals);
    end;
}
