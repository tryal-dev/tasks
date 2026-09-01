// Stand-in for the TryAL VAT Registry gateway: records the request that
// "Vat Registry Client" sends through the handler seam — method, URI, body
// and both SOAP headers — and answers with whatever the test arranged.
codeunit 50901 "Mock Vat Registry" implements "Http Client Handler"
{
    var
        CapturedMethod: Text;
        CapturedUri: Text;
        CapturedBody: Text;
        CapturedContentType: Text;
        CapturedSoapAction: Text;
        SoapActionPresent: Boolean;
        FailSend: Boolean;
        MockStatusCode: Integer;
        MockBody: Text;
        RequestCount: Integer;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpContent: Codeunit "Http Content";
        NativeRequest: HttpRequestMessage;
        ContentHeaders: HttpHeaders;
        ContentTypeValues: List of [Text];
        SoapActionValues: List of [Text];
    begin
        RequestCount += 1;
        CapturedMethod := HttpRequestMessage.GetHttpMethod();
        CapturedUri := HttpRequestMessage.GetRequestUri();

        SoapActionValues := HttpRequestMessage.GetHeaderValues('SOAPAction');
        SoapActionPresent := SoapActionValues.Count() > 0;
        if SoapActionPresent then
            CapturedSoapAction := SoapActionValues.Get(1);

        // Content-Type lives on the content's headers, not the request's —
        // read it from the native message the wrapper carries.
        NativeRequest := HttpRequestMessage.GetHttpRequestMessage();
        if not NativeRequest.Content.ReadAs(CapturedBody) then
            CapturedBody := '';
        if NativeRequest.Content.GetHeaders(ContentHeaders) then
            if ContentHeaders.Contains('Content-Type') then begin
                ContentHeaders.GetValues('Content-Type', ContentTypeValues);
                CapturedContentType := ContentTypeValues.Get(1);
            end;

        if FailSend then
            exit(false);

        HttpResponseMessage.SetHttpStatusCode(MockStatusCode);
        HttpResponseMessage.SetIsSuccessStatusCode(MockStatusCode in [200 .. 299]);
        HttpResponseMessage.SetContent(HttpContent.Create(MockBody));
        exit(true);
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

    procedure GetRequestCount(): Integer
    begin
        exit(RequestCount);
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

    procedure HasSoapActionHeader(): Boolean
    begin
        exit(SoapActionPresent);
    end;

    procedure GetCapturedSoapAction(): Text
    begin
        exit(CapturedSoapAction);
    end;
}
