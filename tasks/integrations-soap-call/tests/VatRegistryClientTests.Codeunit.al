codeunit 50900 "Vat Registry Client Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // The mock answers requests sent through the handler interface; grading
    // containers have no outbound network, so a submission that bypasses the
    // seam with a raw HttpClient must fail loudly instead of hanging on a
    // dead socket.
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        SoapEnvNsLbl: Label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        Soap12EnvNsLbl: Label 'http://www.w3.org/2003/05/soap-envelope', Locked = true;
        VatNsLbl: Label 'urn:tryal:vat:registry:v1', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheTraderNameFromASuccessfulResponse()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
        VatRegistryClient: Codeunit "Vat Registry Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedName: Text;
        TraderName: Text;
        FaultReason: Text;
    begin
        // [SCENARIO] A 200 response with a CheckVatResponse yields true and the trader name
        ExpectedName := 'Trader ' + Any.AlphabeticText(10);
        MockVatRegistry.SetResponse(200, SuccessBody(ExpectedName, 'DK', '88776655'));
        TraderName := 'STALE';
        FaultReason := 'STALE';

        Assert.IsTrue(VatRegistryClient.CheckVat('DK', '88776655', MockVatRegistry, TraderName, FaultReason),
            'Expected CheckVat to return true for a 200 response carrying a CheckVatResponse');
        Assert.AreEqual(ExpectedName, TraderName,
            'Expected TraderName to be the text content of the registry-namespace TraderName element');
        Assert.AreEqual('', FaultReason,
            'Expected FaultReason to be empty on a successful call (it was preset to STALE)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsExactlyOnePostRequestToTheGatewayEndpoint()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
        VatRegistryClient: Codeunit "Vat Registry Client";
        Assert: Codeunit Assert;
        TraderName: Text;
        FaultReason: Text;
    begin
        // [SCENARIO] One CheckVat call is one POST to the documented URL
        MockVatRegistry.SetResponse(200, SuccessBody('Any Trader', 'DK', '11223344'));

        VatRegistryClient.CheckVat('DK', '11223344', MockVatRegistry, TraderName, FaultReason);

        Assert.AreEqual(1, MockVatRegistry.GetRequestCount(),
            'Expected exactly one request to reach the gateway for a single CheckVat call');
        Assert.AreEqual('POST', UpperCase(MockVatRegistry.GetCapturedMethod()),
            'Expected the request sent through the handler to use the POST method — SOAP always travels by POST');
        Assert.AreEqual('https://vat.example.gov/registry/v1/soap', MockVatRegistry.GetCapturedUri(),
            'Expected the full request URL to be exactly the documented gateway endpoint');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsASoap11EnvelopeCarryingTheCheckVatPayload()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
        VatRegistryClient: Codeunit "Vat Registry Client";
        Any: Codeunit Any;
        CountryCode: Text;
        VatNumber: Text;
        TraderName: Text;
        FaultReason: Text;
    begin
        // [SCENARIO] The request body is a namespace-correct SOAP 1.1 CheckVatRequest envelope
        CountryCode := UpperCase(Any.AlphabeticText(2));
        VatNumber := Format(Any.IntegerInRange(10000000, 99999999));
        MockVatRegistry.SetResponse(200, SuccessBody('Any Trader', CountryCode, VatNumber));

        VatRegistryClient.CheckVat(CountryCode, VatNumber, MockVatRegistry, TraderName, FaultReason);

        VerifyRequestEnvelope(MockVatRegistry.GetCapturedBody(), CountryCode, VatNumber);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsTheSoap11ContentTypeHeader()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
        VatRegistryClient: Codeunit "Vat Registry Client";
        Assert: Codeunit Assert;
        TraderName: Text;
        FaultReason: Text;
    begin
        // [SCENARIO] The request announces SOAP 1.1: text/xml with charset=utf-8
        MockVatRegistry.SetResponse(200, SuccessBody('Any Trader', 'DK', '11223344'));

        VatRegistryClient.CheckVat('DK', '11223344', MockVatRegistry, TraderName, FaultReason);

        Assert.AreEqual('text/xml;charset=utf-8', LowerCase(DelChr(MockVatRegistry.GetCapturedContentType(), '=', ' ')),
            'Expected the SOAP 1.1 Content-Type — media type text/xml with the charset=utf-8 parameter (application/soap+xml is SOAP 1.2 and the gateway rejects it; a bare text/xml misses the charset). Case and spacing are ignored by this comparison');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsTheQuotedSoapActionHeader()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
        VatRegistryClient: Codeunit "Vat Registry Client";
        Assert: Codeunit Assert;
        TraderName: Text;
        FaultReason: Text;
    begin
        // [SCENARIO] The request carries SOAPAction with the quotes SOAP 1.1 demands
        MockVatRegistry.SetResponse(200, SuccessBody('Any Trader', 'DK', '11223344'));

        VatRegistryClient.CheckVat('DK', '11223344', MockVatRegistry, TraderName, FaultReason);

        Assert.IsTrue(MockVatRegistry.HasSoapActionHeader(),
            'Expected the request to carry a SOAPAction header — SOAP 1.1 requires it even though the operation is already named inside the body (SOAP 1.2 dropped it, this gateway did not)');
        Assert.AreEqual('"urn:tryal:vat:registry:v1/CheckVat"', MockVatRegistry.GetCapturedSoapAction(),
            'Expected the SOAPAction value to be the operation URI wrapped in double quotes — in SOAP 1.1 the quotes are part of the header value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesTheResponseWhateverPrefixesTheGatewayUses()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
        VatRegistryClient: Codeunit "Vat Registry Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedName: Text;
        TraderName: Text;
        FaultReason: Text;
    begin
        // [SCENARIO] Shuffled prefixes and a foreign-namespace decoy do not fool the parser
        ExpectedName := 'O''Brien & <' + Any.AlphabeticText(6) + '> ApS';
        MockVatRegistry.SetResponse(200, ShuffledSuccessBody(ExpectedName));
        TraderName := 'STALE';

        Assert.IsTrue(VatRegistryClient.CheckVat('IE', '99887766', MockVatRegistry, TraderName, FaultReason),
            'Expected CheckVat to return true — this 200 response is the same CheckVatResponse, only with different namespace prefixes');
        Assert.AreEqual(ExpectedName, TraderName,
            'Expected the registry-namespace TraderName (prefixes are the gateway''s choice; a TraderName in a foreign namespace sits ahead of the real one, and the name contains & and angle brackets)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheFaultReasonWhenTheGatewayRejectsTheCall()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
        VatRegistryClient: Codeunit "Vat Registry Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedReason: Text;
        TraderName: Text;
        FaultReason: Text;
    begin
        // [SCENARIO] A 500 SOAP fault yields false plus the faultstring text
        ExpectedReason := 'Unknown & <invalid> VAT number ' + Any.AlphabeticText(8);
        MockVatRegistry.SetResponse(500, FaultBody(ExpectedReason));
        TraderName := 'STALE';
        FaultReason := 'STALE';

        Assert.IsFalse(VatRegistryClient.CheckVat('DK', '00000000', MockVatRegistry, TraderName, FaultReason),
            'Expected CheckVat to return false when the gateway answers 500 with a SOAP fault');
        Assert.AreEqual(ExpectedReason, FaultReason,
            'Expected FaultReason to be the text content of faultstring — which SOAP 1.1 leaves in NO namespace, unlike the Fault element around it — with the & and angle brackets the reason contains unescaped back to plain text');
        Assert.AreEqual('', TraderName,
            'Expected TraderName to end up empty on a fault (it was preset to STALE)');
        Assert.AreEqual(1, MockVatRegistry.GetRequestCount(),
            'Expected exactly one request even when the gateway answers with a fault — CheckVat does not retry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheRequestCannotBeSent()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
    begin
        // [SCENARIO] A transport failure yields false with both outputs empty
        MockVatRegistry.SetSendFailure();

        VerifyCheckVatFailsWithEmptyOutputs(MockVatRegistry,
            'when the handler reports a transport failure — the request never reached the gateway');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheProxyAnswersWithoutASoapFault()
    var
        MockVatRegistry: Codeunit "Mock Vat Registry";
    begin
        // [SCENARIO] A 502 HTML page from a proxy yields false with both outputs empty
        // The unclosed <br> makes the body real-world HTML that is NOT well-formed XML,
        // so an unguarded XmlDocument parse of the response raises instead of returning false.
        MockVatRegistry.SetResponse(502, '<html><body>502 Bad Gateway<br>nginx</body></html>');

        VerifyCheckVatFailsWithEmptyOutputs(MockVatRegistry,
            'for a 502 proxy response whose HTML body contains no SOAP fault — FaultReason may only carry a real faultstring');
    end;

    local procedure VerifyCheckVatFailsWithEmptyOutputs(MockVatRegistry: Codeunit "Mock Vat Registry"; FailureContext: Text)
    var
        VatRegistryClient: Codeunit "Vat Registry Client";
        Assert: Codeunit Assert;
        TraderName: Text;
        FaultReason: Text;
    begin
        TraderName := 'STALE';
        FaultReason := 'STALE';

        Assert.IsFalse(VatRegistryClient.CheckVat('DK', '11223344', MockVatRegistry, TraderName, FaultReason),
            StrSubstNo('Expected CheckVat to return false %1', FailureContext));
        Assert.AreEqual('', TraderName,
            StrSubstNo('Expected TraderName to end up empty (it was preset to STALE) %1', FailureContext));
        Assert.AreEqual('', FaultReason,
            StrSubstNo('Expected FaultReason to end up empty (it was preset to STALE) %1', FailureContext));
        Assert.AreEqual(1, MockVatRegistry.GetRequestCount(),
            StrSubstNo('Expected exactly one request even when the call fails — CheckVat does not retry — %1', FailureContext));
    end;

    local procedure VerifyRequestEnvelope(RequestBody: Text; CountryCode: Text; VatNumber: Text)
    var
        Assert: Codeunit Assert;
        Doc: XmlDocument;
        NsMgr: XmlNamespaceManager;
        Node: XmlNode;
        Nodes: XmlNodeList;
    begin
        if RequestBody = '' then
            Assert.Fail('Expected the request to carry a SOAP envelope as its body, but the request body was empty');
        if not XmlDocument.ReadFrom(RequestBody, Doc) then
            Assert.Fail(StrSubstNo('Expected the request body to be well-formed XML, got: %1', RequestBody));

        NsMgr.NameTable(Doc.NameTable());
        NsMgr.AddNamespace('s', SoapEnvNsLbl);
        NsMgr.AddNamespace('s12', Soap12EnvNsLbl);
        NsMgr.AddNamespace('v', VatNsLbl);

        if not Doc.SelectSingleNode('/s:Envelope', NsMgr, Node) then begin
            if Doc.SelectSingleNode('/s12:Envelope', NsMgr, Node) then
                Assert.Fail(StrSubstNo('The request envelope uses the SOAP 1.2 namespace %1 — this gateway speaks SOAP 1.1, whose envelope namespace is %2', Soap12EnvNsLbl, SoapEnvNsLbl));
            Assert.Fail(StrSubstNo('Expected the root element to be Envelope in the SOAP 1.1 namespace %1 (namespace URI decides identity, the prefix is your choice). Request body: %2', SoapEnvNsLbl, RequestBody));
        end;

        if not Doc.SelectSingleNode('/s:Envelope/s:Body', NsMgr, Node) then
            Assert.Fail(StrSubstNo('Expected a Body element in the SOAP 1.1 envelope namespace directly under Envelope. Request body: %1', RequestBody));

        Doc.SelectNodes('/s:Envelope/s:Body/v:CheckVatRequest', NsMgr, Nodes);
        Assert.AreEqual(1, Nodes.Count(),
            StrSubstNo('Expected exactly one CheckVatRequest element in the namespace %1 inside Body. Request body: %2', VatNsLbl, RequestBody));

        if not Doc.SelectSingleNode('/s:Envelope/s:Body/v:CheckVatRequest/v:CountryCode', NsMgr, Node) then
            Assert.Fail(StrSubstNo('Expected a CountryCode element in the namespace %1 inside CheckVatRequest — an unprefixed child of a prefixed parent is in NO namespace, not the parent''s. Request body: %2', VatNsLbl, RequestBody));
        Assert.AreEqual(CountryCode, Node.AsXmlElement().InnerText(),
            'Expected the CountryCode element to carry the country code passed to CheckVat');

        if not Doc.SelectSingleNode('/s:Envelope/s:Body/v:CheckVatRequest/v:VatNumber', NsMgr, Node) then
            Assert.Fail(StrSubstNo('Expected a VatNumber element in the namespace %1 inside CheckVatRequest — an unprefixed child of a prefixed parent is in NO namespace, not the parent''s. Request body: %2', VatNsLbl, RequestBody));
        Assert.AreEqual(VatNumber, Node.AsXmlElement().InnerText(),
            'Expected the VatNumber element to carry the VAT number passed to CheckVat');
    end;

    local procedure SuccessBody(TraderName: Text; CountryCode: Text; VatNumber: Text): Text
    begin
        exit(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<soap:Envelope xmlns:soap="' + SoapEnvNsLbl + '">' +
            '<soap:Body>' +
            '<CheckVatResponse xmlns="' + VatNsLbl + '">' +
            '<CountryCode>' + CountryCode + '</CountryCode>' +
            '<VatNumber>' + VatNumber + '</VatNumber>' +
            '<TraderName>' + XmlEscape(TraderName) + '</TraderName>' +
            '</CheckVatResponse>' +
            '</soap:Body>' +
            '</soap:Envelope>');
    end;

    local procedure ShuffledSuccessBody(TraderName: Text): Text
    begin
        exit(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Envelope xmlns="' + SoapEnvNsLbl + '">' +
            '<Body>' +
            '<v:CheckVatResponse xmlns:v="' + VatNsLbl + '" xmlns:zz="urn:tryal:vat:other:v9">' +
            '<zz:TraderName>Decoy Trader - wrong namespace</zz:TraderName>' +
            '<v:TraderName>' + XmlEscape(TraderName) + '</v:TraderName>' +
            '</v:CheckVatResponse>' +
            '</Body>' +
            '</Envelope>');
    end;

    local procedure FaultBody(FaultString: Text): Text
    begin
        exit(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<soapenv:Envelope xmlns:soapenv="' + SoapEnvNsLbl + '">' +
            '<soapenv:Body>' +
            '<soapenv:Fault>' +
            '<faultcode>soapenv:Client</faultcode>' +
            '<faultstring>' + XmlEscape(FaultString) + '</faultstring>' +
            '</soapenv:Fault>' +
            '</soapenv:Body>' +
            '</soapenv:Envelope>');
    end;

    local procedure XmlEscape(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        exit(Value);
    end;
}
