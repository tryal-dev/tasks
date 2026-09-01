# Serialize a Sales Order to JSON

Your company's new warehouse partner picks up sales orders through a REST integration, and the payload format is settled: one JSON document per order — header fields at the top, one array element per line. The first attempt, hand-rolled string concatenation, already blew up twice in the pilot: a colleague in Copenhagen produced `"quantity": 2,5`, and an order for `24" brackets` broke the document at the inch mark.

Your job is the serializer: given a sales order, produce the exact JSON document described below, identical in meaning no matter the regional settings of the session that runs it.

## Requirements

Create a **codeunit** named `"Order JSON Export"` with one public procedure:

```al
procedure ExportOrder(SalesHeader: Record "Sales Header"): Text
```

It returns one JSON object serialized as text. For an order with a single line, the document looks like this:

```json
{
  "orderNo": "S-ORD-1001",
  "customerNo": "C00040",
  "orderDate": "2026-04-27",
  "lines": [
    {
      "lineNo": 10000,
      "itemNo": "I00050",
      "description": "Steel bracket 24\"",
      "quantity": 2.5,
      "unitPrice": 1249.99,
      "lineAmount": 3124.98
    }
  ]
}
```

Rules:

1. `orderNo` is the order's `"No."` and `customerNo` is its `"Sell-to Customer No."` — both JSON strings.
2. `orderDate` is the order's `"Order Date"` as a JSON string in ISO 8601 date format (`yyyy-MM-dd`) — April 27, 2026 serializes as `2026-04-27` whatever the session's regional settings are.
3. `lines` is a JSON array with exactly one object per sales line of the order, in ascending `"Line No."` order. Each object carries `lineNo` (`"Line No."`), `itemNo` (`"No."`), `description` (`Description`), `quantity` (`Quantity`), `unitPrice` (`"Unit Price"`) and `lineAmount` (`"Line Amount"`) — the field values as they stand, no recomputation.
4. `lineNo`, `quantity`, `unitPrice` and `lineAmount` are unquoted, culture-invariant JSON numbers: decimal point, no digit grouping — `1249.99`, never `1.249,99`, `1,249.99` or `"1249.99"`.
5. Text values must survive hostile content: a description containing `"` or `\` must round-trip through a JSON parser unchanged.
6. An order without lines serializes with `"lines": []`.
7. Property names exactly as shown — camelCase, and case matters.

## What the tests check

The grading tests build sales orders with generated customers, items and amounts, call `ExportOrder`, re-parse the returned text with a JSON parser and assert on the parsed structure — property order, whitespace and number formatting beyond the rules above don't matter, and extra properties you emit are ignored. One test seeds a unit price above 1000 so digit grouping has somewhere to appear; one seeds a description containing `"` and `\`; one checks the exact `orderDate` string for a fixed date and another uses a generated date with a single-digit day and month, so the zero padding must be real; one applies a line discount so the stored `"Line Amount"` no longer equals `Quantity * "Unit Price"`; one surrounds the order with other documents — a second order and a quote sharing the order's number — and expects only the order's own lines in the array; one exports an order with no lines at all.

## Learn More

- [JsonObject data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type)
- [JsonArray data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type)
- [JsonObject.Add(Text, JsonValue) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-add-string-jsonvalue-method)
- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property)
- [HTTP, JSON, TextBuilder, and XML API overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-restapi-overview)
