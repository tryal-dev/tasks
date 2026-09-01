# Call a REST API (Mocked)

Your company subscribes to a currency-rate service, and the finance team wants those rates inside Business Central. Real services misbehave — they go down, answer with error statuses, and ship bodies you did not expect — so your client codeunit has to survive all of that without ever crashing the code that calls it.

There is a house rule, too: no codeunit talks to the network directly. Every HTTP call travels through the System Application's `Interface "Http Client Handler"` — production code passes the standard `Codeunit "Http Client Handler"`, which really goes on the wire, while automated tests pass a mock of the service. Your client receives the handler as a parameter and must route its request through it; that seam is exactly how the grading tests watch your request and script the service's answers.

## The service

One endpoint matters here: `GET https://rates.example.com/v1/latest?symbol=<currency code>` — the currency you are asking about travels as the `symbol` query parameter.

On success the service answers `200` with a JSON body like:

```json
{ "symbol": "EUR", "rate": 0.13123, "asOf": "2026-07-15" }
```

When something is wrong the service answers with a non-success status such as `404` or `500` — and, like many real APIs, the error response can still carry a JSON body, sometimes even one containing a `rate` property. Only a success status makes the body trustworthy.

## Requirements

Create a **codeunit** named `"Exchange Rate Client"` with one public procedure:

```al
procedure GetRate(CurrencyCode: Text; HttpClientHandler: Interface "Http Client Handler"; var Rate: Decimal): Boolean
```

Rules:

1. Each call sends **exactly one** HTTP GET request through `HttpClientHandler`, and the full request URL must be exactly `https://rates.example.com/v1/latest?symbol=<CurrencyCode>`.
2. If the handler cannot send the request at all (a transport failure), return `false`.
3. If the response has a success status code and the body is valid JSON with a `rate` property, set `Rate` to that number and return `true`.
4. If the response status is not a success, return `false` — no matter what the body contains.
5. If the status is a success but the body is not valid JSON, or the JSON has no `rate` property, return `false`.
6. Whenever the procedure returns `false`, `Rate` must end up `0` — callers must never see a stale or half-parsed value.
7. The procedure never raises an error, whatever the service does.

You may rely on two guarantees: `CurrencyCode` is always plain letters, and when a `rate` property is present it is always a JSON number.

## What the tests check

The grading tests implement `"Http Client Handler"` with a mock of the rate service — no real network is involved (the grading container has none anyway), so write your request as if the endpoint were real and let the mock do the answering. The mock records every request your code sends through the handler: the method must be GET, the full URL must match the documented endpoint character for character — one test generates a random currency code and expects it unchanged in the `symbol` parameter — and exactly one request per call may arrive. A success test injects `200` with a randomly generated rate and expects that exact number back. One test makes the handler report a transport failure and expects `false`. The `404` and `500` tests inject bodies that still contain a tempting `rate` value — an implementation that parses the body before checking the status returns that value and fails. The malformed-body and missing-property tests expect `false`, and every failure test presets `Rate` to `-1` before calling, so leaving it untouched fails too.

## Learn More

- [Call external services with the HttpClient data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient)
- [HttpClient.Get(Text, var HttpResponseMessage) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-get-method)
- [HttpResponseMessage.IsSuccessStatusCode() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpresponsemessage/httpresponsemessage-issuccessstatuscode-method)
- [JsonObject data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type)
- [Access REST services from within Dynamics 365 Business Central (training module)](https://learn.microsoft.com/en-us/training/modules/access-rest-services/)
