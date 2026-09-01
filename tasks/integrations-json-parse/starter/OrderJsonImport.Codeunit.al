codeunit 50102 "Order Json Import"
{
    procedure ImportOrder(OrderJson: Text): Code[20]
    begin
        // TODO: Parse OrderJson into one "Web Order Header" record and its
        // "Web Order Line" records, converting every value safely, and return
        // the imported order no. A failed import must write nothing.
    end;
}
