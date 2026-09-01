codeunit 50100 "Event Hub Client"
{
    procedure SendEvent(Url: Text; Body: Text; ExtraHeaders: Dictionary of [Text, Text]; HttpClientHandler: Interface "Http Client Handler"): Boolean
    begin
        // TODO: build the POST request with the default headers, merge in
        // ExtraHeaders, route Content-Type to the right header collection,
        // and send everything through HttpClientHandler.
    end;
}
