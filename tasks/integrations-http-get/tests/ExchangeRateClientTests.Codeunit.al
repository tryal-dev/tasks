codeunit 50900 "Exchange Rate Client Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // The mock answers requests sent through the handler interface; grading
    // containers have no outbound network, so a submission that bypasses the
    // seam with a raw HttpClient must fail loudly instead of hanging on a
    // dead socket.
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheRateFromASuccessfulResponse()
    var
        MockRateService: Codeunit "Mock Rate Service";
        ExchangeRateClient: Codeunit "Exchange Rate Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedRate: Decimal;
        Rate: Decimal;
    begin
        ExpectedRate := Any.DecimalInRange(1, 100, 4);
        MockRateService.SetResponse(200, RateBody('EUR', ExpectedRate));

        Assert.IsTrue(ExchangeRateClient.GetRate('EUR', MockRateService, Rate),
            'Expected GetRate to return true for a 200 response whose JSON body carries a rate property');
        Assert.AreEqual(ExpectedRate, Rate,
            'Expected Rate to be set to the number carried by the rate property of the JSON body');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsAGetRequest()
    var
        MockRateService: Codeunit "Mock Rate Service";
        ExchangeRateClient: Codeunit "Exchange Rate Client";
        Assert: Codeunit Assert;
        Rate: Decimal;
    begin
        MockRateService.SetResponse(200, RateBody('USD', 1.23));

        ExchangeRateClient.GetRate('USD', MockRateService, Rate);

        Assert.AreEqual('GET', UpperCase(MockRateService.GetCapturedMethod()),
            'Expected the request sent through the handler to use the GET method');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RequestsTheDocumentedUrlWithTheSymbolParameter()
    var
        MockRateService: Codeunit "Mock Rate Service";
        ExchangeRateClient: Codeunit "Exchange Rate Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Text;
        Rate: Decimal;
    begin
        CurrencyCode := UpperCase(Any.AlphabeticText(3));
        MockRateService.SetResponse(200, RateBody(CurrencyCode, 2.5));

        ExchangeRateClient.GetRate(CurrencyCode, MockRateService, Rate);

        Assert.AreEqual('https://rates.example.com/v1/latest?symbol=' + CurrencyCode, MockRateService.GetCapturedUri(),
            'Expected the full request URL to be exactly the documented endpoint with the currency code as the symbol query parameter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsExactlyOneRequestPerCall()
    var
        MockRateService: Codeunit "Mock Rate Service";
        ExchangeRateClient: Codeunit "Exchange Rate Client";
        Assert: Codeunit Assert;
        Rate: Decimal;
    begin
        MockRateService.SetResponse(200, RateBody('DKK', 0.13));

        ExchangeRateClient.GetRate('DKK', MockRateService, Rate);

        Assert.AreEqual(1, MockRateService.GetRequestCount(),
            'Expected exactly one request to reach the service for a single GetRate call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheRequestCannotBeSent()
    var
        MockRateService: Codeunit "Mock Rate Service";
    begin
        MockRateService.SetSendFailure();

        VerifyGetRateFails(MockRateService,
            'when the handler reports a transport failure — the request never reached the service');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheServiceRespondsNotFound()
    var
        MockRateService: Codeunit "Mock Rate Service";
    begin
        // The 404 body deliberately carries a parseable rate — checking the
        // status code AFTER parsing must not rescue the call.
        MockRateService.SetResponse(404, RateBody('EUR', 999.99));

        VerifyGetRateFails(MockRateService,
            'for an HTTP 404 response, even though its diagnostic body contains a rate property — the status code decides, not the body');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheServiceRespondsServerError()
    var
        MockRateService: Codeunit "Mock Rate Service";
    begin
        MockRateService.SetResponse(500, RateBody('EUR', 999.99));

        VerifyGetRateFails(MockRateService,
            'for an HTTP 500 response, even though its diagnostic body contains a rate property — the status code decides, not the body');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheBodyIsNotJson()
    var
        MockRateService: Codeunit "Mock Rate Service";
    begin
        MockRateService.SetResponse(200, '<html>Service under maintenance</html>');

        VerifyGetRateFails(MockRateService,
            'for a 200 response whose body is not valid JSON — and the procedure must not raise an error either');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheRatePropertyIsMissing()
    var
        MockRateService: Codeunit "Mock Rate Service";
    begin
        MockRateService.SetResponse(200, BodyWithoutRate('EUR'));

        VerifyGetRateFails(MockRateService,
            'for a 200 response whose JSON body has no rate property');
    end;

    local procedure VerifyGetRateFails(MockRateService: Codeunit "Mock Rate Service"; FailureContext: Text)
    var
        ExchangeRateClient: Codeunit "Exchange Rate Client";
        Assert: Codeunit Assert;
        Rate: Decimal;
    begin
        Rate := -1;

        Assert.IsFalse(ExchangeRateClient.GetRate('EUR', MockRateService, Rate),
            StrSubstNo('Expected GetRate to return false %1', FailureContext));
        Assert.AreEqual(0, Rate,
            StrSubstNo('Expected Rate to end up 0 when GetRate returns false (it was preset to -1) %1', FailureContext));
        Assert.AreEqual(1, MockRateService.GetRequestCount(),
            StrSubstNo('Expected exactly one request through the handler — no retries — %1', FailureContext));
    end;

    local procedure RateBody(Symbol: Text; RateValue: Decimal): Text
    var
        Payload: JsonObject;
        Body: Text;
    begin
        Payload.Add('symbol', Symbol);
        Payload.Add('rate', RateValue);
        Payload.Add('asOf', '2026-07-15');
        Payload.WriteTo(Body);
        exit(Body);
    end;

    local procedure BodyWithoutRate(Symbol: Text): Text
    var
        Payload: JsonObject;
        Body: Text;
    begin
        Payload.Add('symbol', Symbol);
        Payload.Add('asOf', '2026-07-15');
        Payload.WriteTo(Body);
        exit(Body);
    end;
}
