codeunit 50100 "Version Compare"
{
    procedure IsAtLeast(Actual: Text; Minimum: Text): Boolean
    begin
        // TODO: this compares text character by character, so '1.10.0' counts
        // as OLDER than '1.9.5' — parse both sides into Version values instead.
        exit(Actual >= Minimum);
    end;

    procedure Normalize(Input: Text): Text
    begin
        // TODO: return the canonical Major.Minor.Build.Revision text, or an
        // empty text when the input is not a version.
        exit(Input);
    end;
}
