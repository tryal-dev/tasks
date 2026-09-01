# When the API Says No

Your company books parcels with a carrier whose REST API is well behaved in the only way that matters: when it refuses, it says why. Every failure comes back as an RFC 7807 problem document — `application/problem+json` with a `title`, a `detail` and, for validation failures, an `errors` array naming each field it rejected. That is a gift, and most integrations throw it away: they catch the failure, shrug, and tell the warehouse clerk "the request failed".

Your job is the client that does not throw it away. One call in, one readable error out — the clerk should be able to read the error and know whether to fix the customer number, wait, or call IT.

There is a house rule, too: no codeunit talks to the network directly. Every HTTP call travels through the System Application's `Interface "Http Client Handler"` — production code passes the standard `Codeunit "Http Client Handler"`, which really goes on the wire, while automated tests pass a mock of the carrier. Your client receives the handler as a parameter and must route its request through it; that seam is exactly how the grading tests watch your request and script the carrier's answers.

## The service

Two endpoints matter here, both under `https://ship.example.com/api/v1/shipments`.

`GET https://ship.example.com/api/v1/shipments/<ShipmentNo>` looks a shipment up. On success it answers `200` with a JSON body like:

```json
{ "shipmentNo": "S-1001", "status": "in transit", "carrier": "TryAL Express" }
```

`POST https://ship.example.com/api/v1/shipments` books a new shipment. The request body is a JSON object with one property, sent as `application/json`:

```json
{ "customerNo": "C-0042" }
```

On success the booking answers `201` with the same shape as the lookup; the `shipmentNo` property carries the number the carrier assigned.

Any status outside the 2xx range is a refusal. Its body is usually a problem document:

```json
{ "type": "https://ship.example.com/problems/shipment", "title": "Shipment S-9999 not found", "status": 404, "detail": "Carrier zeta has no record of this shipment." }
```

A validation refusal adds an `errors` array, one entry per rejected field:

```json
{ "type": "...", "title": "Booking rejected for C-0042", "status": 422, "detail": "The booking request has invalid fields.", "errors": [ { "field": "customerNo", "message": "C-0042 is not a known customer" }, { "field": "serviceLevel", "message": "must be one of express, economy" } ] }
```

But not every refusal comes from the carrier. Gateways and proxies in front of it answer with an HTML page, or with nothing at all — a body you cannot parse, wrapped around a status code you still have to report.

## Requirements

Create a **codeunit** named `"Shipment Booking Client"` with two public procedures:

```al
procedure GetShipmentStatus(ShipmentNo: Text; HttpClientHandler: Interface "Http Client Handler"): Text
procedure BookShipment(CustomerNo: Text; HttpClientHandler: Interface "Http Client Handler"): Text
```

Rules:

1. `GetShipmentStatus` sends **exactly one** HTTP GET through `HttpClientHandler`, to exactly `https://ship.example.com/api/v1/shipments/<ShipmentNo>`.
2. `BookShipment` sends **exactly one** HTTP POST through `HttpClientHandler`, to exactly `https://ship.example.com/api/v1/shipments`, with a JSON object body whose single `customerNo` property carries the argument, sent with content type `application/json`.
3. On a success status (anything in the 2xx range — `200` and `201` both occur), `GetShipmentStatus` returns the response body's `status` property and `BookShipment` returns its `shipmentNo` property.
4. On any non-success status, the procedure raises **one** error, assembled from the response as described in the next section.
5. If the request could not be sent at all — the handler reports a transport failure and no response ever comes back — the procedure raises an error with a message that is exactly `The shipment service could not be reached.` (note the final period). A failed send is never retried.
6. Both procedures follow the same failure contract; only the endpoint and the property they return differ.

## The error message for a refusal

The message is the following parts, in this order, joined with `" | "` — a space, a vertical bar, a space:

1. The status code, a single space, and the reason phrase the response carries: `404 Not Found`.
2. The problem document's `title`.
3. The problem document's `detail`.
4. One part for every entry of the problem document's `errors` array, in the order the array lists them, each formatted `<field>: <message>` — the field name, a colon, a space, the message.

A part that has no value is left out entirely — no empty segment, no doubled or trailing separator. So a body that is not a JSON object at all (HTML, empty, anything unparseable) leaves part 1 as the whole message, a problem document without a `detail` produces the status line and the title only, and one without a `title` produces the status line and the detail only. When an `errors` array is present, each of its entries is a JSON object carrying `field` and `message` as strings.

Worked examples, matching the three bodies above:

| Response | Error message |
|---|---|
| `404 Not Found` + the problem document above | `404 Not Found \| Shipment S-9999 not found \| Carrier zeta has no record of this shipment.` |
| `422 Unprocessable Entity` + the validation document above | `422 Unprocessable Entity \| Booking rejected for C-0042 \| The booking request has invalid fields. \| customerNo: C-0042 is not a known customer \| serviceLevel: must be one of express, economy` |
| `500 Internal Server Error` + an HTML page from the gateway | `500 Internal Server Error` |

Use object IDs from the range 50100–50199, and reference other objects by name, never by numeric ID.

## What the tests check

The grading tests implement `"Http Client Handler"` with a mock of the carrier — no real network is involved (the grading container has none anyway), so write your requests as if the endpoints were real and let the mock do the answering. The mock records every request: the method must be GET or POST as documented, the full URL must match character for character with a randomly generated shipment number in the path, the booking body must parse as JSON and carry the customer number in `customerNo`, its content type must be `application/json`, and exactly one request per call may arrive. The success tests generate the status and shipment number they inject and expect exactly those values back, from a `200` and from a `201`. The refusal tests compare the raised error **in full, character for character**, against the composed message — note the spaces around each `|`, the space after each field name's colon, and that the `type` and `status` properties of the problem document never appear in it. The reason phrases the refusal tests script are generated rather than the canonical ones for their status codes, so the status line has to be read off the response and not looked up from a table of status codes. One refusal omits `detail`, one omits `title`, one carries a two-entry `errors` array, one answers with HTML instead of a problem document, and the transport-failure tests expect the unreachable-service sentence and nothing else — an error raised by the platform on your behalf reads differently and fails them.

## Learn More

- [Call external services with the HttpClient data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient) — how requests, responses and status codes fit together in AL.
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling) — the strategies AL gives you for reacting to an error someone else raised.
- [User experience guidelines for errors](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-error-handling-guidelines) — why one assembled, readable error beats a generic failure.
- [JsonToken data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-data-type) — walking a document whose properties may or may not be there.
