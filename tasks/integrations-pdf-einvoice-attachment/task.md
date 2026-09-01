# The Invoice Inside the PDF

Your vendors have started sending ZUGFeRD invoices: one PDF/A-3 file that is both the invoice a person reads and the invoice a machine reads, because the structured invoice XML travels *inside* the PDF as an embedded file. Business Central's German localization works exactly this way — it attaches the XML when it renders a sales invoice, and it pulls the XML back out of every carrier PDF a vendor sends. You are writing the inbound half: open the PDF, take the e-invoice out of it, and stage what it says.

A carrier PDF is an ordinary PDF — any number of pages, any layout — that carries exactly one embedded file, named `factur-x.xml`, `xrechnung.xml` or `zugferd-invoice.xml` depending on which flavour of the standard the sender used. A plain PDF (a scan, or an invoice printed to file) carries no embedded file at all, and there is nothing to import from it. You never touch PDF bytes yourself: Business Central can read a document's page count and its embedded files for you.

## The embedded invoice

The attachment is UTF-8 XML in the Cross-Industry Invoice (CII) format. Trimmed to what this task needs, with example values:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rsm:CrossIndustryInvoice xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100" xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100" xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100">
  <rsm:ExchangedDocumentContext>
    <ram:GuidelineSpecifiedDocumentContextParameter>
      <ram:ID>urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basicwl</ram:ID>
    </ram:GuidelineSpecifiedDocumentContextParameter>
  </rsm:ExchangedDocumentContext>
  <rsm:ExchangedDocument>
    <ram:ID>INV-9000</ram:ID>
    <ram:TypeCode>380</ram:TypeCode>
    <ram:IssueDateTime>
      <udt:DateTimeString format="102">20250731</udt:DateTimeString>
    </ram:IssueDateTime>
  </rsm:ExchangedDocument>
  <rsm:SupplyChainTradeTransaction>
    <ram:ApplicableHeaderTradeAgreement>
      <ram:SellerTradeParty>
        <ram:Name>Example Vendor GmbH</ram:Name>
      </ram:SellerTradeParty>
      <ram:BuyerTradeParty>
        <ram:Name>CRONUS International Ltd.</ram:Name>
      </ram:BuyerTradeParty>
    </ram:ApplicableHeaderTradeAgreement>
    <ram:ApplicableHeaderTradeDelivery />
    <ram:ApplicableHeaderTradeSettlement>
      <ram:InvoiceCurrencyCode>EUR</ram:InvoiceCurrencyCode>
      <ram:SpecifiedTradeSettlementHeaderMonetarySummation>
        <ram:LineTotalAmount>100.00</ram:LineTotalAmount>
        <ram:TaxBasisTotalAmount>100.00</ram:TaxBasisTotalAmount>
        <ram:GrandTotalAmount>119.00</ram:GrandTotalAmount>
        <ram:TotalPrepaidAmount>20.00</ram:TotalPrepaidAmount>
        <ram:DuePayableAmount>99.00</ram:DuePayableAmount>
      </ram:SpecifiedTradeSettlementHeaderMonetarySummation>
    </ram:ApplicableHeaderTradeSettlement>
  </rsm:SupplyChainTradeTransaction>
</rsm:CrossIndustryInvoice>
```

Every element above belongs to one of three namespaces, and the URIs — not the prefixes — are what identifies them:

- `rsm` → `urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100`
- `ram` → `urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100`
- `udt` → `urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100`

## Requirements

The starter ships two objects. Submit the table `"E-Invoice Staging"` **unchanged** — the tests read its fields one by one. Your work is the body of the codeunit `"E-Invoice PDF Import"`, which has one public procedure:

```al
procedure ImportFromPdf(var PdfTempBlob: Codeunit "Temp Blob"): Integer
```

`PdfTempBlob` holds the bytes of the incoming PDF file.

Rules:

1. One call stages exactly one `"E-Invoice Staging"` record and returns its `"Entry No."` — the field is auto-incremented, so read it back off the record after inserting.
2. `"Page Count"` is the number of pages of the carrier PDF, not of anything inside it.
3. `"Attachment Name"` is the file name under which the e-invoice XML sits inside the PDF, exactly as the document records it (`factur-x.xml`, `zugferd-invoice.xml`, …).
4. The remaining fields come from the embedded XML, at these paths below the `rsm:CrossIndustryInvoice` root:

   | Staging field | Element |
   |---|---|
   | `"Invoice No."` | `rsm:ExchangedDocument` / `ram:ID` |
   | `"Invoice Date"` | `rsm:ExchangedDocument` / `ram:IssueDateTime` / `udt:DateTimeString` |
   | `"Vendor Name"` | `rsm:SupplyChainTradeTransaction` / `ram:ApplicableHeaderTradeAgreement` / `ram:SellerTradeParty` / `ram:Name` |
   | `"Currency Code"` | `rsm:SupplyChainTradeTransaction` / `ram:ApplicableHeaderTradeSettlement` / `ram:InvoiceCurrencyCode` |
   | `"Total Amount"` | `rsm:SupplyChainTradeTransaction` / `ram:ApplicableHeaderTradeSettlement` / `ram:SpecifiedTradeSettlementHeaderMonetarySummation` / `ram:GrandTotalAmount` |

5. Note the near-misses in that document: `ram:ID` also appears under `ram:GuidelineSpecifiedDocumentContextParameter`, `ram:Name` also appears under `ram:BuyerTradeParty`, and the monetary summation carries `ram:LineTotalAmount`, `ram:TaxBasisTotalAmount`, `ram:TotalPrepaidAmount` and `ram:DuePayableAmount` alongside the grand total — all with values of their own.
6. Dates arrive as `YYYYMMDD` (that is what `format="102"` means); amounts arrive with a decimal point and no thousands separator.
7. A PDF that carries no embedded e-invoice XML has nothing to stage: raise an error with a message that contains the text `has no e-invoice attachment`.

Pick your object IDs in the range 50100–50199, and reference other objects by name — never by numeric ID.

## What the tests check

The grading tests hand your codeunit three real PDF files. Two are carrier documents with different page counts (2 and 3), different attachment names (`factur-x.xml` and `zugferd-invoice.xml`) and different invoice content, and for each one the tests compare all seven staged fields — invoice number, date, vendor name, currency, grand total, attachment name and page count — against what that PDF actually contains, so a value hardcoded from one document fails on the other. Every comparison is exact, which the near-miss elements punish: reading `ram:DuePayableAmount`, `ram:TaxBasisTotalAmount` or `ram:LineTotalAmount` instead of the grand total is a failed test, and so is the buyer's name in place of the seller's, or a `ram:ID` taken from the guideline parameter. One test checks that a single call adds exactly one staging record. The third file is a plain PDF with no attachment at all: importing it must raise an error with a message that contains `has no e-invoice attachment` — spelled exactly like that, since the check is a substring match.

## Learn More

- [Electronic invoicing in Germany](https://learn.microsoft.com/en-us/dynamics365/business-central/localfunctionality/germany/germany-einvoicing) — the shipped feature this task reproduces: ZUGFeRD is a PDF/A format, and Business Central extracts the embedded XML from it.
- [Temp Blob codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.temp-blob) — the in-memory byte container in your signature, and the streams it hands out.
- [XmlDocument.ReadFrom(InStream, var XmlDocument) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-readfrom-instream-xmldocument-method) — parsing the extracted attachment straight off a stream.
- [XmlNamespaceManager data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnamespacemanager/xmlnamespacemanager-data-type) — resolving the three CII namespaces so your XPath expressions can name them.
