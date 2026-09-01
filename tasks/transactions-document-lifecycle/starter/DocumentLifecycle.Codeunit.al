codeunit 50102 "Document Lifecycle"
{
    procedure Release(var LifecycleDocument: Record "Lifecycle Document")
    begin
        // TODO: legal only from Open; require a non-zero Amount; move the
        // document to Released.
    end;

    procedure Reopen(var LifecycleDocument: Record "Lifecycle Document")
    begin
        // TODO: legal only from Released; move the document back to Open.
    end;

    procedure Post(var LifecycleDocument: Record "Lifecycle Document")
    begin
        // TODO: legal only from Released; move the document to Posted and
        // stamp "Posted On".
    end;
}
