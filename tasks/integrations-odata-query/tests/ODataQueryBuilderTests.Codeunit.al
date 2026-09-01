// Grading tests for integrations-odata-query.
//
// Every URL is compared character for character: the OData expression, the
// order of the query options, the percent-encoding of the values, and the
// literal "$" in front of each option name.
codeunit 50900 "OData Query Builder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // Grading containers have no outbound network: a submission that bypasses
    // the handler seam with a raw HttpClient must fail loudly instead of
    // hanging on a dead socket.
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerUrlBuildsTheDateWindowFilter()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A plain customer name and a date window become one $filter with three parenthesized comparisons
        Assert.AreEqual(
            EndpointTok + '?$filter=%28CustomerName%20eq%20%27Fabrikam%27%29%20and%20%28OrderDate%20ge%202026-01-01%29%20and%20%28OrderDate%20le%202026-03-31%29',
            QueryBuilder.OrdersByCustomerUrl('Fabrikam', 20260101D, 20260331D),
            'Expected one $filter option holding (CustomerName eq ''Fabrikam'') and (OrderDate ge 2026-01-01) and (OrderDate le 2026-03-31), percent-encoded, with $ left unencoded');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerUrlDoublesSingleQuotesInTheName()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A single quote inside the customer name is doubled so it cannot close the OData string value
        Assert.AreEqual(
            EndpointTok + '?$filter=%28CustomerName%20eq%20%27O%27%27Brien%20Foods%27%29%20and%20%28OrderDate%20ge%202026-06-01%29%20and%20%28OrderDate%20le%202026-06-30%29',
            QueryBuilder.OrdersByCustomerUrl('O''Brien Foods', 20260601D, 20260630D),
            'Expected the quote in O''Brien Foods to be doubled inside the OData value, so %27O%27%27Brien%20Foods%27 reaches the service');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerUrlWritesZeroPaddedIsoDates()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Single-digit months and days are zero-padded and ordered year-month-day, never locale-formatted
        Assert.AreEqual(
            EndpointTok + '?$filter=%28CustomerName%20eq%20%27Adatum%27%29%20and%20%28OrderDate%20ge%202026-02-03%29%20and%20%28OrderDate%20le%202026-11-09%29',
            QueryBuilder.OrdersByCustomerUrl('Adatum', 20260203D, 20261109D),
            'Expected 3 February 2026 to be written as 2026-02-03 and 9 November 2026 as 2026-11-09 - bare, unquoted, zero-padded ISO dates');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerUrlEncodesNonAsciiLettersFromTheirUtf8Bytes()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A name with non-ASCII letters is percent-encoded byte by byte, not character by character
        Assert.AreEqual(
            EndpointTok + '?$filter=%28CustomerName%20eq%20%27M%C3%A5ns%20%C3%98%20AS%27%29%20and%20%28OrderDate%20ge%202026-01-01%29%20and%20%28OrderDate%20le%202026-01-31%29',
            QueryBuilder.OrdersByCustomerUrl('Måns Ø AS', 20260101D, 20260131D),
            'Expected each non-ASCII letter to be encoded from its UTF-8 bytes with uppercase hex (å = %C3%A5, Ø = %C3%98) - a hand-rolled escaper that only knows the ASCII punctuation of the worked examples fails here');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerUrlHandlesGeneratedNameAndDates()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerName: Text;
        FromDate: Date;
        ToDate: Date;
    begin
        // [SCENARIO] A generated name and generated dates are reproduced exactly, so hardcoding the worked example fails
        CustomerName := Any.AlphabeticText(12);
        FromDate := Any.DateInRange(20260101D, 1, 100);
        ToDate := Any.DateInRange(FromDate, 1, 200);

        Assert.AreEqual(
            EndpointTok + '?$filter=%28CustomerName%20eq%20%27' + CustomerName + '%27%29%20and%20%28OrderDate%20ge%20' + IsoDate(FromDate) + '%29%20and%20%28OrderDate%20le%20' + IsoDate(ToDate) + '%29',
            QueryBuilder.OrdersByCustomerUrl(CustomerName, FromDate, ToDate),
            'Expected the generated customer name and the two generated dates to appear in the $filter exactly as passed in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SearchUrlGroupsTheContainsAlternatives()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The status test is ANDed with a parenthesized OR of the two contains() calls, followed by $top
        Assert.AreEqual(
            EndpointTok + '?$filter=%28Status%20eq%20%27Open%27%29%20and%20%28%28contains%28CustomerName%2C%27sea%20salt%27%29%29%20or%20%28contains%28ExternalDocumentNo%2C%27sea%20salt%27%29%29%29&$top=20',
            QueryBuilder.OpenOrderSearchUrl('sea salt', 20),
            'Expected the status test ANDed with a parenthesized OR of the two contains() calls, then $top=20 after the filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SearchUrlDoublesSingleQuotesInTheSearchText()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The quote-doubling rule applies to the search text inside both contains() calls
        Assert.AreEqual(
            EndpointTok + '?$filter=%28Status%20eq%20%27Open%27%29%20and%20%28%28contains%28CustomerName%2C%27O%27%27Neill%27%29%29%20or%20%28contains%28ExternalDocumentNo%2C%27O%27%27Neill%27%29%29%29&$top=5',
            QueryBuilder.OpenOrderSearchUrl('O''Neill', 5),
            'Expected the quote in O''Neill to be doubled inside BOTH contains() calls before encoding');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SearchUrlHandlesGeneratedTextAndRowLimit()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
        MaxRows: Integer;
    begin
        // [SCENARIO] A generated search text and row limit are reproduced exactly, so hardcoding the worked example fails
        SearchText := Any.AlphabeticText(9);
        MaxRows := Any.IntegerInRange(1, 999);

        Assert.AreEqual(
            EndpointTok + '?$filter=%28Status%20eq%20%27Open%27%29%20and%20%28%28contains%28CustomerName%2C%27' + SearchText + '%27%29%29%20or%20%28contains%28ExternalDocumentNo%2C%27' + SearchText + '%27%29%29%29&$top=' + Format(MaxRows),
            QueryBuilder.OpenOrderSearchUrl(SearchText, MaxRows),
            'Expected the generated search text in both contains() calls and the generated row limit as plain digits in $top');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecentOrdersUrlAddsSelectOrderByAndTop()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] $select, $orderby and $top appear in that order, with their values encoded as data
        Assert.AreEqual(
            EndpointTok + '?$select=Number%2CCustomerName%2COrderDate%2CAmount&$orderby=OrderDate%20desc&$top=25',
            QueryBuilder.RecentOrdersUrl(25),
            'Expected $select then $orderby then $top, with the commas of the field list encoded as %2C and the space before desc as %20');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecentOrdersUrlHandlesAGeneratedRowCount()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        RowCount: Integer;
    begin
        // [SCENARIO] The row count reaches $top as plain digits, whatever it is
        RowCount := Any.IntegerInRange(1, 5000);

        Assert.AreEqual(
            EndpointTok + '?$select=Number%2CCustomerName%2COrderDate%2CAmount&$orderby=OrderDate%20desc&$top=' + Format(RowCount),
            QueryBuilder.RecentOrdersUrl(RowCount),
            'Expected the generated row count to appear as plain digits in $top');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QueryOptionNamesKeepTheDollarSignUnencoded()
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
        Url: Text;
    begin
        // [SCENARIO] The $ of every query option name survives as a literal $ - the service never decodes option names
        Url := QueryBuilder.RecentOrdersUrl(10);

        Assert.AreEqual(0, StrPos(Url, '%24'),
            'Expected no %24 anywhere in the URL: the service reads $select, $orderby and $top only when the $ arrives unencoded. The URL was ' + Url);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FetchSendsTheBuiltUrlToTheService()
    var
        MockOrderService: Codeunit "Mock Order Service";
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        // [SCENARIO] The URL handed to Fetch reaches the service unchanged, encoding and all
        MockOrderService.SetResponse(200, OrderPayloadTok);

        QueryBuilder.Fetch(QueryBuilder.OrdersByCustomerUrl('Contoso Ltd.', 20260101D, 20260131D), MockOrderService, ResponseBody);

        Assert.AreEqual(
            EndpointTok + '?$filter=%28CustomerName%20eq%20%27Contoso%20Ltd.%27%29%20and%20%28OrderDate%20ge%202026-01-01%29%20and%20%28OrderDate%20le%202026-01-31%29',
            MockOrderService.GetCapturedUri(),
            'Expected the request that reaches the service to carry exactly the URL that was passed to Fetch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FetchSendsAGetRequest()
    var
        MockOrderService: Codeunit "Mock Order Service";
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        // [SCENARIO] An OData query is read with GET
        MockOrderService.SetResponse(200, OrderPayloadTok);

        QueryBuilder.Fetch(QueryBuilder.RecentOrdersUrl(5), MockOrderService, ResponseBody);

        Assert.AreEqual('GET', UpperCase(MockOrderService.GetCapturedMethod()),
            'Expected the request sent through the handler to use the GET method');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FetchReturnsTheResponseBody()
    var
        MockOrderService: Codeunit "Mock Order Service";
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        // [SCENARIO] A success status yields true and the untouched response body
        MockOrderService.SetResponse(200, OrderPayloadTok);

        Assert.IsTrue(QueryBuilder.Fetch(QueryBuilder.RecentOrdersUrl(5), MockOrderService, ResponseBody),
            'Expected Fetch to return true when the service answers with status 200');
        Assert.AreEqual(OrderPayloadTok, ResponseBody,
            'Expected ResponseBody to hold the response payload exactly as the service sent it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FetchReturnsFalseWhenTheServiceRejectsTheQuery()
    var
        MockOrderService: Codeunit "Mock Order Service";
    begin
        // [SCENARIO] A 400 answer is a failure, even though its diagnostic body would parse fine
        MockOrderService.SetResponse(400, OrderPayloadTok);

        VerifyFetchFails(MockOrderService, 'when the service answers with status 400 - the status decides, not the body');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FetchReturnsFalseWhenTheRequestCannotBeSent()
    var
        MockOrderService: Codeunit "Mock Order Service";
    begin
        // [SCENARIO] The handler's verdict decides, even though the response object it hands back reads as a usable 200
        MockOrderService.SetResponse(200, OrderPayloadTok);
        MockOrderService.SetSendFailure();

        VerifyFetchFails(MockOrderService, 'when the handler reports a transport failure - the request never reached the service, whatever the response object says');
    end;

    local procedure VerifyFetchFails(var MockOrderService: Codeunit "Mock Order Service"; FailureContext: Text)
    var
        QueryBuilder: Codeunit "OData Query Builder";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        ResponseBody := 'PRESET';

        Assert.IsFalse(QueryBuilder.Fetch(QueryBuilder.RecentOrdersUrl(5), MockOrderService, ResponseBody),
            StrSubstNo('Expected Fetch to return false %1', FailureContext));
        Assert.AreEqual('', ResponseBody,
            StrSubstNo('Expected ResponseBody to end up empty (it was preset to PRESET) %1', FailureContext));
    end;

    local procedure IsoDate(Value: Date): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    var
        EndpointTok: Label 'https://api.contoso-orders.example/odata/v4/SalesOrders', Locked = true;
        OrderPayloadTok: Label '{"value":[{"Number":"SO-1001","Amount":250.0}]}', Locked = true;
}

// Stand-in for the partner's OData service: records the request that
// "OData Query Builder" sends through the handler seam and answers with
// whatever the test arranged.
codeunit 50901 "Mock Order Service" implements "Http Client Handler"
{
    var
        CapturedMethod: Text;
        CapturedUri: Text;
        MockBody: Text;
        FailSend: Boolean;
        MockStatusCode: Integer;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpContent: Codeunit "Http Content";
    begin
        CapturedMethod := HttpRequestMessage.GetHttpMethod();
        CapturedUri := HttpRequestMessage.GetRequestUri();

        // The response is filled in even when the send is reported as failed, so
        // the two false-paths of Fetch cannot be satisfied by one check: a
        // submission that ignores Send's Boolean sees a usable 200 here.
        HttpResponseMessage.SetHttpStatusCode(MockStatusCode);
        HttpResponseMessage.SetIsSuccessStatusCode(MockStatusCode in [200 .. 299]);
        HttpResponseMessage.SetContent(HttpContent.Create(MockBody));

        exit(not FailSend);
    end;

    procedure SetResponse(StatusCode: Integer; Body: Text)
    begin
        MockStatusCode := StatusCode;
        MockBody := Body;
        FailSend := false;
    end;

    procedure SetSendFailure()
    begin
        FailSend := true;
    end;

    procedure GetCapturedMethod(): Text
    begin
        exit(CapturedMethod);
    end;

    procedure GetCapturedUri(): Text
    begin
        exit(CapturedUri);
    end;
}
