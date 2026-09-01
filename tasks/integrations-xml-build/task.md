# Generate an XML Document

The warehouse partner that ships your sales orders pulls them from Business Central as XML, and their integration is strict: a document that does not parse is rejected, and a date or amount rendered with the server's regional settings ends up as garbage on their side. The previous attempt at this export glued the document together from strings — it worked until the first customer named `O'Brien & Sons <Import/Export>` came along.

Your job is an export codeunit that produces well-formed XML no matter what the data contains.

## Requirements

Create a **codeunit** named `"Sales Order Xml Export"` with one public procedure:

```al
procedure ExportOrder(OrderNo: Code[20]; ExportStream: OutStream)
```

It writes an XML document describing the sales **order** with that `No.` to `ExportStream`. The document looks like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<SalesOrder no="101005" customerNo="10000" orderDate="2026-03-15">
  <Customer>
    <Name>O'Brien &amp; Sons</Name>
  </Customer>
  <Lines>
    <Line lineNo="10000" no="1896-S" description="ATHENS Desk" quantity="2.5" unitPrice="1234.56" />
    <Line lineNo="20000" no="1900-S" description="PARIS Guest Chair" quantity="7" unitPrice="193.7" />
  </Lines>
</SalesOrder>
```

Rules:

1. The root element is `SalesOrder` with three attributes: `no` = the order's `"No."`, `customerNo` = its `"Sell-to Customer No."`, and `orderDate` = its `"Order Date"` rendered as `yyyy-mm-dd` (for example `2026-03-15`) — regardless of the server's regional settings.
2. The root contains a `Customer` element with a `Name` child element whose text content is the sell-to customer's `Name`, reproduced exactly — whatever apostrophes, ampersands or angle brackets it contains.
3. The root contains a `Lines` element with one `Line` element per sales line of the order, in ascending `"Line No."` order — whatever the line's type (items, G/L accounts, resources, ...). Lines whose `"No."` is empty are skipped entirely, and an empty `"No."` is the *only* thing that skips a line: a comment line is skipped because its `"No."` is empty, not because of its type.
4. Each `Line` element carries five attributes: `lineNo` = `"Line No."`, `no` = `"No."`, `description` = `Description` reproduced exactly, `quantity` = `Quantity` and `unitPrice` = `"Unit Price"`. Numbers use a dot as the decimal separator, no digit grouping (`1234.5`, never `1,234.5` or `1.234,5`) and the fewest digits needed — no trailing decimal zeros (`193.7`, never `193.70`) and no decimal point on whole numbers (`7`) — again regardless of regional settings.
5. The document starts with an XML declaration with version `1.0` and encoding `UTF-8` (the casing of the encoding name is not graded).
6. The finished document is written to `ExportStream` and must re-parse as well-formed XML — special characters in names and descriptions have to survive a full write/read round trip.

## What the tests check

The grading tests create sales orders with generated customers, items, quantities and prices, call `ExportOrder` into a temporary blob, re-parse the result with the platform's XML parser and assert nodes and attributes via XPath. Output that fails to parse fails every check, so escaping is non-negotiable: one test plants `& ' < >` in the customer name, another plants `" & < >` in a line description and expects both back character for character. Amounts above 1000 and a generated order date with single-digit day and month catch locale-dependent formatting and missing zero-padding; a line with quantity `7` at unit price `193.7` must render exactly those strings — no `7.00`, no `193.70`. The skip rule is graded from both sides: a description-only comment line and an item line with an empty `"No."` produce no `Line` element, while a G/L account line with a `"No."` produces one. Indentation, attribute order and the position of `Customer` relative to `Lines` inside the root are **not graded** — the parsed structure is.

## Learn More

- [XmlDocument data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type)
- [XmlElement.Create(Text, Any,...) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-create-string-joker-method)
- [XmlDeclaration.Create(Text, Text, Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldeclaration/xmldeclaration-create-method)
- [XmlDocument.WriteTo(OutStream) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-writeto-outstream-method)
- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property)
