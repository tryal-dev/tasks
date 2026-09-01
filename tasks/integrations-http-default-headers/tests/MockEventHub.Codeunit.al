// Stand-in for the event hub: records the request that "Event Hub Client"
// sends through the handler seam — method, URL, body, and the final request
// and content header sets — and answers with the scripted status.
codeunit 50901 "Mock Event Hub" implements "Http Client Handler"
{
    var
        // Header name (upper-cased) -> all values, comma-joined, so a
        // duplicated header surfaces both values in a failure message.
        CapturedRequestHeaders: Dictionary of [Text, Text];
        CapturedContentHeaders: Dictionary of [Text, Text];
        CapturedMethod: Text;
        CapturedUri: Text;
        CapturedBody: Text;
        MockStatusCode: Integer;
        FailSend: Boolean;
        RequestCount: Integer;

    procedure Send(CurrHttpClientInstance: HttpClient; RequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpContent: Codeunit "Http Content";
        NativeRequest: HttpRequestMessage;
        NativeContent: HttpContent;
        Headers: HttpHeaders;
    begin
        RequestCount += 1;
        CapturedMethod := RequestMessage.GetHttpMethod();
        CapturedUri := RequestMessage.GetRequestUri();

        NativeRequest := RequestMessage.GetHttpRequestMessage();
        NativeRequest.GetHeaders(Headers);
        CaptureHeaders(Headers, CapturedRequestHeaders);
        // A client may set its defaults on the HttpClient instead of the request
        // message; on the real wire those are sent too, unless the request already
        // carries a header of the same name. Mirror that merge so both placements
        // are graded on what would actually have gone out.
        MergeMissingHeaders(CurrHttpClientInstance.DefaultRequestHeaders(), CapturedRequestHeaders);

        NativeContent := NativeRequest.Content();
        if NativeContent.GetHeaders(Headers) then
            CaptureHeaders(Headers, CapturedContentHeaders);
        if not NativeContent.ReadAs(CapturedBody) then
            CapturedBody := '';

        if FailSend then
            exit(false);

        if MockStatusCode = 0 then
            MockStatusCode := 202;
        HttpResponseMessage.SetHttpStatusCode(MockStatusCode);
        HttpResponseMessage.SetIsSuccessStatusCode(MockStatusCode in [200 .. 299]);
        HttpResponseMessage.SetContent(HttpContent.Create('{"accepted":true}'));
        exit(true);
    end;

    local procedure CaptureHeaders(Headers: HttpHeaders; var Captured: Dictionary of [Text, Text])
    begin
        Clear(Captured);
        MergeMissingHeaders(Headers, Captured);
    end;

    local procedure MergeMissingHeaders(Headers: HttpHeaders; var Captured: Dictionary of [Text, Text])
    var
        Name: Text;
        Value: Text;
        JoinedValues: Text;
        Values: List of [Text];
    begin
        foreach Name in Headers.Keys() do
            if not Captured.ContainsKey(Name.ToUpper()) then begin
                Clear(Values);
                if Headers.GetValues(Name, Values) then begin
                    JoinedValues := '';
                    foreach Value in Values do begin
                        if JoinedValues <> '' then
                            JoinedValues += ', ';
                        JoinedValues += Value;
                    end;
                    Captured.Set(Name.ToUpper(), JoinedValues);
                end;
            end;
    end;

    procedure SetResponseStatus(StatusCode: Integer)
    begin
        MockStatusCode := StatusCode;
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

    procedure GetRequestCount(): Integer
    begin
        exit(RequestCount);
    end;

    procedure RequestHasHeader(Name: Text): Boolean
    begin
        exit(CapturedRequestHeaders.ContainsKey(Name.ToUpper()));
    end;

    // All values of the request header, comma-joined; '' when absent.
    procedure GetRequestHeader(Name: Text): Text
    var
        JoinedValues: Text;
    begin
        if CapturedRequestHeaders.Get(Name.ToUpper(), JoinedValues) then
            exit(JoinedValues);
        exit('');
    end;

    // All values of the content header, comma-joined; '' when absent.
    procedure GetContentHeader(Name: Text): Text
    var
        JoinedValues: Text;
    begin
        if CapturedContentHeaders.Get(Name.ToUpper(), JoinedValues) then
            exit(JoinedValues);
        exit('');
    end;
}
