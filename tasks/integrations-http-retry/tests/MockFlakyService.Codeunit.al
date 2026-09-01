// Stand-in for the flaky endpoint: answers each request that "Resilient
// Http Client" sends through the handler seam with the next scripted status
// and records every request it sees.
codeunit 50901 "Mock Flaky Service" implements "Http Client Handler"
{
    var
        CapturedMethods: List of [Text];
        CapturedUris: List of [Text];
        ScriptedStatuses: List of [Integer];
        LastStatus: Integer;
        SuccessBody: Text;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpContent: Codeunit "Http Content";
        Status: Integer;
    begin
        CapturedMethods.Add(HttpRequestMessage.GetHttpMethod());
        CapturedUris.Add(HttpRequestMessage.GetRequestUri());

        // Requests beyond the script replay the last scripted status, so a
        // runaway retry loop terminates and fails the request-count assert
        // instead of erroring inside the mock.
        if ScriptedStatuses.Count() > 0 then begin
            Status := ScriptedStatuses.Get(1);
            ScriptedStatuses.RemoveAt(1);
            LastStatus := Status;
        end else
            Status := LastStatus;

        HttpResponseMessage.SetHttpStatusCode(Status);
        HttpResponseMessage.SetIsSuccessStatusCode(Status in [200 .. 299]);
        if Status in [200 .. 299] then
            HttpResponseMessage.SetContent(HttpContent.Create(SuccessBody))
        else
            HttpResponseMessage.SetContent(HttpContent.Create('{"error":"upstream failure - this body must never reach the caller"}'));
        exit(true);
    end;

    procedure ScriptStatus(StatusCode: Integer)
    begin
        ScriptedStatuses.Add(StatusCode);
    end;

    procedure SetSuccessBody(Body: Text)
    begin
        SuccessBody := Body;
    end;

    procedure GetRequestCount(): Integer
    begin
        exit(CapturedUris.Count());
    end;

    procedure GetCapturedMethod(Index: Integer): Text
    begin
        exit(CapturedMethods.Get(Index));
    end;

    procedure GetCapturedUri(Index: Integer): Text
    begin
        exit(CapturedUris.Get(Index));
    end;
}
