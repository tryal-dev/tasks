// Grading tests for "Shipment Booking Client": the mock carrier answers every
// request the client sends through the handler seam, so the whole scripted
// range — success, RFC 7807 refusals, a body that is not a problem document
// at all, and a send that never leaves the building — is graded without a
// network (the grading container has none).
codeunit 50900 "Shipment Booking Client Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheStatusOfALookedUpShipment()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShipmentNo: Text;
        ExpectedStatus: Text;
    begin
        ShipmentNo := 'S-' + Any.AlphanumericText(6);
        ExpectedStatus := Any.AlphabeticText(10);
        MockShipmentService.SetResponse(200, 'OK', ShipmentBody(ShipmentNo, ExpectedStatus));

        Assert.AreEqual(ExpectedStatus, ShipmentBookingClient.GetShipmentStatus(ShipmentNo, MockShipmentService),
            'Expected GetShipmentStatus to return the status property of the JSON body the service answered with');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LooksUpAShipmentWithOneGetRequestToTheDocumentedUrl()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShipmentNo: Text;
    begin
        ShipmentNo := 'S-' + Any.AlphanumericText(6);
        MockShipmentService.SetResponse(200, 'OK', ShipmentBody(ShipmentNo, 'in transit'));

        ShipmentBookingClient.GetShipmentStatus(ShipmentNo, MockShipmentService);

        Assert.AreEqual('GET', UpperCase(MockShipmentService.GetCapturedMethod()),
            'Expected the lookup to be sent through the handler as a GET request');
        Assert.AreEqual('https://ship.example.com/api/v1/shipments/' + ShipmentNo, MockShipmentService.GetCapturedUri(),
            'Expected the full request URL to be exactly the documented shipment endpoint with the shipment number appended');
        Assert.AreEqual(1, MockShipmentService.GetRequestCount(),
            'Expected exactly one request to reach the service for a single GetShipmentStatus call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheShipmentNoOfANewlyBookedShipment()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedShipmentNo: Text;
    begin
        ExpectedShipmentNo := 'S-' + Any.AlphanumericText(6);
        // 201 Created is a success status too — only the 2xx range decides.
        MockShipmentService.SetResponse(201, 'Created', ShipmentBody(ExpectedShipmentNo, 'booked'));

        Assert.AreEqual(ExpectedShipmentNo, ShipmentBookingClient.BookShipment('C-' + Any.AlphanumericText(5), MockShipmentService),
            'Expected BookShipment to return the shipmentNo property of the JSON body of the 201 response');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BooksAShipmentWithOnePostRequestToTheDocumentedUrl()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        MockShipmentService.SetResponse(201, 'Created', ShipmentBody('S-1001', 'booked'));

        ShipmentBookingClient.BookShipment('C-' + Any.AlphanumericText(5), MockShipmentService);

        Assert.AreEqual('POST', UpperCase(MockShipmentService.GetCapturedMethod()),
            'Expected the booking to be sent through the handler as a POST request');
        Assert.AreEqual('https://ship.example.com/api/v1/shipments', MockShipmentService.GetCapturedUri(),
            'Expected the full request URL to be exactly the documented shipments endpoint, with no customer number appended to it');
        Assert.AreEqual(1, MockShipmentService.GetRequestCount(),
            'Expected exactly one request to reach the service for a single BookShipment call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsTheCustomerNoInAJsonBookingBody()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SentBody: JsonObject;
        CustomerNo: Text;
    begin
        CustomerNo := 'C-' + Any.AlphanumericText(5);
        MockShipmentService.SetResponse(201, 'Created', ShipmentBody('S-1001', 'booked'));

        ShipmentBookingClient.BookShipment(CustomerNo, MockShipmentService);

        Assert.IsTrue(SentBody.ReadFrom(MockShipmentService.GetCapturedBody()),
            StrSubstNo('Expected the booking request body to be a JSON object, got %1', MockShipmentService.GetCapturedBody()));
        Assert.AreEqual(CustomerNo, PropertyText(SentBody, 'customerNo'),
            'Expected the booking request body to carry the customer number in its customerNo property');
        Assert.IsTrue(LowerCase(MockShipmentService.GetCapturedContentType()).StartsWith('application/json'),
            StrSubstNo('Expected the booking request to be sent as application/json, got the content type %1',
                MockShipmentService.GetCapturedContentType()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SurfacesTitleAndDetailOfARefusedLookup()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShipmentNo: Text;
        ReasonPhrase: Text;
        Title: Text;
        Detail: Text;
        ActualError: Text;
    begin
        ShipmentNo := 'S-' + Any.AlphanumericText(6);
        // The reason phrase is generated, not the canonical one for 404: the
        // status line has to be read off the response, never looked up in a
        // table of well-known status codes.
        ReasonPhrase := Any.AlphabeticText(9);
        Title := StrSubstNo('Shipment %1 not found', ShipmentNo);
        Detail := StrSubstNo('Carrier %1 has no record of this shipment.', Any.AlphabeticText(8));
        MockShipmentService.SetResponse(404, ReasonPhrase, ProblemBody(404, Title, Detail));

        asserterror ShipmentBookingClient.GetShipmentStatus(ShipmentNo, MockShipmentService);
        ActualError := GetLastErrorText();

        Assert.AreEqual(StrSubstNo('404 %1 | %2 | %3', ReasonPhrase, Title, Detail), ActualError,
            'Expected the refusal to be surfaced as one error: the status line, the title and the detail of the problem document, joined with " | "');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SurfacesEveryFieldErrorOfARejectedBooking()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Text;
        ReasonPhrase: Text;
        Title: Text;
        Detail: Text;
        FirstMessage: Text;
        SecondMessage: Text;
        ActualError: Text;
    begin
        CustomerNo := 'C-' + Any.AlphanumericText(5);
        ReasonPhrase := Any.AlphabeticText(11);
        Title := StrSubstNo('Booking rejected for %1', CustomerNo);
        Detail := 'The booking request has invalid fields.';
        FirstMessage := StrSubstNo('%1 is not a known customer', CustomerNo);
        SecondMessage := StrSubstNo('must be one of %1', Any.AlphabeticText(6));
        MockShipmentService.SetResponse(422, ReasonPhrase,
            ValidationProblemBody(422, Title, Detail, 'customerNo', FirstMessage, 'serviceLevel', SecondMessage));

        asserterror ShipmentBookingClient.BookShipment(CustomerNo, MockShipmentService);
        ActualError := GetLastErrorText();

        Assert.AreEqual(
            StrSubstNo('422 %1 | %2 | %3 | customerNo: %4 | serviceLevel: %5', ReasonPhrase, Title, Detail, FirstMessage, SecondMessage),
            ActualError,
            'Expected every entry of the errors array to be appended to the error, in order, as "<field>: <message>" parts joined with " | "');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesOutThePartsTheProblemDocumentOmits()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShipmentNo: Text;
        ReasonPhrase: Text;
        Title: Text;
        ActualError: Text;
    begin
        ShipmentNo := 'S-' + Any.AlphanumericText(6);
        ReasonPhrase := Any.AlphabeticText(8);
        Title := StrSubstNo('Shipment %1 was already collected', ShipmentNo);
        MockShipmentService.SetResponse(409, ReasonPhrase, ProblemBody(409, Title, ''));

        asserterror ShipmentBookingClient.GetShipmentStatus(ShipmentNo, MockShipmentService);
        ActualError := GetLastErrorText();

        Assert.AreEqual(StrSubstNo('409 %1 | %2', ReasonPhrase, Title), ActualError,
            'Expected a problem document without a detail to produce two parts only — no empty part and no trailing separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesOutTheTitleWhenTheProblemDocumentHasNone()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ReasonPhrase: Text;
        Detail: Text;
        ActualError: Text;
    begin
        ReasonPhrase := Any.AlphabeticText(7);
        Detail := StrSubstNo('Customer %1 is blocked for new bookings.', Any.AlphanumericText(5));
        MockShipmentService.SetResponse(403, ReasonPhrase, ProblemBody(403, '', Detail));

        asserterror ShipmentBookingClient.BookShipment('C-' + Any.AlphanumericText(5), MockShipmentService);
        ActualError := GetLastErrorText();

        Assert.AreEqual(StrSubstNo('403 %1 | %2', ReasonPhrase, Detail), ActualError,
            'Expected a problem document without a title to produce the status line and the detail only — no empty part and no doubled separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsTheStatusAloneWhenTheFailureBodyIsNotAProblemDocument()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ReasonPhrase: Text;
        ActualError: Text;
    begin
        // The gateway in front of the carrier answers with an HTML page: reading
        // this body as JSON blows up, and the status the user needs is lost.
        ReasonPhrase := Any.AlphabeticText(12);
        MockShipmentService.SetResponse(500, ReasonPhrase, '<html><body>The service is temporarily unavailable</body></html>');

        asserterror ShipmentBookingClient.BookShipment('C-' + Any.AlphanumericText(5), MockShipmentService);
        ActualError := GetLastErrorText();

        Assert.AreEqual(StrSubstNo('500 %1', ReasonPhrase), ActualError,
            'Expected a failure body that is not a JSON object to leave the status line as the whole error — and never to raise a parsing error instead');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsAnUnreachableServiceWhenTheLookupCannotBeSent()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ActualError: Text;
    begin
        MockShipmentService.SetSendFailure();

        asserterror ShipmentBookingClient.GetShipmentStatus('S-' + Any.AlphanumericText(6), MockShipmentService);
        ActualError := GetLastErrorText();

        Assert.AreEqual('The shipment service could not be reached.', ActualError,
            'Expected a lookup whose request never reached the service to fail with exactly the unreachable-service sentence, not with the message the platform raised');
        Assert.AreEqual(1, MockShipmentService.GetRequestCount(),
            'Expected exactly one attempt to reach the service — a failed send is not retried');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsAnUnreachableServiceWhenTheBookingCannotBeSent()
    var
        MockShipmentService: Codeunit "Mock Shipment Service";
        ShipmentBookingClient: Codeunit "Shipment Booking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ActualError: Text;
    begin
        MockShipmentService.SetSendFailure();

        asserterror ShipmentBookingClient.BookShipment('C-' + Any.AlphanumericText(5), MockShipmentService);
        ActualError := GetLastErrorText();

        Assert.AreEqual('The shipment service could not be reached.', ActualError,
            'Expected a booking whose request never reached the service to fail with exactly the unreachable-service sentence, not with the message the platform raised');
        Assert.AreEqual(1, MockShipmentService.GetRequestCount(),
            'Expected exactly one attempt to reach the service — a failed send is not retried');
    end;

    local procedure ShipmentBody(ShipmentNo: Text; Status: Text): Text
    var
        Payload: JsonObject;
        Body: Text;
    begin
        Payload.Add('shipmentNo', ShipmentNo);
        Payload.Add('status', Status);
        Payload.Add('carrier', 'TryAL Express');
        Payload.WriteTo(Body);
        exit(Body);
    end;

    local procedure ProblemBody(StatusCode: Integer; Title: Text; Detail: Text): Text
    var
        Problem: JsonObject;
        Body: Text;
    begin
        Problem.Add('type', 'https://ship.example.com/problems/shipment');
        if Title <> '' then
            Problem.Add('title', Title);
        Problem.Add('status', StatusCode);
        if Detail <> '' then
            Problem.Add('detail', Detail);
        Problem.WriteTo(Body);
        exit(Body);
    end;

    local procedure ValidationProblemBody(StatusCode: Integer; Title: Text; Detail: Text; FirstField: Text; FirstMessage: Text; SecondField: Text; SecondMessage: Text): Text
    var
        Problem: JsonObject;
        FieldErrors: JsonArray;
        Body: Text;
    begin
        Problem.Add('type', 'https://ship.example.com/problems/validation');
        Problem.Add('title', Title);
        Problem.Add('status', StatusCode);
        Problem.Add('detail', Detail);
        FieldErrors.Add(FieldError(FirstField, FirstMessage));
        FieldErrors.Add(FieldError(SecondField, SecondMessage));
        Problem.Add('errors', FieldErrors);
        Problem.WriteTo(Body);
        exit(Body);
    end;

    local procedure FieldError(FieldName: Text; ErrorMessage: Text): JsonObject
    var
        Entry: JsonObject;
    begin
        Entry.Add('field', FieldName);
        Entry.Add('message', ErrorMessage);
        exit(Entry);
    end;

    local procedure PropertyText(Payload: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Payload.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        exit(Token.AsValue().AsText());
    end;
}
