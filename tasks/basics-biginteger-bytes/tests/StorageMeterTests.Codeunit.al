codeunit 50900 "Storage Meter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        StorageMeter: Codeunit "Storage Meter";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalBytesSumsThreeFilesPastTwoGigabytes()
    var
        Sizes: List of [Decimal];
    begin
        // [SCENARIO] Three 1.5 GB files total 4.5 GB, more than twice the Integer ceiling
        // [GIVEN] three sizes of 1,610,612,736 bytes
        Sizes.Add(GiB(1.5));
        Sizes.Add(GiB(1.5));
        Sizes.Add(GiB(1.5));

        // [WHEN] totalling them
        // [THEN] the exact byte count comes back
        AssertBytes(4831838208L, TotalBytesOf(Sizes, 'three 1.5 GB files'),
            'Expected three 1.5 GB files (1,610,612,736 bytes each) to total exactly 4,831,838,208 bytes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalBytesPassesThroughASingleFileOverTwoGigabytes()
    var
        Sizes: List of [Decimal];
    begin
        // [SCENARIO] A single 3 GB file is on its own already past what an Integer can hold
        // [GIVEN] one size of 3,221,225,472 bytes
        Sizes.Add(GiB(3));

        // [WHEN] totalling it
        // [THEN] the size comes back unchanged
        AssertBytes(3221225472L, TotalBytesOf(Sizes, 'a single 3 GB file'),
            'Expected a single 3 GB file to total exactly 3,221,225,472 bytes — one size alone can exceed the Integer ceiling');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalBytesCountsTheFirstBytePastTheIntegerLimit()
    var
        Sizes: List of [Decimal];
    begin
        // [SCENARIO] 2,147,483,647 + 1 is the first total an Integer cannot hold
        // [GIVEN] the largest Integer and one more byte
        Sizes.Add(2147483647);
        Sizes.Add(1);

        // [WHEN] totalling them
        // [THEN] the total is 2,147,483,648
        AssertBytes(2147483648L, TotalBytesOf(Sizes, '2,147,483,647 bytes plus 1 byte'),
            'Expected 2,147,483,647 + 1 to total 2,147,483,648 bytes — the first byte past the Integer ceiling must be counted, not refused');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalBytesIsZeroForAnEmptyList()
    var
        Sizes: List of [Decimal];
    begin
        // [SCENARIO] No attachments means no storage used
        // [WHEN] totalling an empty list
        // [THEN] the total is 0
        AssertBytes(0, TotalBytesOf(Sizes, 'an empty list'),
            'Expected an empty list of sizes to total 0 bytes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalBytesSumsGeneratedSmallFilesExactly()
    var
        Any: Codeunit Any;
        Sizes: List of [Decimal];
        Size: Integer;
        ExpectedBytes: Integer;
        FileCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] A handful of generated small sizes totals exactly their sum
        // [GIVEN] two to six sizes of up to 10,000,000 bytes
        FileCount := Any.IntegerInRange(2, 6);
        for i := 1 to FileCount do begin
            Size := Any.IntegerInRange(1, 10000000);
            Sizes.Add(Size);
            ExpectedBytes += Size;
        end;

        // [WHEN] totalling them
        // [THEN] the total is their exact sum
        AssertBytes(ExpectedBytes, TotalBytesOf(Sizes, StrSubstNo('%1 generated small files', FileCount)),
            StrSubstNo('Expected the %1 generated sizes to total exactly %2 bytes — every byte counts', FileCount, ExpectedBytes));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TotalBytesSumsGeneratedLargeFilesPastTwoGigabytes()
    var
        Any: Codeunit Any;
        Sizes: List of [Decimal];
        SizeMB: Integer;
        TotalMB: Integer;
        ExpectedBytes: BigInteger;
        FileCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] Four to eight files of 600 MB to 1.9 GB always total more than 2 GB
        // [GIVEN] generated sizes, each below the Integer ceiling on its own
        FileCount := Any.IntegerInRange(4, 8);
        for i := 1 to FileCount do begin
            SizeMB := Any.IntegerInRange(600, 1900);
            Sizes.Add(MiB(SizeMB));
            TotalMB += SizeMB;
        end;
        ExpectedBytes := TotalMB;
        ExpectedBytes := ExpectedBytes * 1048576;

        // [WHEN] totalling them
        // [THEN] the total is their exact sum, well past 2 GB
        AssertBytes(ExpectedBytes, TotalBytesOf(Sizes, StrSubstNo('%1 generated files totalling %2 MB', FileCount, TotalMB)),
            StrSubstNo('Expected %1 generated files totalling %2 MB to come back as exactly %3 bytes', FileCount, TotalMB, ExpectedBytes));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotaBytesForOneGigabyte()
    begin
        // [SCENARIO] 1 GB is 1024 x 1024 x 1024 bytes
        // [WHEN] converting a 1 GB quota
        // [THEN] 1,073,741,824 bytes
        AssertBytes(1073741824L, QuotaBytesOf(1),
            'Expected a 1 GB quota to be 1,073,741,824 bytes — a gigabyte is 1024 × 1024 × 1024 bytes, not 1,000,000,000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotaBytesForTwoGigabytesPassesTheIntegerLimit()
    begin
        // [SCENARIO] 2 GB is 2,147,483,648 bytes, one past what an Integer holds
        // [WHEN] converting a 2 GB quota
        // [THEN] 2,147,483,648 bytes
        AssertBytes(2147483648L, QuotaBytesOf(2),
            'Expected a 2 GB quota to be 2,147,483,648 bytes — the product must be computed in 64 bits, not as an Integer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotaBytesForZeroGigabytesIsZero()
    begin
        // [SCENARIO] No quota is no bytes
        // [WHEN] converting a 0 GB quota
        // [THEN] 0 bytes
        AssertBytes(0, QuotaBytesOf(0), 'Expected a 0 GB quota to be 0 bytes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotaBytesForGeneratedQuota()
    var
        Any: Codeunit Any;
        Gigabytes: Integer;
        ExpectedBytes: BigInteger;
    begin
        // [SCENARIO] Any quota in whole gigabytes converts to exactly that many times 1,073,741,824
        // [GIVEN] a generated quota of 3 to 1,000 GB
        Gigabytes := Any.IntegerInRange(3, 1000);
        ExpectedBytes := Gigabytes;
        ExpectedBytes := ExpectedBytes * 1073741824;

        // [WHEN] converting it
        // [THEN] the exact product comes back
        AssertBytes(ExpectedBytes, QuotaBytesOf(Gigabytes),
            StrSubstNo('Expected a %1 GB quota to be exactly %1 × 1,073,741,824 = %2 bytes', Gigabytes, ExpectedBytes));
    end;

    // A call that dies with an overflow is reported in the task's vocabulary plus
    // the runtime error text, instead of the bare error surfacing as the failure.
    local procedure TotalBytesOf(Sizes: List of [Decimal]; Context: Text): BigInteger
    var
        Bytes: BigInteger;
    begin
        if not TryTotalBytes(Sizes, Bytes) then
            Assert.Fail(StrSubstNo('Expected TotalBytes to return the total of %1, but the call raised an error: %2', Context, GetLastErrorText()));
        exit(Bytes);
    end;

    local procedure QuotaBytesOf(Gigabytes: Integer): BigInteger
    var
        Bytes: BigInteger;
    begin
        if not TryQuotaBytes(Gigabytes, Bytes) then
            Assert.Fail(StrSubstNo('Expected QuotaBytes to return the byte count of a %1 GB quota, but the call raised an error: %2', Gigabytes, GetLastErrorText()));
        exit(Bytes);
    end;

    [TryFunction]
    local procedure TryTotalBytes(Sizes: List of [Decimal]; var Bytes: BigInteger)
    begin
        Bytes := StorageMeter.TotalBytes(Sizes);
    end;

    [TryFunction]
    local procedure TryQuotaBytes(Gigabytes: Integer; var Bytes: BigInteger)
    begin
        Bytes := StorageMeter.QuotaBytes(Gigabytes);
    end;

    // Typed parameters keep both sides of the comparison BigInteger, so an Integer
    // literal expectation is never compared against a BigInteger result as mixed types.
    local procedure AssertBytes(ExpectedBytes: BigInteger; ActualBytes: BigInteger; Msg: Text)
    begin
        Assert.AreEqual(ExpectedBytes, ActualBytes, Msg);
    end;

    local procedure GiB(Count: Decimal): Decimal
    begin
        exit(Count * 1073741824);
    end;

    local procedure MiB(Count: Integer): Decimal
    var
        Bytes: Decimal;
    begin
        Bytes := Count;
        exit(Bytes * 1048576);
    end;
}
