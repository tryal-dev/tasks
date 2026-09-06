codeunit 50900 "Version Compare Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeExpandsTwoPartsToFour()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('2.0.0.0', VersionCompare.Normalize('2.0'),
            'Expected Normalize to expand 2.0 to four parts, writing 0 for the Build and Revision the input did not supply');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeExpandsThreePartsToFour()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
        Expected: Text;
    begin
        Input := StrSubstNo('%1.%2.%3', Any.IntegerInRange(1, 99), Any.IntegerInRange(0, 99), Format(Any.IntegerInRange(0, 99999), 0, 9));
        Expected := Input + '.0';

        Assert.AreEqual(Expected, VersionCompare.Normalize(Input),
            StrSubstNo('Expected Normalize to expand the three-part version %1 to four parts, writing 0 for the missing Revision', Input));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeKeepsAFourPartVersion()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
    begin
        Input := StrSubstNo('%1.%2.%3.%4', Any.IntegerInRange(1, 99), Any.IntegerInRange(0, 99), Format(Any.IntegerInRange(1000, 99999), 0, 9), Format(Any.IntegerInRange(0, 99999), 0, 9));

        Assert.AreEqual(Input, VersionCompare.Normalize(Input),
            StrSubstNo('Expected Normalize to return the four-part version %1 unchanged', Input));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeReadsPartsAsNumbers()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('1.9.0.0', VersionCompare.Normalize('1.09.0'),
            'Expected Normalize to treat each part as a number — the minor part 09 is 9, so 1.09.0 normalizes to 1.9.0.0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeStripsSurroundingWhitespace()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
        Tab: Char;
    begin
        Tab := 9;

        Assert.AreEqual('1.10.0.0', VersionCompare.Normalize('  1.10.0 ' + Format(Tab)),
            'Expected Normalize to ignore the spaces and the tab around 1.10.0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeStripsALeadingV()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('1.10.0.0', VersionCompare.Normalize('v1.10.0'),
            'Expected Normalize to drop the leading lowercase v from v1.10.0');
        Assert.AreEqual('2.5.0.0', VersionCompare.Normalize('V2.5'),
            'Expected Normalize to drop the leading uppercase V from V2.5');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeReturnsEmptyForMalformedInput()
    var
        Assert: Codeunit Assert;
        Malformed: List of [Text];
        Input: Text;
        Result: Text;
    begin
        Malformed.Add('1.9.5-beta');
        Malformed.Add('abc');
        Malformed.Add('1.2.3.4.5');
        Malformed.Add('');

        foreach Input in Malformed do begin
            if not TryNormalize(Input, Result) then
                Assert.Fail(StrSubstNo('Expected Normalize to return an empty text for the malformed input "%1", but it raised an error: %2', Input, GetLastErrorText()));
            Assert.AreEqual('', Result,
                StrSubstNo('Expected Normalize to return an empty text for the malformed input "%1"', Input));
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastRanksMinorTenAboveMinorNine()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(VersionCompare.IsAtLeast('1.10.0', '1.9.5'),
            'Expected 1.10.0 to be at least 1.9.5 — minor 10 is newer than minor 9, even though the text "1.10.0" sorts before "1.9.5" character by character');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastRanksMinorNineBelowMinorTen()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(VersionCompare.IsAtLeast('1.9.5', '1.10.0'),
            'Expected 1.9.5 NOT to be at least 1.10.0 — minor 9 is older than minor 10');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastTreatsAbsentPartsAsZero()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(VersionCompare.IsAtLeast('2.0', '2.0.0'),
            'Expected 2.0 to be at least 2.0.0 — they are the same version, so the absent Build must count as 0 rather than as "less than 0"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastIsTrueForTheSameVersion()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
    begin
        Input := StrSubstNo('%1.%2.%3.%4', Any.IntegerInRange(1, 99), Any.IntegerInRange(0, 99), Format(Any.IntegerInRange(0, 99999), 0, 9), Format(Any.IntegerInRange(0, 99999), 0, 9));

        Assert.IsTrue(VersionCompare.IsAtLeast(Input, Input),
            StrSubstNo('Expected %1 to be at least %1 — a version meets a minimum equal to itself', Input));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastIsFalseOneRevisionBelow()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Prefix: Text;
        Revision: Integer;
        Actual: Text;
        Minimum: Text;
    begin
        Prefix := StrSubstNo('%1.%2.%3', Any.IntegerInRange(1, 99), Any.IntegerInRange(0, 99), Format(Any.IntegerInRange(0, 99999), 0, 9));
        Revision := Any.IntegerInRange(0, 99998);
        Actual := StrSubstNo('%1.%2', Prefix, Format(Revision, 0, 9));
        Minimum := StrSubstNo('%1.%2', Prefix, Format(Revision + 1, 0, 9));

        Assert.IsFalse(VersionCompare.IsAtLeast(Actual, Minimum),
            StrSubstNo('Expected %1 NOT to be at least %2 — the revision is one below the minimum, and the fourth part counts too', Actual, Minimum));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastIsTrueOneRevisionAbove()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Prefix: Text;
        Revision: Integer;
        Actual: Text;
        Minimum: Text;
    begin
        Prefix := StrSubstNo('%1.%2.%3', Any.IntegerInRange(1, 99), Any.IntegerInRange(0, 99), Format(Any.IntegerInRange(0, 99999), 0, 9));
        Revision := Any.IntegerInRange(0, 99998);
        Actual := StrSubstNo('%1.%2', Prefix, Format(Revision + 1, 0, 9));
        Minimum := StrSubstNo('%1.%2', Prefix, Format(Revision, 0, 9));

        Assert.IsTrue(VersionCompare.IsAtLeast(Actual, Minimum),
            StrSubstNo('Expected %1 to be at least %2 — the revision is one above the minimum', Actual, Minimum));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastIsFalseOneBuildBelow()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Prefix: Text;
        Build: Integer;
        Actual: Text;
        Minimum: Text;
    begin
        Prefix := StrSubstNo('%1.%2', Any.IntegerInRange(1, 99), Any.IntegerInRange(0, 99));
        Build := Any.IntegerInRange(0, 99998);
        Actual := StrSubstNo('%1.%2.%3', Prefix, Format(Build, 0, 9), Format(Any.IntegerInRange(1, 99999), 0, 9));
        Minimum := StrSubstNo('%1.%2.0', Prefix, Format(Build + 1, 0, 9));

        Assert.IsFalse(VersionCompare.IsAtLeast(Actual, Minimum),
            StrSubstNo('Expected %1 NOT to be at least %2 — the build is one below the minimum, and the build is compared before the revision, so a larger revision cannot make up for it', Actual, Minimum));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastLetsAHigherMajorWin()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(VersionCompare.IsAtLeast('2.0.0', '1.99.99.99'),
            'Expected 2.0.0 to be at least 1.99.99.99 — the major part is compared first, and 2 beats 1 no matter how large the later parts are');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastCleansUpBothArguments()
    var
        VersionCompare: Codeunit "Version Compare";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(VersionCompare.IsAtLeast(' v1.10.0 ', 'V1.10'),
            'Expected " v1.10.0 " to be at least "V1.10" — after dropping the surrounding whitespace and the leading v/V from both, they are the same version');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastReturnsFalseForMalformedActual()
    var
        Assert: Codeunit Assert;
        Result: Boolean;
    begin
        if not TryIsAtLeast('1.9.5-beta', '1.9.0', Result) then
            Assert.Fail(StrSubstNo('Expected IsAtLeast to return false for the malformed actual version "1.9.5-beta", but it raised an error: %1', GetLastErrorText()));

        Assert.IsFalse(Result,
            'Expected IsAtLeast to return false when the actual version "1.9.5-beta" cannot be read as a version');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAtLeastReturnsFalseForMalformedMinimum()
    var
        Assert: Codeunit Assert;
        Result: Boolean;
    begin
        if not TryIsAtLeast('2.0.0', 'latest', Result) then
            Assert.Fail(StrSubstNo('Expected IsAtLeast to return false for the malformed minimum version "latest", but it raised an error: %1', GetLastErrorText()));

        Assert.IsFalse(Result,
            'Expected IsAtLeast to return false when the minimum version "latest" cannot be read as a version');
    end;

    // The contract promises "false, never an error" for malformed input; catching a
    // raised error here turns it into a failure message the user can read instead of
    // a raw runtime error.
    [TryFunction]
    local procedure TryNormalize(Input: Text; var Result: Text)
    var
        VersionCompare: Codeunit "Version Compare";
    begin
        Result := VersionCompare.Normalize(Input);
    end;

    [TryFunction]
    local procedure TryIsAtLeast(Actual: Text; Minimum: Text; var Result: Boolean)
    var
        VersionCompare: Codeunit "Version Compare";
    begin
        Result := VersionCompare.IsAtLeast(Actual, Minimum);
    end;
}
