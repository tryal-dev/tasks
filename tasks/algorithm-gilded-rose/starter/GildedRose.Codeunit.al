codeunit 50100 "Gilded Rose"
{
    procedure UpdateItem(var GildedItem: Record "Gilded Item")
    begin
        // TODO: the previous innkeeper aged every item like a Normal one —
        // Aged Brie, Sulfuras, Backstage Pass and Conjured each follow their
        // own rules (see the task statement).
        if GildedItem."Sell In" <= 0 then
            GildedItem.Quality -= 2
        else
            GildedItem.Quality -= 1;
        if GildedItem.Quality < 0 then
            GildedItem.Quality := 0;
        GildedItem."Sell In" -= 1;
        GildedItem.Modify();
    end;

    procedure EndOfDay()
    begin
        // TODO: run the one-day update for every record in the Gilded Item table.
    end;
}
