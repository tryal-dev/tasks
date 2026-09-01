# Ask the Service the Right Question

Your extension reads sales orders from a partner's OData v4 service, and the current integration glues its query strings together with `+`. It has already failed twice in production: once when a customer called `O'Brien Foods` closed an OData string value halfway through and the service answered with a syntax error, and once when a well-meaning cleanup percent-encoded the `$` of `$filter` — the service silently ignored an option it did not recognise and streamed the entire order table back. You are rebuilding the URL layer so that every query asks the service exactly the question you meant.

## The service

- The endpoint is `https://api.contoso-orders.example/odata/v4/SalesOrders` — an OData v4 entity set with the fields `Number`, `CustomerName`, `ExternalDocumentNo`, `OrderDate`, `Status` and `Amount`.
- It understands the standard system query options `$filter`, `$select`, `$orderby` and `$top`, and it never decodes an option **name**: a request that arrives with `%24filter` is treated as an unknown option and ignored. The `$` has to reach the service as a literal `$`.
- Option **values** are ordinary query-string data and are decoded by the service, so they must be percent-encoded on the way out.

## Requirements

Create a **codeunit** named `"OData Query Builder"` with four public procedures:

```al
procedure OrdersByCustomerUrl(CustomerName: Text; FromDate: Date; ToDate: Date): Text
procedure OpenOrderSearchUrl(SearchText: Text; MaxRows: Integer): Text
procedure RecentOrdersUrl(RowCount: Integer): Text
procedure Fetch(RequestUri: Text; HttpClientHandler: Interface "Http Client Handler"; var ResponseBody: Text): Boolean
```

### How a value is written inside an OData expression

- A **string** value is wrapped in single quotes, and every single quote inside it is doubled: the name `O'Brien Foods` is written `'O''Brien Foods'`.
- A **date** value is a bare ISO 8601 calendar date `YYYY-MM-DD`, zero-padded, never quoted and never locale-formatted: 3 February 2026 is `2026-02-03`.
- A **number** is written as plain digits.

### How the query string is encoded

- Each option **value** travels as data: every character except ASCII letters, digits and `-` `.` `_` `~` is percent-encoded from its UTF-8 bytes with uppercase hex. A space becomes `%20`, a single quote `%27`, `(` becomes `%28`, `)` becomes `%29`, a comma `%2C`, and a non-ASCII letter like `å` becomes `%C3%A5`.
- Each option **name** keeps its dollar sign: the finished query reads `?$filter=…&$top=…`, never `?%24filter=…`.

### The three URLs

**1. `OrdersByCustomerUrl`** returns the endpoint with a single query option, `$filter`, whose value *before* encoding is exactly:

```
(CustomerName eq <name>) and (OrderDate ge <from>) and (OrderDate le <to>)
```

`<name>` is `CustomerName` written as an OData string value; `<from>` and `<to>` are `FromDate` and `ToDate` written as OData date values.

**2. `OpenOrderSearchUrl`** returns the endpoint with two query options in this order — `$filter`, then `$top`. The filter value *before* encoding is exactly:

```
(Status eq 'Open') and ((contains(CustomerName,<text>)) or (contains(ExternalDocumentNo,<text>)))
```

`<text>` is `SearchText` written as an OData string value, and it appears in both `contains` calls. Note there is no space after the comma inside `contains(...)`. `$top` carries `MaxRows` as plain digits.

**3. `RecentOrdersUrl`** returns the endpoint with three query options in this order: `$select` with the value `Number,CustomerName,OrderDate,Amount`, then `$orderby` with the value `OrderDate desc`, then `$top` with `RowCount` as plain digits.

Worked examples, character for character:

- `OrdersByCustomerUrl('Fabrikam', 20260101D, 20260331D)` → `https://api.contoso-orders.example/odata/v4/SalesOrders?$filter=%28CustomerName%20eq%20%27Fabrikam%27%29%20and%20%28OrderDate%20ge%202026-01-01%29%20and%20%28OrderDate%20le%202026-03-31%29`
- `OpenOrderSearchUrl('sea salt', 20)` → `https://api.contoso-orders.example/odata/v4/SalesOrders?$filter=%28Status%20eq%20%27Open%27%29%20and%20%28%28contains%28CustomerName%2C%27sea%20salt%27%29%29%20or%20%28contains%28ExternalDocumentNo%2C%27sea%20salt%27%29%29%29&$top=20`
- `RecentOrdersUrl(25)` → `https://api.contoso-orders.example/odata/v4/SalesOrders?$select=Number%2CCustomerName%2COrderDate%2CAmount&$orderby=OrderDate%20desc&$top=25`

### `Fetch`

`Fetch` sends `RequestUri` to the service as an HTTP **GET** through the `Interface "Http Client Handler"` it is given (the System Application's Rest Client seam), and reports whether the answer is usable:

- the request carries `RequestUri` unchanged;
- if the handler reports that the request could not be sent, return `false` — even when the response object it hands back would read as a success;
- if the service answers with a status outside the success range, return `false`;
- otherwise set `ResponseBody` to the response body as text and return `true`.

On every `false` path `ResponseBody` ends up empty, and `Fetch` never raises an error. Grading passes a stand-in handler that records the request and answers with a canned response — there is no network in the grading container, so the request must travel through the handler you are given.

You may rely on these guarantees about the inputs: `CustomerName` and `SearchText` are never empty and contain only letters (including non-ASCII letters such as `å` or `Ø`), digits, spaces and the characters `'` `.` and `-`; `FromDate` and `ToDate` are real dates; `MaxRows` and `RowCount` are between 1 and 5000.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

Each URL test calls one procedure and compares the returned text with the expected absolute URL **character for character** — the OData expression, the order of the query options, the uppercase percent-encoding of the values, and the literal `$` in front of every option name. The customer tests cover a plain name, a name whose single quote must be doubled, a name carrying non-ASCII letters, a date window with single-digit months and days, and a randomly generated name with generated dates; the search tests cover a two-word term, a term with a single quote, and a generated term with a generated row limit; the paging tests cover a fixed and a generated row count — so hardcoding the worked examples fails. One further test asserts that no `%24` appears anywhere in a built URL. The `Fetch` tests use a stand-in handler and check that the request reaching the service carries exactly the URL passed in, that the method is `GET`, that a 200 response yields `true` plus the untouched body, that a 400 response yields `false`, and that a transport failure yields `false` too — in that last case the stand-in handler still hands back a 200 response with a body, so only honouring what the handler reported gets you there. Both `false` paths leave `ResponseBody` empty.

## Learn More

- [Using filter expressions in OData URIs](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/webservices/use-filter-expressions-in-odata-uris) — the operators and functions a `$filter` may use, and how string values are delimited.
- [OData web services](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/webservices/odata-web-services) — the surrounding OData concepts, including paging and the other system query options.
- [Uri codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.uri) — `EscapeDataString` and `GetAbsoluteUri`, the System Application's URL primitives.
- [Http Client Handler interface](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/interface/system.restclient.http-client-handler) — the single `Send` method `Fetch` calls, and the two codeunits it hands you.
