# Import an Order from JSON

A webshop your company just signed pushes every confirmed order to Business Central as one JSON document. You are writing the import: a single call takes the raw document text and turns it into an order header with its lines — or refuses cleanly, without leaving half an order in the database.

## The document

```json
{
  "orderNo": "SO-1042",
  "orderDate": "2026-04-05",
  "currencyCode": "EUR",
  "customer": {
    "name": "O'Brien & Sons",
    "email": "orders@obrien.example"
  },
  "lines": [
    { "lineNo": 10000, "itemNo": "1896-S", "description": "Athens desk", "quantity": 2.5, "unitPrice": 149.9 },
    { "lineNo": 20000, "itemNo": "1900-S", "description": "Paris chair", "quantity": 1, "unitPrice": 96.4 }
  ]
}
```

Facts about the feed:

- `orderDate` is always ISO 8601 text (`yyyy-mm-dd`) — the import must store the correct date no matter which region settings the server runs with.
- `quantity` and `unitPrice` are JSON numbers; `lineNo` is a JSON integer.
- String values may carry JSON escapes — a customer may be named `O'Brien & \"Sons\"` in the document — and must be stored decoded.
- `currencyCode`, `customer.email` and `description` are optional; every other property shown above is required.
- Values in the graded documents always fit the destination fields — there are no truncation rules to worry about.

## Requirements

The starter ships two tables, `"Web Order Header"` and `"Web Order Line"` — keep them in your submission unchanged; the grading tests read them by name.

Create a **codeunit** named `"Order Json Import"` with one public procedure:

```al
procedure ImportOrder(OrderJson: Text): Code[20]
```

Header mapping:

- `orderNo` → `"Order No."`
- `orderDate` → `"Order Date"`
- `currencyCode` → `"Currency Code"`
- `customer.name` → `"Customer Name"`
- `customer.email` → `"Customer E-Mail"`

Line mapping, one `"Web Order Line"` per element of `lines` (with `"Order No."` set to the header's):

- `lineNo` → `"Line No."`
- `itemNo` → `"Item No."`
- `description` → `Description`
- `quantity` → `Quantity`
- `unitPrice` → `"Unit Price"`

Rules:

1. A valid document inserts exactly one `"Web Order Header"` record plus one `"Web Order Line"` record per element of `lines`, and returns the imported `"Order No."`.
2. A missing optional property leaves its field blank; the import still succeeds.
3. If the text is not valid JSON at all, fail with an error message that contains `invalid JSON` (exact casing).
4. If a required property is missing, or its value cannot be converted to the destination type (an unparseable date, a quantity that is not a number), fail with an error message that contains that property's name exactly as it is spelled in the document. Every required property is graded this way: `orderNo`, `orderDate`, `customer`, `name` (for `customer.name`), `lineNo`, `itemNo`, `quantity`, `unitPrice`. The message must name only the offending property: the tests also assert that none of `orderNo`, `orderDate`, `quantity`, `itemNo`, `unitPrice` appears in the message when a different property is at fault — so one catch-all message that lists every property fails.
5. If `lines` is missing, not an array, or an empty array, fail with an error message that contains `lines`.
6. The error must surface no matter how deep in the document the problem sits — a document whose **second** line is broken still fails naming the offending property. You do not need to clean up on failure (not graded): raising an error rolls back the open database transaction, so a failed import leaves nothing behind by itself.

## What the tests check

The tests import a valid document and read back every mapped header and line field, including a customer name whose JSON escapes must arrive decoded; they store `"orderDate": "2026-03-04"` and expect 4 March 2026 — day and month must not swap; they import a three-line document and check each line's numbers exactly, plus a document generated from random values so constants can't pass; they omit the optional properties and expect blank fields. Then they feed broken documents — text that isn't JSON, one document per required property where it is missing (`orderNo`, `orderDate`, `customer`, `customer.name`, `lineNo`, `itemNo`, `quantity`, `unitPrice`), one per converted property where the value won't convert (a date of `"sometime in spring"`, a `quantity` of `"plenty"`, a `unitPrice` of `"cheap"`, a `lineNo` of `"first"`), and a `lines` that is missing, a string, or an empty array — and expect errors with messages that contain `invalid JSON` (for the text that isn't JSON) or the offending property's name (substring match, exact casing), and none of the other property names listed in rule 4. Finally they feed a document whose **second** line carries the bad `quantity` and expect the same error naming `quantity`.

## Learn More

- [JsonToken data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-data-type)
- [JsonToken.ReadFrom(Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-readfrom-string-method)
- [JsonObject.SelectToken(Text, var JsonToken) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-selecttoken-method)
- [JsonToken.AsValue() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-asvalue-method)
- [JsonValue data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type)
