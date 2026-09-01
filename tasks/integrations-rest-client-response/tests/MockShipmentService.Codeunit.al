// Stand-in for the carrier's booking API: records the request that
// "Shipment Booking Client" sends through the handler seam — method, URL,
// body and content type — and answers with the status, reason phrase and
// body the test scripted, or refuses to send at all.
codeunit 50901 "Mock Shipment Service" implements "Http Client Handler"
{
    var
        CapturedMethod: Text;
        CapturedUri: Text;
        CapturedBody: Text;
        CapturedContentType: Text;
        MockReasonPhrase: Text;
        MockBody: Text;
        FailSend: Boolean;
        MockStatusCode: Integer;
        RequestCount: Integer;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpContent: Codeunit "Http Content";
        NativeRequest: HttpRequestMessage;
        ContentHeaders: HttpHeaders;
        ContentTypeValues: List of [Text];
    begin
        RequestCount += 1;
        CapturedMethod := HttpRequestMessage.GetHttpMethod();
        CapturedUri := HttpRequestMessage.GetRequestUri();

        // Body and Content-Type live on the content of the native message the
        // wrapper carries, not on the wrapper's own header set.
        NativeRequest := HttpRequestMessage.GetHttpRequestMessage();
        if not NativeRequest.Content.ReadAs(CapturedBody) then
            CapturedBody := '';
        CapturedContentType := '';
        if NativeRequest.Content.GetHeaders(ContentHeaders) then
            if ContentHeaders.Contains('Content-Type') then begin
                ContentHeaders.GetValues('Content-Type', ContentTypeValues);
                if ContentTypeValues.Count() > 0 then
                    CapturedContentType := ContentTypeValues.Get(1);
            end;

        if FailSend then
            exit(false);

        HttpResponseMessage.SetHttpStatusCode(MockStatusCode);
        HttpResponseMessage.SetIsSuccessStatusCode(MockStatusCode in [200 .. 299]);
        HttpResponseMessage.SetReasonPhrase(MockReasonPhrase);
        HttpResponseMessage.SetContent(HttpContent.Create(MockBody));
        exit(true);
    end;

    procedure SetResponse(StatusCode: Integer; ReasonPhrase: Text; Body: Text)
    begin
        MockStatusCode := StatusCode;
        MockReasonPhrase := ReasonPhrase;
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

    procedure GetCapturedBody(): Text
    begin
        exit(CapturedBody);
    end;

    procedure GetCapturedContentType(): Text
    begin
        exit(CapturedContentType);
    end;

    procedure GetRequestCount(): Integer
    begin
        exit(RequestCount);
    end;
}
