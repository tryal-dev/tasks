codeunit 50900 "Event Hub Client Tests"
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
    procedure SendsExactlyOnePostRequestToTheGivenUrl()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExtraHeaders: Dictionary of [Text, Text];
        Url: Text;
    begin
        Url := 'https://hub.example.com/v1/events/' + Any.AlphabeticText(10);

        EventHubClient.SendEvent(Url, '{"type":"ping"}', ExtraHeaders, MockEventHub);

        Assert.AreEqual('POST', UpperCase(MockEventHub.GetCapturedMethod()),
            'Expected the request sent through the handler to use the POST method');
        Assert.AreEqual(Url, MockEventHub.GetCapturedUri(),
            'Expected the full request URL to be exactly the Url passed to SendEvent');
        Assert.AreEqual(1, MockEventHub.GetRequestCount(),
            'Expected exactly one request to reach the event hub for a single SendEvent call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsTheBodyUnchanged()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExtraHeaders: Dictionary of [Text, Text];
        Body: Text;
    begin
        Body := StrSubstNo('{"type":"%1"}', Any.AlphabeticText(12));

        EventHubClient.SendEvent('https://hub.example.com/v1/events', Body, ExtraHeaders, MockEventHub);

        Assert.AreEqual(Body, MockEventHub.GetCapturedBody(),
            'Expected the request body to be exactly the Body passed to SendEvent');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsTheDefaultHeadersOnEveryRequest()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        ExtraHeaders: Dictionary of [Text, Text];
    begin
        EventHubClient.SendEvent('https://hub.example.com/v1/events', '{"type":"ping"}', ExtraHeaders, MockEventHub);

        Assert.AreEqual('application/json', MockEventHub.GetRequestHeader('Accept'),
            'Expected every request to carry the default Accept header with exactly this one value');
        Assert.AreEqual('Business Central', MockEventHub.GetRequestHeader('X-Source-System'),
            'Expected every request to carry the default X-Source-System header with exactly this one value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoutesTheDefaultContentTypeToTheContentHeaders()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        ExtraHeaders: Dictionary of [Text, Text];
    begin
        EventHubClient.SendEvent('https://hub.example.com/v1/events', '{"type":"ping"}', ExtraHeaders, MockEventHub);

        Assert.AreEqual('application/json', MockEventHub.GetContentHeader('Content-Type'),
            'Expected the content headers to carry Content-Type application/json when ExtraHeaders is empty');
        Assert.IsFalse(MockEventHub.RequestHasHeader('Content-Type'),
            StrSubstNo('Expected Content-Type to stay off the request''s own headers — it travels with the content. The request headers carried Content-Type: %1',
                MockEventHub.GetRequestHeader('Content-Type')));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddsAnExtraHeaderAlongsideTheDefaults()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExtraHeaders: Dictionary of [Text, Text];
        CorrelationId: Text;
    begin
        CorrelationId := Any.AlphanumericText(16);
        ExtraHeaders.Add('X-Correlation-Id', CorrelationId);

        EventHubClient.SendEvent('https://hub.example.com/v1/events', '{"type":"ping"}', ExtraHeaders, MockEventHub);

        Assert.AreEqual(CorrelationId, MockEventHub.GetRequestHeader('X-Correlation-Id'),
            'Expected the per-call X-Correlation-Id header to be sent with exactly the value passed in ExtraHeaders');
        Assert.AreEqual('application/json', MockEventHub.GetRequestHeader('Accept'),
            'Expected the default Accept header to survive when an unrelated extra header is passed');
        Assert.AreEqual('Business Central', MockEventHub.GetRequestHeader('X-Source-System'),
            'Expected the default X-Source-System header to survive when an unrelated extra header is passed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnOverrideReplacesTheDefaultInsteadOfDuplicatingIt()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExtraHeaders: Dictionary of [Text, Text];
        AcceptOverride: Text;
    begin
        AcceptOverride := 'application/' + Any.AlphabeticText(8);
        ExtraHeaders.Add('Accept', AcceptOverride);

        EventHubClient.SendEvent('https://hub.example.com/v1/events', '{"type":"ping"}', ExtraHeaders, MockEventHub);

        Assert.AreEqual(AcceptOverride, MockEventHub.GetRequestHeader('Accept'),
            'Expected the Accept override to be the only Accept value on the wire — a duplicated header shows every value here');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnOverrideReplacesTheDefaultRegardlessOfCasing()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExtraHeaders: Dictionary of [Text, Text];
        AcceptOverride: Text;
        HeaderCasing: Text;
    begin
        AcceptOverride := 'application/' + Any.AlphabeticText(8);
        HeaderCasing := RandomCasingOf('Accept');
        ExtraHeaders.Add(HeaderCasing, AcceptOverride);

        EventHubClient.SendEvent('https://hub.example.com/v1/events', '{"type":"ping"}', ExtraHeaders, MockEventHub);

        Assert.AreEqual(AcceptOverride, MockEventHub.GetRequestHeader('Accept'),
            StrSubstNo('Expected the Accept override passed as %1 to replace the default Accept header even though its casing differs — and to be the only Accept value on the wire', HeaderCasing));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoutesAContentTypeOverrideToTheContentHeaders()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExtraHeaders: Dictionary of [Text, Text];
        ContentTypeOverride: Text;
    begin
        ContentTypeOverride := 'text/' + Any.AlphabeticText(6);
        ExtraHeaders.Add('Content-Type', ContentTypeOverride);

        EventHubClient.SendEvent('https://hub.example.com/v1/events', 'id;name', ExtraHeaders, MockEventHub);

        Assert.AreEqual(ContentTypeOverride, MockEventHub.GetContentHeader('Content-Type'),
            'Expected the Content-Type override to replace application/json on the content headers and to be the only value there');
        Assert.IsFalse(MockEventHub.RequestHasHeader('Content-Type'),
            StrSubstNo('Expected the Content-Type override to stay off the request''s own headers — it travels with the content. The request headers carried Content-Type: %1',
                MockEventHub.GetRequestHeader('Content-Type')));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AContentTypeOverrideIsRecognizedRegardlessOfCasing()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExtraHeaders: Dictionary of [Text, Text];
        ContentTypeOverride: Text;
        HeaderCasing: Text;
    begin
        ContentTypeOverride := 'text/' + Any.AlphabeticText(6);
        HeaderCasing := RandomCasingOf('Content-Type');
        ExtraHeaders.Add(HeaderCasing, ContentTypeOverride);

        EventHubClient.SendEvent('https://hub.example.com/v1/events', 'id;name', ExtraHeaders, MockEventHub);

        Assert.AreEqual(ContentTypeOverride, MockEventHub.GetContentHeader('Content-Type'),
            StrSubstNo('Expected a Content-Type override passed as %1 to replace the default content header — header names never compare case-sensitively', HeaderCasing));
        Assert.IsFalse(MockEventHub.RequestHasHeader('Content-Type'),
            StrSubstNo('Expected the Content-Type override passed as %1 to stay off the request''s own headers — it travels with the content. The request headers carried Content-Type: %2',
                HeaderCasing, MockEventHub.GetRequestHeader('Content-Type')));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTrueWhenTheEventHubAcceptsTheEvent()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        ExtraHeaders: Dictionary of [Text, Text];
    begin
        MockEventHub.SetResponseStatus(202);

        Assert.IsTrue(EventHubClient.SendEvent('https://hub.example.com/v1/events', '{"type":"ping"}', ExtraHeaders, MockEventHub),
            'Expected SendEvent to return true for a 202 response — any status in the 2xx class counts as accepted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheEventHubRejectsTheEvent()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        ExtraHeaders: Dictionary of [Text, Text];
    begin
        MockEventHub.SetResponseStatus(500);

        Assert.IsFalse(EventHubClient.SendEvent('https://hub.example.com/v1/events', '{"type":"ping"}', ExtraHeaders, MockEventHub),
            'Expected SendEvent to return false for an HTTP 500 response');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheRequestCannotBeSent()
    var
        MockEventHub: Codeunit "Mock Event Hub";
        EventHubClient: Codeunit "Event Hub Client";
        Assert: Codeunit Assert;
        ExtraHeaders: Dictionary of [Text, Text];
    begin
        MockEventHub.SetSendFailure();

        Assert.IsFalse(EventHubClient.SendEvent('https://hub.example.com/v1/events', '{"type":"ping"}', ExtraHeaders, MockEventHub),
            'Expected SendEvent to return false when the handler reports a transport failure — the request never reached the event hub');
    end;

    // Unpredictable casing defeats submissions that pattern-match the literal
    // spellings the statement mentions instead of comparing case-insensitively.
    local procedure RandomCasingOf(Name: Text): Text
    var
        Any: Codeunit Any;
        Randomized: Text;
        I: Integer;
    begin
        for I := 1 to StrLen(Name) do
            if Any.Boolean() then
                Randomized += CopyStr(Name, I, 1).ToUpper()
            else
                Randomized += CopyStr(Name, I, 1).ToLower();
        // The randomized name must actually differ in casing from the canonical
        // spelling, or the test would not exercise case-insensitivity at all.
        if Randomized = Name then
            Randomized := Name.ToLower();
        exit(Randomized);
    end;
}
