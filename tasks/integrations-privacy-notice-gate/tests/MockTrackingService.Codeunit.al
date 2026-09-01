// Stand-in for the parcel-tracking endpoint: answers every request that
// "Parcel Tracking Client" sends through the handler seam with a canned 200
// and records what it saw, so the tests can count requests that should never
// have left the building.
codeunit 50901 "Mock Tracking Service" implements "Http Client Handler"
{
    var
        CapturedMethods: List of [Text];
        CapturedUris: List of [Text];
        CannedBody: Text;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpContent: Codeunit "Http Content";
    begin
        CapturedMethods.Add(HttpRequestMessage.GetHttpMethod());
        CapturedUris.Add(HttpRequestMessage.GetRequestUri());

        HttpResponseMessage.SetHttpStatusCode(200);
        HttpResponseMessage.SetIsSuccessStatusCode(true);
        HttpResponseMessage.SetContent(HttpContent.Create(CannedBody));
        exit(true);
    end;

    procedure SetResponseBody(Body: Text)
    begin
        CannedBody := Body;
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
