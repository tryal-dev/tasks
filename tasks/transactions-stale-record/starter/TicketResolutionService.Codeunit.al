codeunit 50101 "Ticket Resolution Service"
{
    procedure ResolveTicket(StaleTicket: Record "Support Ticket"; ResolutionNote: Text[100]): Boolean
    begin
        // TODO: land Resolved and "Resolution Note" on the ticket's current
        // database row without touching any other field, and report whether
        // the ticket still exists.
    end;
}
