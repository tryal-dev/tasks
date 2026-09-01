codeunit 50900 "Cue Thresholds Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheCueTableStoresAnOverdueAmount()
    var
        CueRef: RecordRef;
        OverdueAmount: FieldRef;
        Amount: Decimal;
        StoredAmount: Decimal;
    begin
        // [SCENARIO] The Receivables Cue table holds a decimal Overdue Amount
        // [GIVEN] a generated amount and the cue table's "Overdue Amount" field
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        CueRef.Open(Database::"Receivables Cue");
        OverdueAmount := FieldByName(CueRef, 'Overdue Amount');
        Assert.AreEqual(Format(FieldType::Decimal), Format(OverdueAmount.Type()),
            'Expected the Receivables Cue field "Overdue Amount" to be of type Decimal');

        // [WHEN] inserting a cue record carrying that amount
        CueRef.Init();
        OverdueAmount.Value := Amount;
        CueRef.Insert();

        // [THEN] the amount is read back unchanged
        CueRef.Get(CueRef.RecordId());
        StoredAmount := FieldByName(CueRef, 'Overdue Amount').Value();
        Assert.AreEqual(Amount, StoredAmount,
            'Expected the "Overdue Amount" written to the Receivables Cue record to be read back unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstRegistrationReturnsTrue()
    var
        Registrar: Codeunit "Receivables Cue Style";
    begin
        // [SCENARIO] Registering thresholds for the first time reports success
        // [WHEN] registering thresholds while no setup exists for the cue field
        // [THEN] RegisterThresholds returns true
        Assert.IsTrue(
            Registrar.RegisterThresholds(LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(300, 400, 2)),
            'Expected RegisterThresholds to return true when no setup exists for the cue field yet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StyleBelowTheLowerThresholdIsFavorable()
    var
        LowerThreshold: Decimal;
    begin
        // [SCENARIO] An amount strictly below the lower threshold resolves to Favorable
        LowerThreshold := LibraryRandom.RandDecInRange(100, 200, 2);
        AssertStyle(
            Enum::"Cues And KPIs Style"::Favorable,
            RegisterAndResolve(LowerThreshold, LibraryRandom.RandDecInRange(300, 400, 2), LibraryRandom.RandDecInRange(1, 99, 2)),
            'an amount strictly below the lower threshold');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StyleBetweenTheThresholdsIsAmbiguous()
    begin
        // [SCENARIO] An amount strictly between the thresholds resolves to Ambiguous
        AssertStyle(
            Enum::"Cues And KPIs Style"::Ambiguous,
            RegisterAndResolve(LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(300, 400, 2), LibraryRandom.RandDecInRange(201, 299, 2)),
            'an amount strictly between the two thresholds');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StyleAboveTheUpperThresholdIsUnfavorable()
    var
        UpperThreshold: Decimal;
    begin
        // [SCENARIO] An amount strictly above the upper threshold resolves to Unfavorable
        UpperThreshold := LibraryRandom.RandDecInRange(300, 400, 2);
        AssertStyle(
            Enum::"Cues And KPIs Style"::Unfavorable,
            RegisterAndResolve(LibraryRandom.RandDecInRange(100, 200, 2), UpperThreshold, LibraryRandom.RandDecInRange(401, 500, 2)),
            'an amount strictly above the upper threshold');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StyleExactlyAtTheLowerThresholdIsAmbiguous()
    var
        LowerThreshold: Decimal;
    begin
        // [SCENARIO] The lower boundary belongs to the middle band
        LowerThreshold := LibraryRandom.RandDecInRange(100, 200, 2);
        AssertStyle(
            Enum::"Cues And KPIs Style"::Ambiguous,
            RegisterAndResolve(LowerThreshold, LibraryRandom.RandDecInRange(300, 400, 2), LowerThreshold),
            'an amount exactly equal to the lower threshold (the boundary belongs to the middle band)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StyleExactlyAtTheUpperThresholdIsAmbiguous()
    var
        UpperThreshold: Decimal;
    begin
        // [SCENARIO] The upper boundary belongs to the middle band
        UpperThreshold := LibraryRandom.RandDecInRange(300, 400, 2);
        AssertStyle(
            Enum::"Cues And KPIs Style"::Ambiguous,
            RegisterAndResolve(LibraryRandom.RandDecInRange(100, 200, 2), UpperThreshold, UpperThreshold),
            'an amount exactly equal to the upper threshold (the boundary belongs to the middle band)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondRegistrationReturnsFalse()
    var
        Registrar: Codeunit "Receivables Cue Style";
        SecondRegistrar: Codeunit "Receivables Cue Style";
    begin
        // [SCENARIO] Registering when a setup already exists reports failure
        // [GIVEN] an existing registration for the cue field
        Registrar.RegisterThresholds(LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(300, 400, 2));

        // [WHEN] registering a second time
        // [THEN] RegisterThresholds returns false
        Assert.IsFalse(
            SecondRegistrar.RegisterThresholds(LibraryRandom.RandDecInRange(1000, 1100, 2), LibraryRandom.RandDecInRange(2000, 2100, 2)),
            'Expected RegisterThresholds to return false when a setup for the cue field already exists');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondRegistrationKeepsTheFirstThresholds()
    var
        Registrar: Codeunit "Receivables Cue Style";
        SecondRegistrar: Codeunit "Receivables Cue Style";
        Resolver: Codeunit "Receivables Cue Style";
        ProbeAmount: Decimal;
    begin
        // [SCENARIO] A rejected second registration leaves the first thresholds in force
        // [GIVEN] a registration and a much higher second registration attempt
        Registrar.RegisterThresholds(LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(300, 400, 2));
        SecondRegistrar.RegisterThresholds(LibraryRandom.RandDecInRange(1000, 1100, 2), LibraryRandom.RandDecInRange(2000, 2100, 2));

        // [WHEN] resolving an amount above the first upper threshold but below the second registration's lower threshold
        ProbeAmount := LibraryRandom.RandDecInRange(500, 900, 2);

        // [THEN] the first registration still decides: the style is Unfavorable
        AssertStyle(
            Enum::"Cues And KPIs Style"::Unfavorable,
            Resolver.StyleFor(ProbeAmount),
            'an amount above the first upper threshold — the rejected second registration must not overwrite the first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegistrationIsVisibleToThePlatformCueSetup()
    var
        Registrar: Codeunit "Receivables Cue Style";
        CuesAndKPIs: Codeunit "Cues And KPIs";
    begin
        // [SCENARIO] RegisterThresholds occupies the platform's company-wide cue-indicator setup slot
        // [GIVEN] a successful registration through the user's codeunit
        Registrar.RegisterThresholds(LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(300, 400, 2));

        // [WHEN] the platform's own cue-indicator API tries to record a setup for the same cue field
        // [THEN] it reports that a setup already exists — proving the registration landed in the platform store
        Assert.IsFalse(
            CuesAndKPIs.InsertData(
                Database::"Receivables Cue", OverdueAmountFieldNo(),
                Enum::"Cues And KPIs Style"::Favorable, LibraryRandom.RandDecInRange(1000, 1100, 2),
                Enum::"Cues And KPIs Style"::Ambiguous, LibraryRandom.RandDecInRange(2000, 2100, 2),
                Enum::"Cues And KPIs Style"::Unfavorable),
            'Expected RegisterThresholds to record its setup in the platform''s company-wide cue-indicator storage, so the platform rejects a second setup for the "Overdue Amount" cue field');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StyleForResolvesASetupRecordedByThePlatform()
    var
        Resolver: Codeunit "Receivables Cue Style";
        CuesAndKPIs: Codeunit "Cues And KPIs";
        UpperThreshold: Decimal;
    begin
        // [SCENARIO] StyleFor reads the platform's cue-indicator setup, not private state
        // [GIVEN] a setup recorded directly through the platform's cue-indicator API, bypassing RegisterThresholds
        UpperThreshold := LibraryRandom.RandDecInRange(300, 400, 2);
        CuesAndKPIs.InsertData(
            Database::"Receivables Cue", OverdueAmountFieldNo(),
            Enum::"Cues And KPIs Style"::Favorable, LibraryRandom.RandDecInRange(100, 200, 2),
            Enum::"Cues And KPIs Style"::Ambiguous, UpperThreshold,
            Enum::"Cues And KPIs Style"::Unfavorable);

        // [WHEN] resolving an amount above that setup's upper threshold
        // [THEN] StyleFor finds the platform-recorded setup and returns Unfavorable
        AssertStyle(
            Enum::"Cues And KPIs Style"::Unfavorable,
            Resolver.StyleFor(LibraryRandom.RandDecInRange(401, 500, 2)),
            'an amount above the upper threshold of a setup recorded by the platform''s own cue-indicator API — StyleFor must resolve from the platform store');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StyleIsNoneWhenNothingIsRegistered()
    var
        Resolver: Codeunit "Receivables Cue Style";
    begin
        // [SCENARIO] Without any registration StyleFor falls back to None
        // [WHEN] resolving an amount while no setup exists for the cue field
        // [THEN] the style is None
        AssertStyle(
            Enum::"Cues And KPIs Style"::None,
            Resolver.StyleFor(LibraryRandom.RandDecInRange(1, 1000, 2)),
            'any amount when no setup was registered for the cue field');
    end;

    local procedure RegisterAndResolve(LowerThreshold: Decimal; UpperThreshold: Decimal; Amount: Decimal): Enum "Cues And KPIs Style"
    var
        Registrar: Codeunit "Receivables Cue Style";
        Resolver: Codeunit "Receivables Cue Style";
    begin
        // Separate instances so thresholds kept in codeunit state cannot pass.
        Registrar.RegisterThresholds(LowerThreshold, UpperThreshold);
        exit(Resolver.StyleFor(Amount));
    end;

    local procedure OverdueAmountFieldNo(): Integer
    var
        CueRef: RecordRef;
    begin
        CueRef.Open(Database::"Receivables Cue");
        exit(FieldByName(CueRef, 'Overdue Amount').Number());
    end;

    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        Index: Integer;
    begin
        // Looked up by name at run time so the tests compile against a starter that
        // has not added the field yet, and fail with a message that names it.
        for Index := 1 to RecRef.FieldCount() do
            if RecRef.FieldIndex(Index).Name() = FieldName then
                exit(RecRef.FieldIndex(Index));
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;

    local procedure AssertStyle(ExpectedStyle: Enum "Cues And KPIs Style"; ActualStyle: Enum "Cues And KPIs Style"; AmountDescription: Text)
    begin
        Assert.AreEqual(Format(ExpectedStyle), Format(ActualStyle),
            StrSubstNo('Expected StyleFor to return %1 for %2', ExpectedStyle, AmountDescription));
    end;
}
