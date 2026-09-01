codeunit 50900 "Counter Allocator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstValueOnAFreshCounterIsOne()
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Value: Integer;
    begin
        // [SCENARIO] The very first NextValue on a counter without a row returns 1 and creates the row
        Value := CounterAllocator.NextValue('TRYAL-C01');

        Assert.AreEqual(1, Value,
            'Expected the very first value of a brand-new counter to be 1');
        Assert.IsTrue(NumberCounter.Get('TRYAL-C01'),
            'Expected the first call to create the counter row so later calls can continue the sequence');
        Assert.AreEqual(1, NumberCounter."Last Used No.",
            'Expected the new counter row to record 1 as the last used number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextValueContinuesAfterTheSeededValue()
    var
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Seed: Integer;
    begin
        // [SCENARIO] NextValue on an existing counter returns Last Used No. + 1
        Seed := Any.IntegerInRange(100, 5000);
        SeedCounter('TRYAL-C02', Seed);

        Assert.AreEqual(Seed + 1, CounterAllocator.NextValue('TRYAL-C02'),
            'Expected NextValue to return the seeded "Last Used No." plus one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ThreeCallsReturnThreeConsecutiveValues()
    var
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Seed: Integer;
    begin
        // [SCENARIO] Repeated NextValue calls return a gap-free, repeat-free sequence
        Seed := Any.IntegerInRange(100, 5000);
        SeedCounter('TRYAL-C03', Seed);

        Assert.AreEqual(Seed + 1, CounterAllocator.NextValue('TRYAL-C03'),
            'Expected the first call to return the seeded value plus one');
        Assert.AreEqual(Seed + 2, CounterAllocator.NextValue('TRYAL-C03'),
            'Expected the second call to return the next consecutive number — no repeats');
        Assert.AreEqual(Seed + 3, CounterAllocator.NextValue('TRYAL-C03'),
            'Expected the third call to return the next consecutive number — no gaps');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheReturnedValueIsSavedOnTheCounter()
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Value: Integer;
    begin
        // [SCENARIO] After NextValue the row's Last Used No. equals the returned number
        SeedCounter('TRYAL-C04', Any.IntegerInRange(100, 5000));

        Value := CounterAllocator.NextValue('TRYAL-C04');

        NumberCounter.Get('TRYAL-C04');
        Assert.AreEqual(Value, NumberCounter."Last Used No.",
            'Expected the returned number to be saved back to "Last Used No." — an unsaved counter repeats itself on the next call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextValueSeesAnUpdateMadeBetweenCalls()
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstValue: Integer;
    begin
        // [SCENARIO] The allocator reads the row fresh on every call instead of trusting remembered state
        SeedCounter('TRYAL-C05', Any.IntegerInRange(100, 5000));
        FirstValue := CounterAllocator.NextValue('TRYAL-C05');
        // [GIVEN] the counter row is moved forward directly, as a concurrent writer would
        NumberCounter.Get('TRYAL-C05');
        NumberCounter."Last Used No." := FirstValue + 25;
        NumberCounter.Modify();

        // [WHEN] the allocator is asked again
        // [THEN] it continues from the updated row, not from anything it remembered
        Assert.AreEqual(FirstValue + 26, CounterAllocator.NextValue('TRYAL-C05'),
            'Expected the second call to continue from the row''s updated "Last Used No." — the allocator must re-read the counter on every call, never reuse a value it read earlier');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextValueFetchesTheCounterRowFromSqlNotFromTheCache()
    begin
        // [SCENARIO] With the counter row warm in the server data cache, NextValue still reads it from SQL
        VerifyTheWarmCounterRowIsFetchedFromSql('TRYAL-C13', false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReserveBlockFetchesTheCounterRowFromSqlNotFromTheCache()
    begin
        // [SCENARIO] With the counter row warm in the server data cache, ReserveBlock still reads it from SQL
        VerifyTheWarmCounterRowIsFetchedFromSql('TRYAL-C14', true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountersAdvanceIndependently()
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SeedA: Integer;
        SeedB: Integer;
    begin
        // [SCENARIO] Interleaved calls on two counters never bleed into each other
        SeedA := Any.IntegerInRange(100, 2000);
        SeedB := SeedA + Any.IntegerInRange(500, 1000);
        SeedCounter('TRYAL-C06A', SeedA);
        SeedCounter('TRYAL-C06B', SeedB);

        Assert.AreEqual(SeedA + 1, CounterAllocator.NextValue('TRYAL-C06A'),
            'Expected counter A to continue from its own seeded value');
        Assert.AreEqual(SeedB + 1, CounterAllocator.NextValue('TRYAL-C06B'),
            'Expected counter B to continue from its own seeded value, untouched by counter A');
        Assert.AreEqual(SeedA + 2, CounterAllocator.NextValue('TRYAL-C06A'),
            'Expected counter A to continue its own sequence after counter B was used in between');
        NumberCounter.Get('TRYAL-C06B');
        Assert.AreEqual(SeedB + 1, NumberCounter."Last Used No.",
            'Expected counter B''s row to be unaffected by allocations on counter A');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReserveBlockReturnsTheFirstValueAndAdvancesByTheSize()
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Seed: Integer;
        BlockSize: Integer;
    begin
        // [SCENARIO] A block reservation returns its first number and moves the row to its last number
        Seed := Any.IntegerInRange(100, 5000);
        BlockSize := Any.IntegerInRange(2, 20);
        SeedCounter('TRYAL-C07', Seed);

        Assert.AreEqual(Seed + 1, CounterAllocator.ReserveBlock('TRYAL-C07', BlockSize),
            'Expected ReserveBlock to return the first number of the reserved block');
        NumberCounter.Get('TRYAL-C07');
        Assert.AreEqual(Seed + BlockSize, NumberCounter."Last Used No.",
            'Expected "Last Used No." to land on the block''s last number — the counter advances by exactly the block size');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextValueAfterAReservedBlockSkipsTheWholeBlock()
    var
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Seed: Integer;
        BlockSize: Integer;
    begin
        // [SCENARIO] The first allocation after a block starts one past the block's last number
        Seed := Any.IntegerInRange(100, 5000);
        BlockSize := Any.IntegerInRange(2, 20);
        SeedCounter('TRYAL-C08', Seed);
        CounterAllocator.ReserveBlock('TRYAL-C08', BlockSize);

        Assert.AreEqual(Seed + BlockSize + 1, CounterAllocator.NextValue('TRYAL-C08'),
            'Expected the first value after a reserved block to skip the whole block — every number in the block belongs to the caller that reserved it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReserveBlockOnAFreshCounterStartsAtOne()
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        BlockSize: Integer;
    begin
        // [SCENARIO] A block on a counter without a row starts at 1 and creates the row
        BlockSize := Any.IntegerInRange(3, 15);

        Assert.AreEqual(1, CounterAllocator.ReserveBlock('TRYAL-C09', BlockSize),
            'Expected a block on a brand-new counter to start at 1');
        Assert.IsTrue(NumberCounter.Get('TRYAL-C09'),
            'Expected the reservation to create the counter row');
        Assert.AreEqual(BlockSize, NumberCounter."Last Used No.",
            'Expected the new row''s "Last Used No." to be the block''s last number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReserveBlockOfOneAllocatesExactlyOneValue()
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Seed: Integer;
    begin
        // [SCENARIO] A block of size 1 behaves exactly like NextValue
        Seed := Any.IntegerInRange(100, 5000);
        SeedCounter('TRYAL-C10', Seed);

        Assert.AreEqual(Seed + 1, CounterAllocator.ReserveBlock('TRYAL-C10', 1),
            'Expected a block of size 1 to return the seeded value plus one, exactly like NextValue');
        NumberCounter.Get('TRYAL-C10');
        Assert.AreEqual(Seed + 1, NumberCounter."Last Used No.",
            'Expected a block of size 1 to advance the counter by exactly one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ZeroBlockSizeIsRejectedAndAllocatesNothing()
    begin
        // [SCENARIO] A zero block size fails with the must-be-positive error and leaves the counter alone
        VerifyInvalidBlockSizeFails('TRYAL-C11', 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure NegativeBlockSizeIsRejectedAndAllocatesNothing()
    var
        Any: Codeunit Any;
    begin
        // [SCENARIO] A negative block size fails with the must-be-positive error and leaves the counter alone
        VerifyInvalidBlockSizeFails('TRYAL-C12', -Any.IntegerInRange(1, 50));
    end;

    local procedure VerifyInvalidBlockSizeFails(CounterCode: Code[20]; BlockSize: Integer)
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Seed: Integer;
    begin
        Seed := Any.IntegerInRange(100, 5000);
        SeedCounter(CounterCode, Seed);
        // The refused call rolls the database back to the last commit; without
        // this the seeded row would vanish together with the rejected block.
        Commit();

        asserterror CounterAllocator.ReserveBlock(CounterCode, BlockSize);

        AssertErrorContains('must be positive');
        NumberCounter.Get(CounterCode);
        Assert.AreEqual(Seed, NumberCounter."Last Used No.",
            'Expected a rejected reservation to leave "Last Used No." untouched — a failing call must not burn numbers');
    end;

    local procedure VerifyTheWarmCounterRowIsFetchedFromSql(CounterCode: Code[20]; UseReserveBlock: Boolean)
    var
        NumberCounter: Record "Number Counter";
        CounterAllocator: Codeunit "Counter Allocator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Seed: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
        Value: Integer;
        CallName: Text;
    begin
        Seed := Any.IntegerInRange(100, 5000);
        SeedCounter(CounterCode, Seed);
        // Warm-up: the first allocator call pays one-time metadata statements,
        // and its write empties the data cache for the table again.
        CounterAllocator.NextValue(CounterCode);
        // An ordinary read here puts the row back into the server data cache,
        // so inside the measured call a cache-served read costs zero SQL rows
        // — only a read that bypasses the cache still fetches from SQL.
        NumberCounter.Get(CounterCode);

        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        if UseReserveBlock then
            Value := CounterAllocator.ReserveBlock(CounterCode, 1)
        else
            Value := CounterAllocator.NextValue(CounterCode);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        if UseReserveBlock then
            CallName := 'ReserveBlock'
        else
            CallName := 'NextValue';
        if DebugBudgets() then
            Assert.Fail(StrSubstNo('DEBUG %1: the measured call executed %2 SQL statements and read %3 rows', CallName, StatementsUsed, RowsUsed));

        Assert.AreEqual(Seed + 2, Value,
            StrSubstNo('Expected the measured %1 call to return the next consecutive number before its read style is judged', CallName));
        Assert.IsTrue(RowsUsed >= MinRowsFetchedFromSql(),
            StrSubstNo('Expected %1 to fetch the counter row''s current state from SQL even though the row was already sitting in the server data cache, but the call read %2 rows from SQL — a cache-served read is exactly the stale read that lets two sessions see the same "Last Used No." and hand out the same number', CallName, RowsUsed));
    end;

    local procedure MinRowsFetchedFromSql(): Integer
    begin
        exit(1);
    end;

    local procedure DebugBudgets(): Boolean
    begin
        // Flip to true to fail the cache-probe tests with the raw SQL counters —
        // the only output channel for calibrating MinRowsFetchedFromSql on the platform.
        exit(false);
    end;

    local procedure SeedCounter(CounterCode: Code[20]; LastUsedNo: Integer)
    var
        NumberCounter: Record "Number Counter";
    begin
        NumberCounter.Init();
        NumberCounter."Counter Code" := CounterCode;
        NumberCounter."Last Used No." := LastUsedNo;
        NumberCounter.Insert();
    end;

    local procedure AssertErrorContains(Fragment: Text)
    var
        Assert: Codeunit Assert;
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains(LowerCase(Fragment)),
            StrSubstNo('Expected the allocator error to contain "%1", got: %2', Fragment, ActualError));
    end;
}
