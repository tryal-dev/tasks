// Grading tests for error-handling-try-call-contract.
//
// [FEATURE] [Package Scan Validator]
codeunit 50900 "Package Scan Validator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckScanAcceptsACodeOfTheConfiguredLength()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Any: Codeunit Any;
        CodeLength: Integer;
    begin
        // [SCENARIO] a code of exactly the required length, all digits, passes silently
        // [GIVEN] a required length and a code of that many digits
        CodeLength := Any.IntegerInRange(5, 9);

        // [WHEN] checking that code
        // [THEN] it returns without raising — any error here fails the test
        PackageScanValidator.CheckScan(DigitCode(Any, CodeLength), CodeLength);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckScanRejectsACodeThatIsTooShort()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CodeLength: Integer;
        ScannedCode: Text;
    begin
        // [SCENARIO] a code one character short raises the length message
        // [GIVEN] a code of CodeLength - 1 digits
        CodeLength := Any.IntegerInRange(5, 9);
        ScannedCode := DigitCode(Any, CodeLength - 1);

        // [WHEN] checking that code
        asserterror PackageScanValidator.CheckScan(ScannedCode, CodeLength);

        // [THEN] the error carries exactly the promised length message
        Assert.AreEqual(StrSubstNo('''%1'' must be exactly %2 characters long.', ScannedCode, CodeLength), GetLastErrorText(),
            'Expected a code shorter than the required length to raise exactly the length message from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckScanRejectsACodeThatIsTooLong()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CodeLength: Integer;
        ScannedCode: Text;
    begin
        // [SCENARIO] a code one character too long raises the length message
        // [GIVEN] a code of CodeLength + 1 digits
        CodeLength := Any.IntegerInRange(5, 9);
        ScannedCode := DigitCode(Any, CodeLength + 1);

        // [WHEN] checking that code
        asserterror PackageScanValidator.CheckScan(ScannedCode, CodeLength);

        // [THEN] the error carries exactly the promised length message
        Assert.AreEqual(StrSubstNo('''%1'' must be exactly %2 characters long.', ScannedCode, CodeLength), GetLastErrorText(),
            'Expected a code longer than the required length to raise exactly the length message from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckScanRejectsACodeThatContainsALetter()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CodeLength: Integer;
        ScannedCode: Text;
    begin
        // [SCENARIO] a code of the right length but with a letter raises the digits message
        // [GIVEN] a code of the required length whose last character is a letter
        CodeLength := Any.IntegerInRange(5, 9);
        ScannedCode := DigitCode(Any, CodeLength - 1) + 'X';

        // [WHEN] checking that code
        asserterror PackageScanValidator.CheckScan(ScannedCode, CodeLength);

        // [THEN] the error carries exactly the promised digits message
        Assert.AreEqual(StrSubstNo('''%1'' must contain digits only.', ScannedCode), GetLastErrorText(),
            'Expected a code of the right length carrying a letter to raise exactly the digits-only message from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckScanRejectsACodeThatContainsANonDigitSymbol()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CodeLength: Integer;
        ScannedCode: Text;
    begin
        // [SCENARIO] a code of the right length carrying a symbol raises the digits message — the rule is digits only, not merely letter-free
        // [GIVEN] a code of the required length whose first character is a minus sign
        CodeLength := Any.IntegerInRange(5, 9);
        ScannedCode := '-' + DigitCode(Any, CodeLength - 1);

        // [WHEN] checking that code
        asserterror PackageScanValidator.CheckScan(ScannedCode, CodeLength);

        // [THEN] the error carries exactly the promised digits message
        Assert.AreEqual(StrSubstNo('''%1'' must contain digits only.', ScannedCode), GetLastErrorText(),
            'Expected a code of the right length carrying a non-digit symbol to raise exactly the digits-only message from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckScanReportsTheLengthProblemBeforeTheDigitsProblem()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] a code breaking both rules is reported as a length problem
        // [GIVEN] a two-letter code where eight digits are required

        // [WHEN] checking that code
        asserterror PackageScanValidator.CheckScan('XY', 8);

        // [THEN] the length rule wins — it is checked first
        Assert.AreEqual('''XY'' must be exactly 8 characters long.', GetLastErrorText(),
            'Expected the length rule to be reported for a code that breaks both rules — length is checked before the digits rule');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveCodeLengthReturnsTheConfiguredLength()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CodeLength: Integer;
    begin
        // [SCENARIO] a usable setup yields its Code Length
        // [GIVEN] a Package Scan Setup record with a positive Code Length
        CodeLength := Any.IntegerInRange(5, 9);
        SetCodeLength(CodeLength);

        // [WHEN] resolving the configuration
        // [THEN] the configured length comes back
        Assert.AreEqual(CodeLength, PackageScanValidator.ResolveCodeLength(),
            'Expected ResolveCodeLength to return the Code Length stored in Package Scan Setup');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveCodeLengthFailsWhenTheSetupIsMissing()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] no setup record at all is a configuration error
        // [GIVEN] an empty Package Scan Setup table
        RemoveSetup();

        // [WHEN] resolving the configuration
        asserterror PackageScanValidator.ResolveCodeLength();

        // [THEN] the error carries exactly the promised missing-setup message
        Assert.AreEqual('Package Scan Setup is missing.', GetLastErrorText(),
            'Expected a missing Package Scan Setup record to raise exactly the missing-setup message from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveCodeLengthFailsWhenTheConfiguredLengthIsZero()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] a Code Length of exactly 0 is a configuration error — the rule is strictly greater than zero
        // [GIVEN] a setup record whose Code Length is 0
        SetCodeLength(0);

        // [WHEN] resolving the configuration
        asserterror PackageScanValidator.ResolveCodeLength();

        // [THEN] the error carries exactly the promised length message
        Assert.AreEqual('Code Length must be greater than zero in Package Scan Setup.', GetLastErrorText(),
            'Expected a Code Length of 0 to raise exactly the non-positive-length message from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveCodeLengthFailsWhenTheConfiguredLengthIsNegative()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] a negative Code Length is a configuration error too, not a required length no code can ever match
        // [GIVEN] a setup record whose Code Length is below zero
        SetCodeLength(-Any.IntegerInRange(1, 5));

        // [WHEN] resolving the configuration
        asserterror PackageScanValidator.ResolveCodeLength();

        // [THEN] the error carries exactly the promised length message
        Assert.AreEqual('Code Length must be greater than zero in Package Scan Setup.', GetLastErrorText(),
            'Expected a negative Code Length to raise exactly the non-positive-length message from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchReportsABrokenCodeInsteadOfRaisingIt()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ScannedCodes: List of [Text];
        Failures: List of [Text];
        CodeLength: Integer;
        BrokenCode: Text;
    begin
        // [SCENARIO] a scan problem is reported, never raised
        // [GIVEN] a usable setup and a batch holding one code that is too short
        CodeLength := Any.IntegerInRange(5, 9);
        SetCodeLength(CodeLength);
        BrokenCode := DigitCode(Any, CodeLength - 1);
        ScannedCodes.Add(BrokenCode);

        // [WHEN] validating the batch — called directly: an error raised here fails the test
        Assert.AreEqual(0, PackageScanValidator.ValidateBatch(ScannedCodes, Failures),
            'Expected 0 passed codes for a batch whose only code is broken — and no error: a scan problem belongs in Failures, not in the caller');

        // [THEN] the broken code shows up once, with the message CheckScan would have raised
        Assert.AreEqual(1, Failures.Count(),
            'Expected exactly one entry in Failures for a batch with exactly one broken code');
        Assert.AreEqual(StrSubstNo('''%1'' must be exactly %2 characters long.', BrokenCode, CodeLength), Failures.Get(1),
            'Expected the Failures entry to be exactly the message CheckScan raises for that code');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchChecksEveryCodeBehindABrokenOne()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ScannedCodes: List of [Text];
        Failures: List of [Text];
        CodeLength: Integer;
        FirstBroken: Text;
        SecondBroken: Text;
    begin
        // [SCENARIO] the codes behind a broken one are still checked, and Failures keeps the input order
        // [GIVEN] a batch of broken, good, broken, good — the first code is already broken
        CodeLength := Any.IntegerInRange(5, 9);
        SetCodeLength(CodeLength);
        FirstBroken := DigitCode(Any, CodeLength - 1);
        SecondBroken := DigitCode(Any, CodeLength - 1) + 'x';
        ScannedCodes.Add(FirstBroken);
        ScannedCodes.Add(DigitCode(Any, CodeLength));
        ScannedCodes.Add(SecondBroken);
        ScannedCodes.Add(DigitCode(Any, CodeLength));

        // [WHEN] validating the batch
        Assert.AreEqual(2, PackageScanValidator.ValidateBatch(ScannedCodes, Failures),
            'Expected the two good codes to be counted — a broken code must not stop the batch, not even the very first one');

        // [THEN] both broken codes are reported, in the order they were scanned
        Assert.AreEqual(2, Failures.Count(),
            'Expected one Failures entry per broken code — two of the four codes are broken');
        Assert.AreEqual(StrSubstNo('''%1'' must be exactly %2 characters long.', FirstBroken, CodeLength), Failures.Get(1),
            'Expected the first Failures entry to describe the first broken code — Failures follows the order of the batch');
        Assert.AreEqual(StrSubstNo('''%1'' must contain digits only.', SecondBroken), Failures.Get(2),
            'Expected the second Failures entry to describe the second broken code — Failures follows the order of the batch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchCountsAnEntirelyValidBatch()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ScannedCodes: List of [Text];
        Failures: List of [Text];
        CodeLength: Integer;
    begin
        // [SCENARIO] every code passing means every code counted and nothing reported
        // [GIVEN] a usable setup and three good codes
        CodeLength := Any.IntegerInRange(5, 9);
        SetCodeLength(CodeLength);
        ScannedCodes.Add(DigitCode(Any, CodeLength));
        ScannedCodes.Add(DigitCode(Any, CodeLength));
        ScannedCodes.Add(DigitCode(Any, CodeLength));

        // [WHEN] validating the batch
        Assert.AreEqual(3, PackageScanValidator.ValidateBatch(ScannedCodes, Failures),
            'Expected all three good codes to be counted as passed');

        // [THEN] nothing is reported
        Assert.AreEqual(0, Failures.Count(),
            'Expected an empty Failures list for a batch in which every code passes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchReturnsZeroForAnEmptyBatch()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ScannedCodes: List of [Text];
        Failures: List of [Text];
    begin
        // [SCENARIO] an empty batch on a usable setup is a clean, empty result
        // [GIVEN] a usable setup and no scanned codes at all
        SetCodeLength(Any.IntegerInRange(5, 9));

        // [WHEN] validating the empty batch
        Assert.AreEqual(0, PackageScanValidator.ValidateBatch(ScannedCodes, Failures),
            'Expected 0 passed codes for an empty batch');

        // [THEN] nothing is reported
        Assert.AreEqual(0, Failures.Count(),
            'Expected an empty Failures list for an empty batch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchClearsFailuresFromAnEarlierRun()
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ScannedCodes: List of [Text];
        Failures: List of [Text];
        CodeLength: Integer;
    begin
        // [SCENARIO] whatever Failures already holds is discarded before the batch is checked
        // [GIVEN] a Failures list carrying leftovers and a batch in which every code passes
        CodeLength := Any.IntegerInRange(5, 9);
        SetCodeLength(CodeLength);
        Failures.Add('TRYAL-stale-1');
        Failures.Add('TRYAL-stale-2');
        ScannedCodes.Add(DigitCode(Any, CodeLength));

        // [WHEN] validating the batch
        PackageScanValidator.ValidateBatch(ScannedCodes, Failures);

        // [THEN] only this run's findings remain — none
        Assert.AreEqual(0, Failures.Count(),
            'Expected ValidateBatch to clear Failures before it starts — the leftovers of an earlier run must not survive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchLetsTheMissingSetupErrorReachTheCaller()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ScannedCodes: List of [Text];
        Failures: List of [Text];
        Succeeded: Boolean;
        ActualError: Text;
    begin
        // [SCENARIO] a broken configuration is not a scan problem — it must escape the batch
        // [GIVEN] no setup record and a batch mixing a plausible code with a broken one
        RemoveSetup();
        ScannedCodes.Add(DigitCode(Any, 8));
        ScannedCodes.Add(DigitCode(Any, 3));

        // [WHEN] validating the batch inside a try call of our own
        Succeeded := TryValidateBatch(ScannedCodes, Failures);
        ActualError := GetLastErrorText();

        // [THEN] the missing-setup error reached us, with its message intact
        Assert.IsFalse(Succeeded,
            StrSubstNo('Expected the missing-setup error to travel out of ValidateBatch to the caller — it returned normally with %1 collected failure(s) instead', Failures.Count()));
        Assert.AreEqual(0, Failures.Count(),
            'Expected the configuration error to reach the caller without being filed as a per-code failure — Failures must be cleared and left empty');
        Assert.AreEqual('Package Scan Setup is missing.', ActualError,
            'Expected the caller to see exactly the missing-setup message that ResolveCodeLength raises');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchLetsTheConfigurationErrorReachTheCallerOnAnEmptyBatch()
    var
        Assert: Codeunit Assert;
        ScannedCodes: List of [Text];
        Failures: List of [Text];
        Succeeded: Boolean;
        ActualError: Text;
    begin
        // [SCENARIO] the configuration is checked even when there is nothing to scan
        // [GIVEN] no setup record and no scanned codes at all
        RemoveSetup();

        // [WHEN] validating the empty batch inside a try call of our own
        Succeeded := TryValidateBatch(ScannedCodes, Failures);
        ActualError := GetLastErrorText();

        // [THEN] the configuration error reached us anyway, with its message intact
        Assert.IsFalse(Succeeded,
            'Expected an empty batch on a missing setup to raise the configuration error too — the configuration is not something only a scanned code can trip over');
        Assert.AreEqual(0, Failures.Count(),
            'Expected the configuration error to reach the caller without being filed as a per-code failure — Failures must be cleared and left empty');
        Assert.AreEqual('Package Scan Setup is missing.', ActualError,
            'Expected the caller to see exactly the missing-setup message that ResolveCodeLength raises');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchLetsTheNonPositiveLengthErrorReachTheCaller()
    var
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ScannedCodes: List of [Text];
        Failures: List of [Text];
        Succeeded: Boolean;
        ActualError: Text;
    begin
        // [SCENARIO] an unusable Code Length escapes even when every code looks fine
        // [GIVEN] a setup record whose Code Length is 0 and a batch of plausible codes
        SetCodeLength(0);
        ScannedCodes.Add(DigitCode(Any, 8));
        ScannedCodes.Add(DigitCode(Any, 8));

        // [WHEN] validating the batch inside a try call of our own
        Succeeded := TryValidateBatch(ScannedCodes, Failures);
        ActualError := GetLastErrorText();

        // [THEN] the configuration error reached us, with its message intact
        Assert.IsFalse(Succeeded,
            StrSubstNo('Expected the non-positive Code Length error to travel out of ValidateBatch to the caller — it returned normally with %1 collected failure(s) instead', Failures.Count()));
        Assert.AreEqual(0, Failures.Count(),
            'Expected the configuration error to reach the caller without being filed as a per-code failure — Failures must be cleared and left empty');
        Assert.AreEqual('Code Length must be greater than zero in Package Scan Setup.', ActualError,
            'Expected the caller to see exactly the non-positive-length message that ResolveCodeLength raises');
    end;

    // Wrapping the call here rather than using asserterror keeps a rich failure
    // message for the case this test exists to catch: ValidateBatch returning
    // normally because it swallowed the configuration error.
    [TryFunction]
    local procedure TryValidateBatch(ScannedCodes: List of [Text]; var Failures: List of [Text])
    var
        PackageScanValidator: Codeunit "Package Scan Validator";
    begin
        PackageScanValidator.ValidateBatch(ScannedCodes, Failures);
    end;

    local procedure DigitCode(var AnyGenerator: Codeunit Any; CodeLength: Integer): Text
    var
        ScannedCode: Text;
        Position: Integer;
    begin
        for Position := 1 to CodeLength do
            ScannedCode += Format(AnyGenerator.IntegerInRange(0, 9));
        exit(ScannedCode);
    end;

    local procedure SetCodeLength(CodeLength: Integer)
    var
        PackageScanSetup: Record "Package Scan Setup";
    begin
        PackageScanSetup.DeleteAll();
        PackageScanSetup.Init();
        PackageScanSetup."Primary Key" := '';
        PackageScanSetup."Code Length" := CodeLength;
        PackageScanSetup.Insert();
    end;

    local procedure RemoveSetup()
    var
        PackageScanSetup: Record "Package Scan Setup";
    begin
        PackageScanSetup.DeleteAll();
    end;
}
