codeunit 50901 "Delete Event Blocker"
{
    // While bound, this subscriber puts Staging Entry into one of the states the
    // platform's bulk truncation refuses to handle — the body is deliberately empty,
    // only the active subscription matters.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Staging Entry", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteStagingEntry(var Rec: Record "Staging Entry"; RunTrigger: Boolean)
    begin
    end;
}
