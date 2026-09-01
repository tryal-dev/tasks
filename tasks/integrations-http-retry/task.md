# Retry with Backoff

Your extension calls a rate-limited external API, and that API misbehaves in a very specific way: sometimes it answers `429 Too Many Requests` or a `5xx` server error that clears up seconds later, and sometimes it answers a plain `404` that no amount of retrying will ever fix. A caller that gives up on the first hiccup loses data; a caller that retries everything hammers a service that already asked it to slow down. You will build the client that gets this right.

The house rule from the previous task still stands: no codeunit talks to the network directly. Every HTTP call travels through the System Application's `Interface "Http Client Handler"` — production code passes the standard `Codeunit "Http Client Handler"`, which really goes on the wire, while automated tests pass a mock of the service. Your client receives the handler as a parameter and must route every attempt through it; that seam is exactly how the grading tests count your requests and script the flaky service's answers.

## Requirements

Create a **codeunit** named `"Resilient Http Client"` with three public procedures:

```al
procedure GetWithRetry(Url: Text; MaxAttempts: Integer; HttpClientHandler: Interface "Http Client Handler"; var ResponseBody: Text): Boolean
procedure BackoffDelayMs(RetryNumber: Integer): Integer
procedure GetTotalBackoffMs(): Integer
```

Rules for `GetWithRetry`:

1. Every attempt sends exactly one HTTP **GET** request through `HttpClientHandler`, and every request's full URL is exactly `Url` — nothing rewritten, nothing appended, on retries too. The first attempt goes out immediately.
2. A response with a **success** status code — any status in the `2xx` class, not just `200` — ends the call: return `true` with the body of that response in `ResponseBody`.
3. A response with status **429** or any status in **500–599** is transient: if fewer than `MaxAttempts` requests have been sent so far, try again; if the budget is spent, give up.
4. Any other non-success status (`400`, `404`, …) is permanent: give up immediately, sending no further requests.
5. Giving up means returning `false` with `ResponseBody` equal to `''` — never the body of a failed response, and never a stale value the caller left in the variable.
6. It never sends more than `MaxAttempts` requests and never raises an error.

Rules for the backoff schedule:

7. `BackoffDelayMs` returns the wait in milliseconds before retry number `RetryNumber` (the retry that produces attempt `RetryNumber + 1`): 100 milliseconds for retry 1, and double the previous wait for every retry after it — 100, 200, 400, 800, and so on.
8. `GetWithRetry` keeps a backoff tally: for each retry number `k` it actually performs, it records `BackoffDelayMs(k)`. `GetTotalBackoffMs`, called on the same codeunit instance, returns the sum recorded by the most recent `GetWithRetry` call — `0` when that call never retried, and a fresh tally on every call, never a running total across calls.
9. Grading verifies the tally arithmetic, never wall-clock time: the grading mock answers instantly, and no test measures elapsed time. Actually pausing execution between retries is what production code would do with these values, but it is not graded — a submission that sleeps just grades slower.

You may rely on these guarantees: `MaxAttempts` is always at least 1, `Url` is a plain HTTPS URL without a query string, and the handler always delivers a response — transport-level send failures are out of scope here.

## What the tests check

The grading tests implement `"Http Client Handler"` with a mock of the flaky service — no real network is involved (the grading container has none anyway), so write your requests as if the endpoint were real and let the mock do the answering. The mock answers each request with the next status in a scripted sequence and records everything it sees; **every test asserts the exact number of requests**, so retrying too much or too little always fails somewhere. The flagship script answers `429`, then `500`, then `200`: exactly three requests must arrive and the third response's randomly generated body must come back with `true`. Another success script answers the very first request with a randomly chosen status anywhere in the `2xx` range — checking for exactly `200` fails it. A script that endlessly repeats a single randomly chosen `5xx` status (anywhere in `500`–`599`, not just the famous ones) with a randomly chosen `MaxAttempts` between 2 and 5 must produce exactly that many requests and then `false`. A randomly chosen `400` or `404` whose script continues with a `200` must produce exactly one request — retrying it would reach the `200` and wrongly succeed — and `MaxAttempts` of 1 against a `500` likewise means exactly one request. One test scripts retries against a randomly generated URL and compares every captured request's method and full URL character for character. Failure tests preset `ResponseBody` to a stale value and expect `''` back. `BackoffDelayMs` is graded as a pure function, including a random retry number up to 8; the tally tests expect `GetTotalBackoffMs` to report 300 after the flagship script (100 + 200), the full schedule when the attempt budget is spent, `0` when the first attempt succeeds or a permanent status ends the call, and a fresh value — not a running total — when the same instance is used for a second call.

## Learn More

- [Call external services with the HttpClient data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient)
- [HttpResponseMessage data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpresponsemessage/httpresponsemessage-data-type)
- [HttpResponseMessage.HttpStatusCode() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpresponsemessage/httpresponsemessage-httpstatuscode-method)
- [HttpResponseMessage.IsSuccessStatusCode() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpresponsemessage/httpresponsemessage-issuccessstatuscode-method)
- [Troubleshooting web service errors](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/webservices/web-service-troubleshooting)
