codeunit 50900 "Dispatch Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstCallCreatesTheMissingRow()
    var
        DispatchSetup: Record "Dispatch Setup";
        StoredSetup: Record "Dispatch Setup";
        SetupMgt: Codeunit "Dispatch Setup Mgt.";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] GetSetup auto-creates the setup row when the table is empty
        Initialize();

        SetupMgt.GetSetup(DispatchSetup);

        Assert.IsTrue(StoredSetup.Get(''),
            'Expected the first GetSetup call to insert the setup row with the empty primary key — the row must really live in the table, not just in memory');
        Assert.RecordCount(StoredSetup, 1);
        Assert.AreEqual('', Format(DispatchSetup."Primary Key"),
            'Expected the returned setup record to carry the empty primary key');
        Assert.AreEqual('', Format(DispatchSetup."Default Carrier Code"),
            'Expected the auto-created row to come back with the default (empty) carrier code');
        Assert.AreEqual(0.0, DispatchSetup."Max Package Weight",
            'Expected the auto-created row to come back with the default (zero) maximum package weight');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheValuesStoredInTheTable()
    var
        DispatchSetup: Record "Dispatch Setup";
        StoredSetup: Record "Dispatch Setup";
        SetupMgt: Codeunit "Dispatch Setup Mgt.";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Carrier: Code[20];
        Weight: Decimal;
    begin
        // [SCENARIO] An existing setup row is served as-is, neither overwritten nor duplicated
        Initialize();
        Carrier := CopyStr(StrSubstNo('CARRIER%1', Any.IntegerInRange(100, 999)), 1, MaxStrLen(Carrier));
        Weight := Any.DecimalInRange(1, 999, 2);
        SeedSetup(Carrier, Weight);

        SetupMgt.GetSetup(DispatchSetup);

        Assert.AreEqual(Carrier, DispatchSetup."Default Carrier Code",
            'Expected GetSetup to hand back the carrier code stored in the table');
        Assert.AreEqual(Weight, DispatchSetup."Max Package Weight",
            'Expected GetSetup to hand back the maximum package weight stored in the table');
        Assert.RecordCount(StoredSetup, 1);
        StoredSetup.Get('');
        Assert.AreEqual(Carrier, StoredSetup."Default Carrier Code",
            'Expected the existing row to be left untouched — auto-create fires only when the row is missing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsServingTheCachedCopyWithoutInvalidate()
    var
        DispatchSetup: Record "Dispatch Setup";
        SetupMgt: Codeunit "Dispatch Setup Mgt.";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OldCarrier: Code[20];
        OldWeight: Decimal;
    begin
        // [SCENARIO] A change written straight to the table stays invisible until someone invalidates
        Initialize();
        OldCarrier := CopyStr(StrSubstNo('OLD%1', Any.IntegerInRange(100, 999)), 1, MaxStrLen(OldCarrier));
        OldWeight := Any.DecimalInRange(1, 499, 2);
        SeedSetup(OldCarrier, OldWeight);
        SetupMgt.GetSetup(DispatchSetup);
        UpdateStoredSetup(CopyStr(StrSubstNo('NEW%1', Any.IntegerInRange(100, 999)), 1, 20), Any.DecimalInRange(500, 999, 2));

        SetupMgt.GetSetup(DispatchSetup);

        Assert.AreEqual(OldCarrier, DispatchSetup."Default Carrier Code",
            'Expected the second call to serve the copy read earlier — a carrier code changed straight in the table must stay invisible until Invalidate is called');
        Assert.AreEqual(OldWeight, DispatchSetup."Max Package Weight",
            'Expected the second call to serve the copy read earlier — a weight changed straight in the table must stay invisible until Invalidate is called');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheCacheIsSharedAcrossCodeunitVariables()
    var
        DispatchSetup: Record "Dispatch Setup";
        WarmSetupMgt: Codeunit "Dispatch Setup Mgt.";
        ColdSetupMgt: Codeunit "Dispatch Setup Mgt.";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OldCarrier: Code[20];
        OldWeight: Decimal;
    begin
        // [SCENARIO] The cache lives at session scope, so a second, independent variable is served from it
        Initialize();
        OldCarrier := CopyStr(StrSubstNo('OLD%1', Any.IntegerInRange(100, 999)), 1, MaxStrLen(OldCarrier));
        OldWeight := Any.DecimalInRange(1, 499, 2);
        SeedSetup(OldCarrier, OldWeight);
        WarmSetupMgt.GetSetup(DispatchSetup);
        UpdateStoredSetup(CopyStr(StrSubstNo('NEW%1', Any.IntegerInRange(100, 999)), 1, 20), Any.DecimalInRange(500, 999, 2));

        ColdSetupMgt.GetSetup(DispatchSetup);

        Assert.AreEqual(OldCarrier, DispatchSetup."Default Carrier Code",
            'Expected every codeunit variable in the session to share one cache — the copy warmed through the first variable must serve the second variable too, so a cache tied to a single variable fails here');
        Assert.AreEqual(OldWeight, DispatchSetup."Max Package Weight",
            'Expected the second variable to be served the cached weight, not a fresh read of the table');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvalidateMakesTheNextCallReadTheTableAgain()
    var
        DispatchSetup: Record "Dispatch Setup";
        SetupMgt: Codeunit "Dispatch Setup Mgt.";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NewCarrier: Code[20];
        NewWeight: Decimal;
    begin
        // [SCENARIO] Invalidate drops the cached copy, so the next call picks up direct table changes
        Initialize();
        SeedSetup(CopyStr(StrSubstNo('OLD%1', Any.IntegerInRange(100, 999)), 1, 20), Any.DecimalInRange(1, 499, 2));
        SetupMgt.GetSetup(DispatchSetup);
        NewCarrier := CopyStr(StrSubstNo('NEW%1', Any.IntegerInRange(100, 999)), 1, MaxStrLen(NewCarrier));
        NewWeight := Any.DecimalInRange(500, 999, 2);
        UpdateStoredSetup(NewCarrier, NewWeight);
        SetupMgt.Invalidate();

        SetupMgt.GetSetup(DispatchSetup);

        Assert.AreEqual(NewCarrier, DispatchSetup."Default Carrier Code",
            'Expected Invalidate to drop the cached copy so the next call reads the current carrier code from the table');
        Assert.AreEqual(NewWeight, DispatchSetup."Max Package Weight",
            'Expected Invalidate to drop the cached copy so the next call reads the current weight from the table');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvalidateThenDeletedRowIsRecreated()
    var
        DispatchSetup: Record "Dispatch Setup";
        StoredSetup: Record "Dispatch Setup";
        SetupMgt: Codeunit "Dispatch Setup Mgt.";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] After the row vanished and the cache was invalidated, the next call auto-creates again
        Initialize();
        SeedSetup(CopyStr(StrSubstNo('OLD%1', Any.IntegerInRange(100, 999)), 1, 20), Any.DecimalInRange(1, 999, 2));
        SetupMgt.GetSetup(DispatchSetup);
        StoredSetup.DeleteAll();
        SetupMgt.Invalidate();

        SetupMgt.GetSetup(DispatchSetup);

        Assert.IsTrue(StoredSetup.Get(''),
            'Expected the call after Invalidate to re-create the setup row that had been deleted');
        Assert.RecordCount(StoredSetup, 1);
        Assert.AreEqual('', Format(DispatchSetup."Default Carrier Code"),
            'Expected the re-created row to come back with default values, not the ones cached before the deletion');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepeatedCallsAreServedWithoutSql()
    var
        DispatchSetup: Record "Dispatch Setup";
        WarmSetupMgt: Codeunit "Dispatch Setup Mgt.";
        GradedSetupMgt: Codeunit "Dispatch Setup Mgt.";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Carrier: Code[20];
        Weight: Decimal;
        CallCount: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        // [SCENARIO] After the warm-up, a burst of GetSetup calls costs zero SQL statements
        Initialize();
        Carrier := CopyStr(StrSubstNo('CARRIER%1', Any.IntegerInRange(100, 999)), 1, MaxStrLen(Carrier));
        Weight := Any.DecimalInRange(1, 999, 2);
        SeedSetup(Carrier, Weight);
        // the warm-up pays the one real read plus any one-time metadata statements
        WarmSetupMgt.GetSetup(DispatchSetup);
        InsertDecoyRow();
        SelectLatestVersion();

        CallCount := 10;
        StatementsUsed := 0;
        for i := 1 to CallCount do begin
            // each bump invalidates the table's cached result sets, so a per-call
            // read pays a real statement inside the measured window every time
            BumpTableVersion(i);
            StatementsBefore := SessionInformation.SqlStatementsExecuted();
            GradedSetupMgt.GetSetup(DispatchSetup);
            StatementsUsed += SessionInformation.SqlStatementsExecuted() - StatementsBefore;
        end;

        Assert.AreEqual(Carrier, DispatchSetup."Default Carrier Code",
            'Expected the burst of calls to still return the stored carrier code before the budget is judged');
        Assert.AreEqual(Weight, DispatchSetup."Max Package Weight",
            'Expected the burst of calls to still return the stored maximum package weight before the budget is judged');
        Assert.AreEqual(0L, StatementsUsed,
            StrSubstNo('Expected %1 GetSetup calls after the warm-up to execute 0 SQL statements — served purely from the session''s memory copy — but they executed %2; the data cache was knocked out before every call, so each per-call read of the setup table costs a real statement', CallCount, StatementsUsed));
    end;

    local procedure Initialize()
    var
        DispatchSetup: Record "Dispatch Setup";
        SetupMgt: Codeunit "Dispatch Setup Mgt.";
    begin
        // the database rolls back between tests, but a session-scoped cache does
        // not — start every test with an empty table AND an empty cache
        DispatchSetup.DeleteAll();
        SetupMgt.Invalidate();
    end;

    local procedure SeedSetup(CarrierCode: Code[20]; MaxWeight: Decimal)
    var
        DispatchSetup: Record "Dispatch Setup";
    begin
        DispatchSetup.Init();
        DispatchSetup."Primary Key" := '';
        DispatchSetup."Default Carrier Code" := CarrierCode;
        DispatchSetup."Max Package Weight" := MaxWeight;
        DispatchSetup.Insert();
    end;

    local procedure UpdateStoredSetup(CarrierCode: Code[20]; MaxWeight: Decimal)
    var
        DispatchSetup: Record "Dispatch Setup";
    begin
        DispatchSetup.Get('');
        DispatchSetup."Default Carrier Code" := CarrierCode;
        DispatchSetup."Max Package Weight" := MaxWeight;
        DispatchSetup.Modify();
    end;

    local procedure InsertDecoyRow()
    var
        DispatchSetup: Record "Dispatch Setup";
    begin
        // lives under a non-empty primary key, so no Get('') ever returns it
        DispatchSetup.Init();
        DispatchSetup."Primary Key" := 'ZZ-DECOY';
        DispatchSetup.Insert();
    end;

    local procedure BumpTableVersion(Bump: Integer)
    var
        DispatchSetup: Record "Dispatch Setup";
    begin
        // a write bumps the table's version and invalidates its cached result
        // sets; SelectLatestVersion alone is not enough for rows this
        // transaction has locked
        DispatchSetup.Get('ZZ-DECOY');
        DispatchSetup."Max Package Weight" := Bump;
        DispatchSetup.Modify();
    end;
}
