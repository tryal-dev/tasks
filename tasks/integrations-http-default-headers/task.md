# Default Headers and the Content-Type Gotcha

Your company pushes business events — "order shipped", "invoice posted" — to a partner's event hub, and the partner's API specification is strict about headers: every request must identify the sending system, every request must declare what it accepts, and the body's media type must be declared correctly. Instead of repeating that header boilerplate at every call site, you will build the one client codeunit that layers it on: fixed defaults on every request, per-call extras when a call needs more, and overrides that cleanly replace a default instead of sending both values.

The house rule from this topic's other HTTP tasks stands: no codeunit talks to the network directly. Every HTTP call travels through the System Application's `Interface "Http Client Handler"` — production code passes the standard `Codeunit "Http Client Handler"`, which really goes on the wire, while automated tests pass a mock of the event hub. Your client receives the handler as a parameter and must route its request through it; that seam is exactly how the grading tests capture your request and inspect the header sets that would have gone on the wire.

## Requirements

Create a **codeunit** named `"Event Hub Client"` with one public procedure:

```al
procedure SendEvent(Url: Text; Body: Text; ExtraHeaders: Dictionary of [Text, Text]; HttpClientHandler: Interface "Http Client Handler"): Boolean
```

Use object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

Rules:

1. Each call sends **exactly one** HTTP **POST** request through `HttpClientHandler`, with the full request URL exactly `Url` and the request body exactly `Body` — nothing rewritten, nothing appended.
2. Every request carries two default request headers, exact names and values: `Accept: application/json` and `X-Source-System: Business Central`.
3. Every entry of `ExtraHeaders` ends up on the request with exactly its value. An entry whose name matches a default — compared **case-insensitively**, so `ACCEPT` matches `Accept` — replaces that default: the header goes on the wire with exactly one value, never two.
4. `Content-Type` is special. The body's media type is `application/json` by default; an `ExtraHeaders` entry named `Content-Type` (under any casing) replaces it. But wherever the value comes from, `Content-Type` must end up in the **content's** header collection and must never appear among the request's own headers — HTTP keeps content headers with the content, and this is the classic HttpClient mistake this task exists to teach.
5. Return `true` only when the handler accepts the request and the response status is in the `2xx` class — any success status, not just `200`. Return `false` on a transport failure (the handler's `Send` reports it) or on any non-success status.

You may rely on these guarantees: `Url` is a plain HTTPS URL, `Body` is non-empty text, and `ExtraHeaders` holds at most a few entries with syntactically valid header names and values, no two of which name the same header.

## What the tests check

The grading tests implement `"Http Client Handler"` with a mock of the event hub — no real network is involved (the grading container has none anyway), so write your request as if the endpoint were real and let the mock do the answering. The mock records the method, the full URL, the body, the number of requests, and the complete request and content header sets your call produced. The URL, the body, and every override value are randomly generated, so hardcoding the examples fails. One test passes no extras and expects both defaults plus `Content-Type: application/json` on the content; one test passes an unrelated extra header and expects it alongside the intact defaults; the override tests pass `Accept` once in its canonical spelling and once under a randomly chosen casing and expect exactly one value on the wire — a duplicated header shows both values in the failure message; the `Content-Type` tests pass overrides as `Content-Type` and under a randomly chosen casing and expect the content header replaced while the request's own headers stay free of `Content-Type` in every test. The status tests script a `202` acceptance (checking for exactly `200` fails), a `500` rejection, and a transport failure.

## Learn More

- [Call external services with the HttpClient data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient) — how an AL request is assembled and where request and content headers are set.
- [HttpContent data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type) — the content's own header collection and the `text/plain; charset=utf-8` default it starts with.
- [HttpHeaders data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type) — the header collection API behind both the request and the content.
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — iterating the `ExtraHeaders` parameter.
