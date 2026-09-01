# Post a Form, Read a Form

Your extension talks to a partner's ageing integration gateway, and neither half of it speaks JSON: the OAuth token endpoint and the legacy order API both want `application/x-www-form-urlencoded` — the same wire format an HTML form posts — and both answer in it too. The first version of this integration glued the body together with `Key + '=' + Value + '&'`, and it worked right up until a client secret contained a `+`. The gateway read that `+` as a space, the credentials stopped matching, and nothing in the logs said why. That shape of bug — a character that means one thing as data and another as syntax — is what you are fixing here, in both directions.

The house rule from this topic's other HTTP tasks stands: no codeunit talks to the network directly. Every HTTP call travels through the System Application's `Interface "Http Client Handler"` — production code passes the standard `Codeunit "Http Client Handler"`, which really goes on the wire, while automated tests pass a mock of the gateway. Your client receives the handler as a parameter and must route its request through it; that seam is exactly how the grading tests capture the body and the headers your call would have put on the wire.

## The wire format

A form body is a list of `key=value` pairs joined by `&`, for example `grant_type=client_credentials&scope=orders%20read`. Both directions have to agree on what each character means.

**Writing.** Every character of every key and value except ASCII letters, digits and `-` `.` `_` `~` is percent-encoded: a `%` followed by the two-digit **uppercase** hex of each of that character's UTF-8 bytes. So a space goes out as `%20` (never as `+`), a `+` as `%2B`, an `&` as `%26`, an `=` as `%3D`, and `é` as `%C3%A9`. The gateway accepts `%20` for a space, so you never need `+` on the way out — and a literal `+` that slips through unescaped is the bug from the story above.

**Reading.** The gateway is not so tidy on the way back: it writes spaces as `+`. So when reading a form, a raw `+` means a space, and a `%XX` run is the UTF-8 bytes of the original character — which means `%2B` stands for a literal `+`, not for a space. Note the order in which you apply those two rules to the same text.

## Requirements

Create a **codeunit** named `"Form Url Encoded Client"` with three public procedures:

```al
procedure BuildFormBody(Fields: Dictionary of [Text, Text]): Text
procedure ParseFormBody(FormText: Text): Dictionary of [Text, Text]
procedure PostForm(Url: Text; Fields: Dictionary of [Text, Text]; HttpClientHandler: Interface "Http Client Handler"; var ResponseFields: Dictionary of [Text, Text]): Boolean
```

Use object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

`BuildFormBody`:

1. Every entry of `Fields` becomes one `key=value` pair, the key and the value each encoded by the writing rule above. The pairs are joined by a single `&`, with no leading and no trailing `&`. The order of the pairs is **not** graded.
2. A field whose value is empty text still appears, as `key=` — the trailing `=` with nothing after it. Dropping the field, or emitting a bare `key`, is wrong.
3. An empty `Fields` produces empty text.

`ParseFormBody`:

4. The text is split into pairs on `&`, and each pair is split at its **first** `=`; any further `=` in that pair belongs to the value, so `code=YWJjZA==` yields the value `YWJjZA==`. A pair with no `=` at all yields that key with an empty value. Key and value are then decoded by the reading rule above.
5. A key that appears more than once keeps the value of its **last** occurrence, and a repeated key never raises an error.
6. Empty text yields an empty dictionary.

`PostForm`:

7. Exactly one HTTP **POST** request goes through `HttpClientHandler`, to exactly `Url`, carrying `BuildFormBody(Fields)` as the request body.
8. The body's media type is `application/x-www-form-urlencoded`, and it must live in the **content's** header collection, never among the request's own headers — HTTP keeps content headers with the content. A trailing `; charset=...` on the media type is accepted.
9. Return `true` only when the handler accepts the request and the response status is in the `2xx` class — any success status, not just `200`. When it returns `true`, `ResponseFields` holds the response body run through the same parsing rules. Return `false` on a transport failure (the handler's `Send` reports it) or on any non-success status; what `ResponseFields` holds after a `false` is not graded.

You may rely on these guarantees about the inputs:

- Keys handed to `BuildFormBody` are never empty; values may be. Keys and values consist of letters (including non-ASCII letters such as `é`), digits, spaces, and the characters `&` `=` `+` `-` `.` `_` — never a `%`.
- Text handed to `ParseFormBody` is a well-formed form body: no empty pair, no leading or trailing `&`, no empty key, and every `%` starts a valid two-hex-digit escape.
- `Url` is a plain HTTPS URL.

## What the tests check

The grading tests call each procedure directly and compare exact strings, so note the uppercase hex, `%20` rather than `+`, and the trailing `=` on an empty value. The build tests cover a randomly generated field (hardcoding the examples fails), a space, a literal `+`, `&` and `=` in both the key and the value, a non-ASCII value, characters that must stay unescaped, an empty value, an empty dictionary, and three fields at once — that last one checks only that each pair appears exactly once and that a single `&` joins them, never their order. The parse tests cover a randomly generated pair, a raw `+` in both key and value, an encoded `%2B` sitting next to a raw `+` in the same value (the ordering trap), percent escapes including UTF-8 ones, a value carrying `=` characters of its own, an empty value, a pair with no `=`, a repeated key, and empty text; one further test round-trips a generated key and value full of `+` `&` `=` spaces and non-ASCII letters through `BuildFormBody` and back. The `PostForm` tests implement `"Http Client Handler"` with a mock of the gateway — no real network is involved; the grading container has none — and check that exactly one POST reaches the given URL, that its body is the encoded form, that `Content-Type` sits on the content headers and nowhere among the request's own headers, that a form-encoded response body lands parsed in `ResponseFields`, and that the return value is `true` for a `202`, `false` for a `400`, and `false` for a transport failure.

## Learn More

- [Call external services with the HttpClient data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient) — how an AL request is assembled and where request and content headers live.
- [HttpContent data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type) — the content's own header collection and the `text/plain; charset=utf-8` default it starts with.
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type) — reading the fields out of the parameter and putting the parsed ones back in.
- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type) — `Split`, `Replace` and the rest of the text methods the two conversions are built from.
