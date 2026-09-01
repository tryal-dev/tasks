codeunit 50900 "Inbound Xml Validation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidOrderComesBackValidWithEmptyDiagnostic()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Diagnostic: Text;
        OrderNo: Text;
        Quantity: Integer;
    begin
        // [SCENARIO] A well-formed order that satisfies the schema is Valid
        OrderNo := Any.AlphanumericText(10);
        Quantity := Any.IntegerInRange(1, 9999);

        Assert.AreEqual(Format("Xml Verdict"::Valid),
            Format(InboundXmlValidation.Validate(DefaultNsOrder(OrderNo, Format(Quantity)), Diagnostic)),
            StrSubstNo('Expected the verdict Valid for a well-formed order that satisfies the schema (order no %1, quantity %2)', OrderNo, Quantity));
        Assert.AreEqual('', Diagnostic,
            'Expected an empty Diagnostic for a valid order — rule 3');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidOrderUnderANamespacePrefixIsStillValid()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Diagnostic: Text;
        OrderNo: Text;
    begin
        // [SCENARIO] The sender declares urn:tryal:orders under a prefix instead of as default
        OrderNo := Any.AlphanumericText(10);

        Assert.AreEqual(Format("Xml Verdict"::Valid),
            Format(InboundXmlValidation.Validate(PrefixedNsOrder(OrderNo, Format(Any.IntegerInRange(1, 9999))), Diagnostic)),
            StrSubstNo('Expected the verdict Valid for order no %1 sent under a namespace prefix — the prefix is the sender''s choice, only the namespace URI is identity', OrderNo));
        Assert.AreEqual('', Diagnostic,
            'Expected an empty Diagnostic for a valid order sent under a namespace prefix');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PlainTextComesBackNotWellFormed()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Diagnostic: Text;
        Payload: Text;
    begin
        // [SCENARIO] A payload with no XML in it at all is NotWellFormed
        Payload := Any.AlphabeticText(24);

        Assert.AreEqual(Format("Xml Verdict"::NotWellFormed),
            Format(InboundXmlValidation.Validate(Payload, Diagnostic)),
            StrSubstNo('Expected the verdict NotWellFormed for the plain-text payload %1', Payload));
        Assert.AreEqual('', Diagnostic,
            'Expected an empty Diagnostic for a not-well-formed payload — rule 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MismatchedTagsComeBackNotWellFormed()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Diagnostic: Text;
    begin
        // [SCENARIO] A payload whose closing tag does not match its opening tag is NotWellFormed
        Assert.AreEqual(Format("Xml Verdict"::NotWellFormed),
            Format(InboundXmlValidation.Validate('<Order xmlns="urn:tryal:orders"><OrderNo>TRYAL-1</Order>', Diagnostic)),
            'Expected the verdict NotWellFormed for a payload with a mismatched closing tag');
        Assert.AreEqual('', Diagnostic,
            'Expected an empty Diagnostic for a not-well-formed payload — rule 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyPayloadComesBackNotWellFormed()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Diagnostic: Text;
    begin
        // [SCENARIO] An empty payload is NotWellFormed, not an error
        Assert.AreEqual(Format("Xml Verdict"::NotWellFormed),
            Format(InboundXmlValidation.Validate('', Diagnostic)),
            'Expected the verdict NotWellFormed for an empty payload');
        Assert.AreEqual('', Diagnostic,
            'Expected an empty Diagnostic for an empty payload — rule 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnexpectedElementIsSchemaInvalidAndDiagnosticNamesIt()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Diagnostic: Text;
        ExtraName: Text;
        Payload: Text;
    begin
        // [SCENARIO] An element the schema does not allow makes the order SchemaInvalid
        ExtraName := Any.AlphabeticText(8);
        Payload := StrSubstNo('<Order xmlns="urn:tryal:orders"><OrderNo>%1</OrderNo><Quantity>%2</Quantity><%3>x</%3></Order>',
            Any.AlphanumericText(8), Any.IntegerInRange(1, 99), ExtraName);

        Assert.AreEqual(Format("Xml Verdict"::SchemaInvalid),
            Format(InboundXmlValidation.Validate(Payload, Diagnostic)),
            StrSubstNo('Expected the verdict SchemaInvalid for an order carrying the unexpected element <%1>', ExtraName));
        Assert.IsTrue(Diagnostic.Contains(ExtraName),
            StrSubstNo('Expected the Diagnostic to name the unexpected element %1, got "%2"', ExtraName, Diagnostic));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingQuantityIsSchemaInvalidAndDiagnosticNamesQuantity()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Diagnostic: Text;
        Payload: Text;
    begin
        // [SCENARIO] An order without the required Quantity element is SchemaInvalid
        Payload := StrSubstNo('<Order xmlns="urn:tryal:orders"><OrderNo>%1</OrderNo></Order>', Any.AlphanumericText(8));

        Assert.AreEqual(Format("Xml Verdict"::SchemaInvalid),
            Format(InboundXmlValidation.Validate(Payload, Diagnostic)),
            'Expected the verdict SchemaInvalid for an order missing the required Quantity element');
        Assert.IsTrue(Diagnostic.Contains('Quantity'),
            StrSubstNo('Expected the Diagnostic to name the missing element Quantity, got "%1"', Diagnostic));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonIntegerQuantityIsSchemaInvalidAndDiagnosticShowsTheValue()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Diagnostic: Text;
        BadValue: Text;
    begin
        // [SCENARIO] A Quantity that is not an integer is SchemaInvalid
        BadValue := Any.AlphabeticText(6);

        Assert.AreEqual(Format("Xml Verdict"::SchemaInvalid),
            Format(InboundXmlValidation.Validate(DefaultNsOrder(Any.AlphanumericText(8), BadValue), Diagnostic)),
            StrSubstNo('Expected the verdict SchemaInvalid for a Quantity holding the non-integer value %1', BadValue));
        Assert.IsTrue(Diagnostic.Contains(BadValue),
            StrSubstNo('Expected the Diagnostic to show the rejected Quantity value %1, got "%2"', BadValue, Diagnostic));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DiagnosticFromAnEarlierFailureDoesNotLeak()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Diagnostic: Text;
        OrderNo: Text;
    begin
        // [SCENARIO] A valid order right after a schema violation must not inherit the old Diagnostic
        // [GIVEN] a failed validation that filled the caller's Diagnostic variable
        InboundXmlValidation.Validate(StrSubstNo('<Order xmlns="urn:tryal:orders"><OrderNo>%1</OrderNo></Order>', Any.AlphanumericText(8)), Diagnostic);
        OrderNo := Any.AlphanumericText(10);

        // [WHEN] validating a valid order through the same variable
        // [THEN] the verdict is Valid and the stale text is gone
        Assert.AreEqual(Format("Xml Verdict"::Valid),
            Format(InboundXmlValidation.Validate(DefaultNsOrder(OrderNo, Format(Any.IntegerInRange(1, 9999))), Diagnostic)),
            StrSubstNo('Expected the verdict Valid for the valid order %1 that follows a failed validation', OrderNo));
        Assert.AreEqual('', Diagnostic,
            'Expected an empty Diagnostic after a valid order — text from the earlier failed call must not leak through (rule 5)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DiagnosticDoesNotSurviveANotWellFormedPayload()
    var
        InboundXmlValidation: Codeunit "Inbound Xml Validation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Diagnostic: Text;
        Payload: Text;
    begin
        // [SCENARIO] A not-well-formed payload right after a schema violation must not inherit the old Diagnostic
        // [GIVEN] a failed validation that filled the caller's Diagnostic variable
        InboundXmlValidation.Validate(StrSubstNo('<Order xmlns="urn:tryal:orders"><OrderNo>%1</OrderNo></Order>', Any.AlphanumericText(8)), Diagnostic);
        Payload := Any.AlphabeticText(24);

        // [WHEN] validating plain text through the same variable
        // [THEN] the verdict is NotWellFormed and the stale text is gone
        Assert.AreEqual(Format("Xml Verdict"::NotWellFormed),
            Format(InboundXmlValidation.Validate(Payload, Diagnostic)),
            StrSubstNo('Expected the verdict NotWellFormed for the plain-text payload %1 that follows a failed validation', Payload));
        Assert.AreEqual('', Diagnostic,
            'Expected an empty Diagnostic for a not-well-formed payload — text from the earlier failed call must not leak through (rules 1 and 5)');
    end;

    local procedure DefaultNsOrder(OrderNo: Text; Quantity: Text): Text
    begin
        exit(StrSubstNo('<Order xmlns="urn:tryal:orders"><OrderNo>%1</OrderNo><Quantity>%2</Quantity></Order>', OrderNo, Quantity));
    end;

    local procedure PrefixedNsOrder(OrderNo: Text; Quantity: Text): Text
    begin
        exit(StrSubstNo('<po:Order xmlns:po="urn:tryal:orders"><po:OrderNo>%1</po:OrderNo><po:Quantity>%2</po:Quantity></po:Order>', OrderNo, Quantity));
    end;
}
