codeunit 50900 "Dimension Set Totals Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SumsEveryEntryCarryingTheValue()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        AloneSetID: Integer;
        CombinedSetID: Integer;
    begin
        // [SCENARIO] Every entry whose dimension set carries the value is added, across every set that contains it
        // [GIVEN] one value living in two different dimension sets — alone, and combined with another dimension
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimWithDimValue(OtherValue);
        AloneSetID := LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code);
        CombinedSetID := LibraryDimension.CreateDimSet(AloneSetID, OtherValue."Dimension Code", OtherValue.Code);
        Amount1 := Any.DecimalInRange(100, 900, 2);
        Amount2 := Any.DecimalInRange(100, 900, 2);
        Amount3 := Any.DecimalInRange(100, 900, 2);
        MockGLEntry(AccountNo, Amount1, AloneSetID);
        MockGLEntry(AccountNo, Amount2, AloneSetID);
        MockGLEntry(AccountNo, Amount3, CombinedSetID);

        // [WHEN] breaking the account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] the value's net change is the sum over both sets
        Assert.AreEqual(Amount1 + Amount2 + Amount3, GetTotal(Totals, DimensionValue.Code),
            'Expected the value''s net change to add up every entry whose dimension set carries it — the value lives in two different sets here, and both count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsEachValuesNetChangeSeparate()
    var
        Dimension: Record Dimension;
        ValueA: Record "Dimension Value";
        ValueB: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        AmountA: Decimal;
        AmountB: Decimal;
    begin
        // [SCENARIO] Two values of the dimension get two separate numbers
        // [GIVEN] value A on a set of its own and value B on a set shared with another dimension
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(ValueA, Dimension.Code);
        LibraryDimension.CreateDimensionValue(ValueB, Dimension.Code);
        LibraryDimension.CreateDimWithDimValue(OtherValue);
        AmountA := Any.DecimalInRange(100, 900, 2);
        AmountB := Any.DecimalInRange(1000, 9000, 2);
        MockGLEntry(AccountNo, AmountA, LibraryDimension.CreateDimSet(0, Dimension.Code, ValueA.Code));
        MockGLEntry(AccountNo, AmountB, LibraryDimension.CreateDimSet(
            LibraryDimension.CreateDimSet(0, Dimension.Code, ValueB.Code), OtherValue."Dimension Code", OtherValue.Code));

        // [WHEN] breaking the account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] each value carries only its own entries
        Assert.AreEqual(AmountA, GetTotal(Totals, ValueA.Code),
            'Expected value A''s net change to be built only from entries whose set carries value A');
        Assert.AreEqual(AmountB, GetTotal(Totals, ValueB.Code),
            'Expected value B''s net change to be built only from entries whose set carries value B');
        Assert.AreEqual(2, Totals.Count(),
            'Expected exactly two keys — one per dimension value that has entries on the account');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreditsReduceTheNetChange()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        SetID: Integer;
    begin
        // [SCENARIO] A negative entry lowers the value's net change instead of being skipped
        // [GIVEN] a debit and a smaller credit on the same value
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        SetID := LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code);
        DebitAmount := Any.DecimalInRange(500, 900, 2);
        CreditAmount := Any.DecimalInRange(100, 400, 2);
        MockGLEntry(AccountNo, DebitAmount, SetID);
        MockGLEntry(AccountNo, -CreditAmount, SetID);

        // [WHEN] breaking the account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] the credit is subtracted
        Assert.AreEqual(DebitAmount - CreditAmount, GetTotal(Totals, DimensionValue.Code),
            'Expected the negative entry (a credit) to reduce the value''s net change, not to be skipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesNettingToZeroStillAppear()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        Amount: Decimal;
        SetID: Integer;
    begin
        // [SCENARIO] A value whose entries cancel out keeps its key, with 0
        // [GIVEN] a debit and an equal credit on the same value
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        SetID := LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code);
        Amount := Any.DecimalInRange(100, 900, 2);
        MockGLEntry(AccountNo, Amount, SetID);
        MockGLEntry(AccountNo, -Amount, SetID);

        // [WHEN] breaking the account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] the value is present with a net change of exactly 0
        Assert.IsTrue(Totals.ContainsKey(DimensionValue.Code),
            'Expected the value to keep its key even though its entries net to exactly 0 — a key appears when at least one entry carries the value, whatever the sum');
        Assert.AreEqual(0.0, Totals.Get(DimensionValue.Code),
            'Expected a net change of exactly 0 for entries that cancel out');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesOnOtherAccountsStayOut()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        OtherAccountNo: Code[20];
        Amount: Decimal;
        SetID: Integer;
    begin
        // [SCENARIO] The very same dimension set on another account does not leak into this account's number
        // [GIVEN] one entry on the graded account and one on another account, both pointing at the same set
        AccountNo := LibraryERM.CreateGLAccountNo();
        OtherAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        SetID := LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code);
        Amount := Any.DecimalInRange(100, 900, 2);
        MockGLEntry(AccountNo, Amount, SetID);
        MockGLEntry(OtherAccountNo, Any.DecimalInRange(1000, 9000, 2), SetID);

        // [WHEN] breaking the graded account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] only the graded account's entry is counted
        Assert.AreEqual(Amount, GetTotal(Totals, DimensionValue.Code),
            'Expected the value''s net change to be built only from entries on the requested G/L account — the same dimension set on another account must not attract its amount');
        Assert.AreEqual(1, Totals.Count(),
            'Expected exactly one key: the other account''s entry adds nothing, not even a value of its own');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesWithoutTheDimensionStayOut()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Entries whose set holds no value for the dimension are skipped, never filed under a blank key
        // [GIVEN] one entry carrying the value, one with no dimensions at all, and one whose set holds only another dimension
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimWithDimValue(OtherValue);
        Amount := Any.DecimalInRange(100, 900, 2);
        MockGLEntry(AccountNo, Amount, LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code));
        MockGLEntry(AccountNo, Any.DecimalInRange(100, 900, 2), 0);
        MockGLEntry(AccountNo, Any.DecimalInRange(100, 900, 2), LibraryDimension.CreateDimSet(0, OtherValue."Dimension Code", OtherValue.Code));

        // [WHEN] breaking the account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] only the entry carrying the value produces a key
        Assert.IsFalse(Totals.ContainsKey(''),
            'Expected no blank key: an entry whose dimension set holds no value for the dimension is skipped, not filed under an empty value code');
        Assert.AreEqual(1, Totals.Count(),
            'Expected exactly one key — the entry with "Dimension Set ID" 0 and the entry whose set holds only another dimension carry no value for this dimension and stay out');
        Assert.AreEqual(Amount, GetTotal(Totals, DimensionValue.Code),
            'Expected the value''s net change to contain only the entry whose set actually carries the value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValueWithoutEntriesDoesNotAppear()
    var
        Dimension: Record Dimension;
        PostedValue: Record "Dimension Value";
        ElsewhereValue: Record "Dimension Value";
        IdleValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        OtherAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Values with no entry on the account earn no key, whether they have sets elsewhere or only a master record
        // [GIVEN] a value posted on the account, a value whose set is used on another account only, and a value that exists only in the Dimension Value table
        AccountNo := LibraryERM.CreateGLAccountNo();
        OtherAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(PostedValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(ElsewhereValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(IdleValue, Dimension.Code);
        Amount := Any.DecimalInRange(100, 900, 2);
        MockGLEntry(AccountNo, Amount, LibraryDimension.CreateDimSet(0, Dimension.Code, PostedValue.Code));
        MockGLEntry(OtherAccountNo, Any.DecimalInRange(100, 900, 2), LibraryDimension.CreateDimSet(0, Dimension.Code, ElsewhereValue.Code));

        // [WHEN] breaking the account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] only the posted value has a key
        Assert.IsFalse(Totals.ContainsKey(ElsewhereValue.Code),
            'Expected a value whose dimension sets are used on other accounts only to stay out of this account''s breakdown — having a set is not having an entry');
        Assert.IsFalse(Totals.ContainsKey(IdleValue.Code),
            'Expected a value that exists only in the Dimension Value table to stay out — the master record alone earns no key, not even a zero one');
        Assert.AreEqual(1, Totals.Count(),
            'Expected exactly one key: only the value with an entry on the account appears');
        Assert.AreEqual(Amount, GetTotal(Totals, PostedValue.Code),
            'Expected the posted value''s net change to be its entry''s amount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShortcutColumnsAreNotTheSource()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        RealAmount: Decimal;
    begin
        // [SCENARIO] The Global Dimension 1/2 Code columns on the entry are not consulted — the dimension is not global
        // [GIVEN] a real entry carrying the value in its set, and a decoy whose shortcut columns spell the value code while its set holds only another dimension
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimWithDimValue(OtherValue);
        RealAmount := Any.DecimalInRange(100, 900, 2);
        MockGLEntry(AccountNo, RealAmount, LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code));
        MockGLEntryWithShortcuts(AccountNo, Any.DecimalInRange(1000, 9000, 2),
            LibraryDimension.CreateDimSet(0, OtherValue."Dimension Code", OtherValue.Code), DimensionValue.Code, DimensionValue.Code);

        // [WHEN] breaking the account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] only the entry whose set carries the value counts
        Assert.AreEqual(RealAmount, GetTotal(Totals, DimensionValue.Code),
            'Expected only the entry whose dimension SET carries the value — the entry whose "Global Dimension 1 Code" and "Global Dimension 2 Code" merely spell the same code, while its set holds no value for this dimension, must stay out; a non-global dimension never lives in those columns');
        Assert.AreEqual(1, Totals.Count(),
            'Expected exactly one key: the shortcut-column decoy must not add a value of its own either');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SameValueCodeOnAnotherDimensionIsNotCounted()
    var
        Dimension: Record Dimension;
        OtherDimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] A value of another dimension that happens to share the code is a different value
        // [GIVEN] two dimensions each owning a value coded TRYAL-SHARED, and one entry on each
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimension(OtherDimension);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'TRYAL-SHARED', Dimension.Code);
        LibraryDimension.CreateDimensionValueWithCode(OtherValue, 'TRYAL-SHARED', OtherDimension.Code);
        Amount := Any.DecimalInRange(100, 900, 2);
        MockGLEntry(AccountNo, Amount, LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code));
        MockGLEntry(AccountNo, Any.DecimalInRange(1000, 9000, 2), LibraryDimension.CreateDimSet(0, OtherDimension.Code, OtherValue.Code));

        // [WHEN] breaking the account down by the first dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] only the first dimension's TRYAL-SHARED entry is counted
        Assert.AreEqual(Amount, GetTotal(Totals, 'TRYAL-SHARED'),
            'Expected only the entry whose set holds TRYAL-SHARED under the requested dimension — the other dimension''s value of the same code is a different value and must not be added');
        Assert.AreEqual(1, Totals.Count(),
            'Expected exactly one key: the other dimension''s entry carries no value for the requested dimension');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AccountWithoutEntriesReturnsEmpty()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
    begin
        // [SCENARIO] An account with no entries at all yields an empty dictionary and no error
        // [GIVEN] a dimension with a value and a set, and an account nothing was posted to
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code);

        // [WHEN] breaking the empty account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] nothing comes back
        Assert.AreEqual(0, Totals.Count(),
            'Expected an empty dictionary and no error for an account without a single entry — a dimension set that exists but was never posted to this account earns no key');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DimensionWithoutSetsReturnsEmpty()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
    begin
        // [SCENARIO] A dimension no dimension set has ever used yields an empty dictionary and no error
        // [GIVEN] a dimension with a value but no set, and an account whose entries carry no dimensions or only another dimension's set
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimWithDimValue(OtherValue);
        MockGLEntry(AccountNo, Any.DecimalInRange(100, 900, 2), 0);
        MockGLEntry(AccountNo, Any.DecimalInRange(100, 900, 2), LibraryDimension.CreateDimSet(0, OtherValue."Dimension Code", OtherValue.Code));

        // [WHEN] breaking the account down by the unused dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] nothing comes back
        Assert.AreEqual(0, Totals.Count(),
            'Expected an empty dictionary and no error for a dimension that no dimension set has ever used — the account has entries, but none of them carries a value for this dimension, and an unused dimension must yield an empty result rather than an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesAddedBetweenCallsAreCounted()
    var
        Dimension: Record Dimension;
        FirstValue: Record "Dimension Value";
        LaterValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        FirstAmount: Decimal;
        LaterAmount: Decimal;
        FirstSetID: Integer;
    begin
        // [SCENARIO] The same codeunit instance reflects entries and dimension sets created after its previous call
        // [GIVEN] one entry, a first call on the instance, then a new value with a brand-new set and an entry posted with it
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(FirstValue, Dimension.Code);
        FirstSetID := LibraryDimension.CreateDimSet(0, Dimension.Code, FirstValue.Code);
        FirstAmount := Any.DecimalInRange(100, 900, 2);
        LaterAmount := Any.DecimalInRange(1000, 9000, 2);
        MockGLEntry(AccountNo, FirstAmount, FirstSetID);
        // the first call on the very same codeunit variable primes any cache a submission keeps across calls
        DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);
        LibraryDimension.CreateDimensionValue(LaterValue, Dimension.Code);
        MockGLEntry(AccountNo, LaterAmount, LibraryDimension.CreateDimSet(0, Dimension.Code, LaterValue.Code));
        MockGLEntry(AccountNo, FirstAmount, FirstSetID);

        // [WHEN] calling again on the same instance
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] both the new set's value and the first value's new entry are in
        Assert.AreEqual(LaterAmount, GetTotal(Totals, LaterValue.Code),
            'Expected the second call to include the value whose dimension set was created after the first call — the map from set to value must be read fresh on every call, never remembered');
        Assert.AreEqual(FirstAmount + FirstAmount, GetTotal(Totals, FirstValue.Code),
            'Expected the second call to include the entry posted after the first call — totals are read from the ledger at call time, never remembered');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EveryValueAppearsExactlyOnceAcrossManySets()
    var
        Dimension: Record Dimension;
        OtherDimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        ValueCodes: List of [Code[20]];
        OtherValueCodes: List of [Code[20]];
        ValueCode: Code[20];
        OtherValueCode: Code[20];
        AccountNo: Code[20];
        ValueCount: Integer;
        AloneSetID: Integer;
        i: Integer;
    begin
        // [SCENARIO] A value spread over several dimension sets comes back as one key holding all of them
        // [GIVEN] several values, each posted once on its own set and once per combination with three other-dimension values
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimension(OtherDimension);
        for i := 1 to 3 do begin
            LibraryDimension.CreateDimensionValue(OtherValue, OtherDimension.Code);
            OtherValueCodes.Add(OtherValue.Code);
        end;
        ValueCount := Any.IntegerInRange(4, 7);
        for i := 1 to ValueCount do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
            ValueCodes.Add(DimensionValue.Code);
            AloneSetID := LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code);
            MockGLEntry(AccountNo, 10, AloneSetID);
            foreach OtherValueCode in OtherValueCodes do
                MockGLEntry(AccountNo, 10, LibraryDimension.CreateDimSet(AloneSetID, OtherDimension.Code, OtherValueCode));
        end;

        // [WHEN] breaking the account down by that dimension
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);

        // [THEN] one key per value, each holding all four of its sets
        Assert.AreEqual(ValueCount, Totals.Count(),
            StrSubstNo('Expected exactly one key per distinct value — %1 values were seeded, each spread over four dimension sets', ValueCount));
        foreach ValueCode in ValueCodes do
            Assert.AreEqual(40.0, GetTotal(Totals, ValueCode),
                StrSubstNo('Expected value %1 to appear once with all four of its dimension sets added together', ValueCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheSqlStatementBudget()
    var
        Dimension: Record Dimension;
        OtherDimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        WarmUpValue: Record "Dimension Value";
        DimensionSetTotals: Codeunit "Dimension Set Totals";
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        Expected: Dictionary of [Code[20], Decimal];
        OtherValueCodes: List of [Code[20]];
        ValueCode: Code[20];
        OtherValueCode: Code[20];
        AccountNo: Code[20];
        WarmUpAccountNo: Code[20];
        ValueCount: Integer;
        SetCount: Integer;
        EntriesPerSet: Integer;
        MaxStatements: Integer;
        AloneSetID: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        // [SCENARIO] One call stays within the statement budget however many entries and distinct sets the account holds
        // [GIVEN] a warm-up call on a throwaway account and dimension, made before any graded data exists
        MaxStatements := 15;
        EntriesPerSet := 6;
        WarmUpAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimWithDimValue(WarmUpValue);
        MockGLEntry(WarmUpAccountNo, 1, LibraryDimension.CreateDimSet(0, WarmUpValue."Dimension Code", WarmUpValue.Code));
        // The first call may pay one-time metadata statements for both tables; grade the steady state.
        // It deliberately touches none of the graded data: Clear drops only the reference to a
        // codeunit and never resets a SingleInstance one, so a per-set memo that resolved the
        // graded sets here would carry them into the measured call. Seeding those sets afterwards
        // means every one of them is a miss the memo still has to pay for.
        DimensionSetTotals.NetChangeByDimensionValue(WarmUpAccountNo, WarmUpValue."Dimension Code");

        // [GIVEN] a few values, each on seven distinct dimension sets, with several entries per set
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimension(OtherDimension);
        for i := 1 to 6 do begin
            LibraryDimension.CreateDimensionValue(OtherValue, OtherDimension.Code);
            OtherValueCodes.Add(OtherValue.Code);
        end;
        ValueCount := Any.IntegerInRange(4, 6);
        for i := 1 to ValueCount do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
            AloneSetID := LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code);
            AddExpected(Expected, DimensionValue.Code, SeedEntries(AccountNo, AloneSetID, EntriesPerSet, Any));
            foreach OtherValueCode in OtherValueCodes do
                AddExpected(Expected, DimensionValue.Code,
                    SeedEntries(AccountNo, LibraryDimension.CreateDimSet(AloneSetID, OtherDimension.Code, OtherValueCode), EntriesPerSet, Any));
        end;
        SetCount := ValueCount * (OtherValueCodes.Count() + 1);

        // a submission that is not SingleInstance starts cold after Clear; the seeding order above
        // is what starves one that is
        Clear(DimensionSetTotals);
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();

        // [WHEN] breaking the graded account down by its dimension for the first time
        Totals := DimensionSetTotals.NetChangeByDimensionValue(AccountNo, Dimension.Code);
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        if DebugBudgets() then
            Assert.Fail(StrSubstNo('DEBUG budget: %1 SQL statements for %2 entries across %3 sets and %4 values',
                StatementsUsed, SetCount * EntriesPerSet, SetCount, ValueCount));

        // [THEN] the numbers are still right and the call cost a handful of statements
        Assert.AreEqual(ValueCount, Totals.Count(),
            StrSubstNo('Expected every one of the %1 values in the breakdown before judging the budget', ValueCount));
        foreach ValueCode in Expected.Keys() do
            Assert.AreEqual(Expected.Get(ValueCode), GetTotal(Totals, ValueCode),
                StrSubstNo('Expected the budget-friendly breakdown to still carry the real net change of value %1', ValueCode));
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the whole breakdown to cost at most %1 SQL statements no matter how many entries the account holds or how many dimension sets they spread across, but this call executed %2 for %3 entries spread over %4 distinct sets — one lookup per entry, or even one per distinct set, does not scale; ask the dimension side which sets carry it first',
                MaxStatements, StatementsUsed, SetCount * EntriesPerSet, SetCount));
    end;

    local procedure SeedEntries(GLAccountNo: Code[20]; DimSetID: Integer; Count: Integer; var Any: Codeunit Any) Sum: Decimal
    var
        Amount: Decimal;
        i: Integer;
    begin
        for i := 1 to Count do begin
            Amount := Any.DecimalInRange(1, 900, 2);
            if Any.Boolean() then
                Amount := -Amount;
            MockGLEntry(GLAccountNo, Amount, DimSetID);
            Sum += Amount;
        end;
    end;

    local procedure AddExpected(var Expected: Dictionary of [Code[20], Decimal]; ValueCode: Code[20]; Amount: Decimal)
    begin
        if Expected.ContainsKey(ValueCode) then
            Expected.Set(ValueCode, Expected.Get(ValueCode) + Amount)
        else
            Expected.Add(ValueCode, Amount);
    end;

    local procedure MockGLEntry(GLAccountNo: Code[20]; Amount: Decimal; DimSetID: Integer)
    begin
        MockGLEntryWithShortcuts(GLAccountNo, Amount, DimSetID, '', '');
    end;

    local procedure MockGLEntryWithShortcuts(GLAccountNo: Code[20]; Amount: Decimal; DimSetID: Integer; GlobalDim1Code: Code[20]; GlobalDim2Code: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast() then;
        GLEntry.Init();
        GLEntry."Entry No." += 1;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Posting Date" := WorkDate();
        GLEntry."Document No." := 'TRYAL-DST';
        GLEntry.Amount := Amount;
        GLEntry."Dimension Set ID" := DimSetID;
        GLEntry."Global Dimension 1 Code" := GlobalDim1Code;
        GLEntry."Global Dimension 2 Code" := GlobalDim2Code;
        GLEntry.Insert();
    end;

    local procedure GetTotal(Totals: Dictionary of [Code[20], Decimal]; ValueCode: Code[20]): Decimal
    begin
        Assert.IsTrue(Totals.ContainsKey(ValueCode),
            StrSubstNo('Expected dimension value %1 to appear in the breakdown', ValueCode));
        exit(Totals.Get(ValueCode));
    end;

    local procedure InvalidateDataCache()
    var
        DecoyValue: Record "Dimension Value";
    begin
        // The warm-up call leaves both tables' result sets in the server data cache,
        // and a cached read costs zero SQL — the graded call would measure nothing.
        // A write bumps each table's version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has locked.
        // The decoy set belongs to a dimension the graded call never asks about, and
        // the decoy entry sits on an account it never filters on.
        LibraryDimension.CreateDimWithDimValue(DecoyValue);
        MockGLEntry('TRYAL-DECOY', 1, LibraryDimension.CreateDimSet(0, DecoyValue."Dimension Code", DecoyValue.Code));
        SelectLatestVersion();
    end;

    // Flip to true while calibrating: the budget test then fails right after measuring
    // and reports the raw counters — a failure message is a test's only output channel
    // on the platform. Ship with false.
    local procedure DebugBudgets(): Boolean
    begin
        exit(false);
    end;
}
