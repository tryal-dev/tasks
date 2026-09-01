# Call a SOAP Service (Mocked)

REST won its war, but nobody told the TryAL VAT Registry — the government gateway your finance team must call before invoicing a new business partner. Like plenty of carriers, banks and tax authorities, it speaks SOAP 1.1 over HTTP POST, and it will keep speaking it long after you retire. This task composes three things you have built before: an XML document with namespaces, an HTTP call through the mockable handler seam, and a namespace-aware parse of the answer.

As in the other integration tasks, the house rule applies: no codeunit talks to the network directly. Every HTTP call travels through the System Application's `Interface "Http Client Handler"` — production code passes the standard `Codeunit "Http Client Handler"`, while automated tests pass a mock of the gateway. Your client receives the handler as a parameter, and that seam is how the grading tests read your request and script the registry's answers.

## The gateway

One operation matters here: `CheckVat`, reached by an HTTP `POST` to `https://vat.example.gov/registry/v1/soap`.

The gateway speaks **SOAP 1.1 only**. Concretely, a request must satisfy all of the following:

- The body is a SOAP 1.1 envelope: a root element `Envelope` with a child `Body`, both in the namespace `http://schemas.xmlsoap.org/soap/envelope/`. SOAP 1.2 envelopes (namespace `http://www.w3.org/2003/05/soap-envelope`) are rejected.
- Inside `Body` sits exactly one `CheckVatRequest` element in the namespace `urn:tryal:vat:registry:v1`, with two child elements in that **same** namespace: `CountryCode` and `VatNumber`.
- The `Content-Type` is the SOAP 1.1 one: media type `text/xml` with the parameter `charset=utf-8`. SOAP 1.2's `application/soap+xml` is rejected. (Letter case and spacing inside the header value are not graded; the media type and the charset parameter are.)
- The request carries a `SOAPAction` header whose value is exactly `"urn:tryal:vat:registry:v1/CheckVat"` — the double quotes are part of the header value, as SOAP 1.1 demands, and the gateway rejects a call without them.

A valid request, with one possible choice of prefixes:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <CheckVatRequest xmlns="urn:tryal:vat:registry:v1">
      <CountryCode>DK</CountryCode>
      <VatNumber>88776655</VatNumber>
    </CheckVatRequest>
  </soap:Body>
</soap:Envelope>
```

Namespace prefixes are never part of the contract — on the wire, in either direction, only namespace URIs and local names carry identity. The gateway parses your envelope namespace-aware and answers with whatever prefixes (or default declarations) it fancies that day.

When the number is registered, the gateway answers `200` with an envelope whose `Body` carries a `CheckVatResponse` in `urn:tryal:vat:registry:v1`, containing, among other elements, a `TraderName` element in that same namespace with the registered trader's name:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
  <env:Body>
    <CheckVatResponse xmlns="urn:tryal:vat:registry:v1">
      <CountryCode>DK</CountryCode>
      <VatNumber>88776655</VatNumber>
      <TraderName>Kronborg Freight ApS</TraderName>
    </CheckVatResponse>
  </env:Body>
</env:Envelope>
```

When the gateway rejects the call, it answers `500` with a SOAP 1.1 fault: a `Fault` element in the envelope namespace inside `Body`, whose `faultcode` and `faultstring` children are — a genuine SOAP 1.1 quirk — in **no namespace at all**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <soapenv:Fault>
      <faultcode>soapenv:Client</faultcode>
      <faultstring>Unknown VAT number</faultstring>
    </soapenv:Fault>
  </soapenv:Body>
</soapenv:Envelope>
```

And the infrastructure between you and the gateway adds failure modes of its own: the transport can fail outright, and a proxy may answer with some other status and an arbitrary body (a `502` HTML page, say) that contains no SOAP fault anywhere.

You may rely on the following: `CountryCode` is always two uppercase letters and `VatNumber` is letters and digits only, but trader names and fault reasons can contain any characters — ampersands, quotes, angle brackets. Response envelopes may also contain elements from foreign namespaces with familiar local names (even a `TraderName`); they are not yours and must be ignored.

## Requirements

Create a **codeunit** named `"Vat Registry Client"` with one public procedure:

```al
procedure CheckVat(CountryCode: Text; VatNumber: Text; HttpClientHandler: Interface "Http Client Handler"; var TraderName: Text; var FaultReason: Text): Boolean
```

Rules:

1. Each call sends **exactly one** HTTP POST request through `HttpClientHandler` to exactly `https://vat.example.gov/registry/v1/soap`.
2. The request body is a valid SOAP 1.1 `CheckVatRequest` envelope as specified above, carrying the `CountryCode` and `VatNumber` parameters exactly. Your choice of prefixes (or default declarations) is free — the tests identify every element by namespace URI and local name.
3. The request carries the SOAP 1.1 `Content-Type` and the quoted `SOAPAction` header exactly as specified above.
4. On a `200` response: return `true`, set `TraderName` to the text content of the response's registry-namespace `TraderName` element, and leave `FaultReason` empty.
5. On a non-success response whose body is a SOAP 1.1 fault envelope: return `false`, set `FaultReason` to the text content of `faultstring`, and leave `TraderName` empty.
6. On a transport failure (the handler cannot send at all), or any other non-success response — whatever junk its body holds: return `false` with **both** outputs empty.
7. Whenever the procedure returns `false`, `TraderName` must end up `''`; `FaultReason` must be non-empty only when an actual fault was parsed. Callers must never see stale or half-parsed values.
8. The procedure never raises an error, whatever the gateway or the infrastructure does.

## What the tests check

The grading tests implement `"Http Client Handler"` with a mock of the registry — no real network is involved (the grading container has none anyway). The mock records your request: one test asserts exactly one POST to the exact URL, one parses your envelope namespace-aware and checks root, `Body`, payload element and both children — in the right namespaces, carrying randomly generated parameter values — one checks the `Content-Type` (case- and spacing-insensitively), and one checks the `SOAPAction` header character for character, quotes included. On the response side: a success test injects a `200` with a generated trader name and expects it back exactly; a second success test shuffles all prefixes (default envelope namespace, prefixed payload) and plants a foreign-namespace `TraderName` decoy ahead of the real one, whose text contains `&` and angle brackets; a fault test injects a `500` fault envelope and expects the generated `faultstring` text — which itself contains `&` and angle brackets — in `FaultReason` with `TraderName` cleared; a transport-failure test and a `502`-proxy test whose HTML body is not even well-formed XML expect `false` with both outputs empty. The failure tests preset both `var` parameters to sentinel values before calling, so leaving them untouched fails too, and they all assert that exactly one request was sent — no retries on any path.

## Learn More

- [SOAP web services](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/webservices/soap-web-services)
- [Call external services with the HttpClient data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient)
- [HttpRequestMessage data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequestmessage/httprequestmessage-data-type)
- [HttpContent data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type)
- [XmlNamespaceManager data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnamespacemanager/xmlnamespacemanager-data-type)
