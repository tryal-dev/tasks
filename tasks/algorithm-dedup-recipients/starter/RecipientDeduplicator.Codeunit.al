codeunit 50100 "Recipient Deduplicator"
{
    procedure Dedupe(Recipients: Text): Text
    begin
        // TODO: split on ';', trim each entry, drop the empty ones, and keep
        // only the first case-insensitive occurrence of each address —
        // in first-seen order, joined with '; '.
        exit(Recipients);
    end;
}
