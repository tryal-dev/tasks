// Stand-in for the rate service: records the request that "Exchange Rate
// Client" sends through the handler seam and answers with whatever the
// test arranged.
codeunit 50901 "Mock Rate Service" implements "Http Client Handler"
{
    var
        CapturedMethod: Text;
        CapturedUri: Text;
        MockBody: Text;
        FailSend: Boolean;
        MockStatusCode: Integer;
        RequestCount: Integer;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpContent: Codeunit "Http Content";
    begin
        RequestCount += 1;
        CapturedMethod := HttpRequestMessage.GetHttpMethod();
        CapturedUri := HttpRequestMessage.GetRequestUri();

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

    procedure GetCapturedMethod(): Text
    begin
        exit(CapturedMethod);
    end;

    procedure GetCapturedUri(): Text
    begin
        exit(CapturedUri);
    end;

    procedure GetRequestCount(): Integer
    begin
        exit(RequestCount);
    end;
}
