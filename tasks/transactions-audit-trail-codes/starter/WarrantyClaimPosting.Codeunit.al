codeunit 50100 "Warranty Claim Posting"
{
    procedure InitAuditCodes()
    begin
        // TODO: make the company ready — create the "Source Code Setup" singleton
        // if it is missing, then seed WARRANTY and WARRCLAIM into the two warranty
        // fields, but only while those fields are still blank.
    end;

    procedure PostWarrantyClaim(var GenJournalLine: Record "Gen. Journal Line")
    begin
        // TODO: stamp the two setup codes onto the line, then post it — without
        // committing anything.
    end;
}
