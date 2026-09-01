codeunit 50900 "Enum Wire Mapping Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ToWireReturnsTheDeclaredCodeForEveryValue()
    var
        Mapper: Codeunit "Carrier Status Mapper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Every declared value encodes to its wire code
        Assert.AreEqual(0, Mapper.ToWire("Carrier Status"::Unknown), 'Expected Unknown to encode to wire code 0');
        Assert.AreEqual(10, Mapper.ToWire("Carrier Status"::Registered), 'Expected Registered to encode to wire code 10');
        Assert.AreEqual(20, Mapper.ToWire("Carrier Status"::"In Transit"), 'Expected In Transit to encode to wire code 20');
        Assert.AreEqual(30, Mapper.ToWire("Carrier Status"::Delivered), 'Expected Delivered to encode to wire code 30');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ToWireNameReturnsTheDeclaredValueName()
    var
        Mapper: Codeunit "Carrier Status Mapper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Every declared value encodes to its declared name, never its caption
        Assert.AreEqual('Unknown', Mapper.ToWireName("Carrier Status"::Unknown), 'Expected the declared name of the Unknown value');
        Assert.AreEqual('Registered', Mapper.ToWireName("Carrier Status"::Registered), 'Expected the declared name of the Registered value');
        Assert.AreEqual('In Transit', Mapper.ToWireName("Carrier Status"::"In Transit"), 'Expected the declared name In Transit (capital T) — the caption differs from the name, and captions never go on the wire');
        Assert.AreEqual('Delivered', Mapper.ToWireName("Carrier Status"::Delivered), 'Expected the declared name of the Delivered value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FromWireDecodesEveryDeclaredCode()
    var
        Mapper: Codeunit "Carrier Status Mapper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Every declared wire code decodes to the value with that ordinal
        Assert.AreEqual(0, Mapper.FromWire(0).AsInteger(), 'Expected wire code 0 to decode to Unknown (ordinal 0)');
        Assert.AreEqual(10, Mapper.FromWire(10).AsInteger(), 'Expected wire code 10 to decode to Registered (ordinal 10)');
        Assert.AreEqual(20, Mapper.FromWire(20).AsInteger(), 'Expected wire code 20 to decode to In Transit (ordinal 20)');
        Assert.AreEqual(30, Mapper.FromWire(30).AsInteger(), 'Expected wire code 30 to decode to Delivered (ordinal 30)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FromWireFallsBackToUnknownForUnrecognizedCodes()
    var
        Mapper: Codeunit "Carrier Status Mapper";
        Assert: Codeunit Assert;
        RandomInvalidCode: Integer;
    begin
        // [SCENARIO] A wire code that matches no value decodes to Unknown instead of erroring
        Assert.AreEqual(0, Mapper.FromWire(7).AsInteger(), 'Expected the unrecognized wire code 7 to decode to Unknown');
        Assert.AreEqual(0, Mapper.FromWire(-1).AsInteger(), 'Expected the negative wire code -1 to decode to Unknown');
        RandomInvalidCode := UnrecognizedCode();
        Assert.AreEqual(0, Mapper.FromWire(RandomInvalidCode).AsInteger(), StrSubstNo('Expected the unrecognized wire code %1 to decode to Unknown', RandomInvalidCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FromWireStrictDecodesEveryDeclaredCode()
    var
        Mapper: Codeunit "Carrier Status Mapper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Strict decoding accepts every declared wire code without error
        Assert.AreEqual(0, Mapper.FromWireStrict(0).AsInteger(), 'Expected FromWireStrict to decode wire code 0 to Unknown (ordinal 0)');
        Assert.AreEqual(10, Mapper.FromWireStrict(10).AsInteger(), 'Expected FromWireStrict to decode wire code 10 to Registered (ordinal 10)');
        Assert.AreEqual(20, Mapper.FromWireStrict(20).AsInteger(), 'Expected FromWireStrict to decode wire code 20 to In Transit (ordinal 20)');
        Assert.AreEqual(30, Mapper.FromWireStrict(30).AsInteger(), 'Expected FromWireStrict to decode wire code 30 to Delivered (ordinal 30)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FromWireStrictErrorsOnAnUnrecognizedCode()
    var
        Mapper: Codeunit "Carrier Status Mapper";
        Assert: Codeunit Assert;
        RandomInvalidCode: Integer;
    begin
        // [SCENARIO] Strict decoding of an unrecognized code raises an error naming the code
        asserterror Mapper.FromWireStrict(999);
        Assert.ExpectedError('999');
        RandomInvalidCode := UnrecognizedCode();
        asserterror Mapper.FromWireStrict(RandomInvalidCode);
        Assert.ExpectedError(Format(RandomInvalidCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtensionValueDecodesWithNoMapperChange()
    var
        Mapper: Codeunit "Carrier Status Mapper";
        Assert: Codeunit Assert;
        ReturnedCode: Integer;
    begin
        // [SCENARIO] A value added by an enumextension decodes without any mapper change
        ReturnedCode := ReturnedWireCode();
        Assert.AreEqual(ReturnedCode, Mapper.FromWire(ReturnedCode).AsInteger(), StrSubstNo('Expected wire code %1, added to the enum by an enumextension, to decode to that value with no mapper change — a hardcoded list of values cannot do this', ReturnedCode));
        Assert.AreEqual(ReturnedCode, Mapper.FromWireStrict(ReturnedCode).AsInteger(), StrSubstNo('Expected FromWireStrict to accept wire code %1 once an enumextension declares it', ReturnedCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtensionValueEncodesWithNoMapperChange()
    var
        Mapper: Codeunit "Carrier Status Mapper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A value added by an enumextension encodes without any mapper change
        Assert.AreEqual(ReturnedWireCode(), Mapper.ToWire("Carrier Status"::Returned), 'Expected the enumextension value Returned to encode to its declared ordinal');
        Assert.AreEqual('Returned', Mapper.ToWireName("Carrier Status"::Returned), 'Expected the declared name Returned — its caption deliberately differs, so a caption-based lookup fails here');
    end;

    // The ordinal the extension value ends up with is whatever the runtime assigned to
    // the enumextension, so it is looked up by name instead of being written down.
    local procedure ReturnedWireCode(): Integer
    var
        Status: Enum "Carrier Status";
    begin
        exit(Status.Ordinals().Get(Status.Names().IndexOf('Returned')));
    end;

    // A generated invalid code must not collide with any declared ordinal, the
    // extension value's included.
    local procedure UnrecognizedCode(): Integer
    var
        Any: Codeunit Any;
        Status: Enum "Carrier Status";
        Candidate: Integer;
    begin
        Candidate := Any.IntegerInRange(1000, 9999);
        while Status.Ordinals().Contains(Candidate) do
            Candidate += 1;
        exit(Candidate);
    end;
}
