codeunit 50101 "Package Scan Validator"
{
    procedure ResolveCodeLength(): Integer
    begin
        // TODO: return the configured code length, or raise the configuration
        // error from the task statement when the setup cannot be used.
    end;

    procedure CheckScan(ScannedCode: Text; CodeLength: Integer)
    begin
        // TODO: raise the message of the first broken scan rule; a good code
        // returns silently.
    end;

    procedure ValidateBatch(ScannedCodes: List of [Text]; var Failures: List of [Text]): Integer
    var
        ScannedCode: Text;
        Passed: Integer;
    begin
        Clear(Failures);

        // TODO: this loop does not survive a broken code — the caller is hit
        // by the scan error, the codes after the broken one are never looked
        // at, Failures stays empty, and Passed counts codes that passed
        // nothing. A broken setup, on the other hand, must still reach the
        // caller.
        foreach ScannedCode in ScannedCodes do begin
            TryCheckScan(ScannedCode, ResolveCodeLength());
            Passed += 1;
        end;

        exit(Passed);
    end;

    [TryFunction]
    local procedure TryCheckScan(ScannedCode: Text; CodeLength: Integer)
    begin
        CheckScan(ScannedCode, CodeLength);
    end;
}
