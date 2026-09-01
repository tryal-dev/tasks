codeunit 50900 "E-Invoice PDF Import Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [E-Invoice] [PDF]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StagesTheHeaderOfTheFacturXInvoice()
    var
        EInvoiceStaging: Record "E-Invoice Staging";
        Fixtures: Codeunit "E-Invoice PDF Fixtures";
        EInvoicePdfImport: Codeunit "E-Invoice PDF Import";
        PdfTempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        EntryNo: Integer;
    begin
        // [SCENARIO] The invoice header of a Factur-X carrier PDF reaches the staging record
        // [GIVEN] A two-page PDF carrying factur-x.xml for invoice INV-1001
        Fixtures.FacturXCarrierPdf(PdfTempBlob);

        // [WHEN] Importing that PDF
        EntryNo := EInvoicePdfImport.ImportFromPdf(PdfTempBlob);

        // [THEN] Every header field comes from the embedded XML, near-misses avoided
        GetStagedRecord(EntryNo, EInvoiceStaging);
        Assert.AreEqual('INV-1001', Format(EInvoiceStaging."Invoice No."),
            'Expected "Invoice No." to come from rsm:ExchangedDocument/ram:ID, not from the guideline parameter');
        Assert.AreEqual(DMY2Date(15, 1, 2025), EInvoiceStaging."Invoice Date",
            'Expected "Invoice Date" to be udt:DateTimeString 20250115 read as a date (YYYYMMDD)');
        Assert.AreEqual('Nordwind Papier GmbH', EInvoiceStaging."Vendor Name",
            'Expected "Vendor Name" to come from ram:SellerTradeParty/ram:Name, not from the buyer');
        Assert.AreEqual('EUR', Format(EInvoiceStaging."Currency Code"),
            'Expected "Currency Code" to come from ram:InvoiceCurrencyCode');
        Assert.AreEqual(1234.56, EInvoiceStaging."Total Amount",
            'Expected "Total Amount" to be ram:GrandTotalAmount, not the line total, tax basis or due amount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StagesASecondCarrierWithoutReusingTheFirstValues()
    var
        EInvoiceStaging: Record "E-Invoice Staging";
        Fixtures: Codeunit "E-Invoice PDF Fixtures";
        EInvoicePdfImport: Codeunit "E-Invoice PDF Import";
        PdfTempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        EntryNo: Integer;
    begin
        // [SCENARIO] A second carrier PDF stages its own values, in another currency and flavour
        // [GIVEN] A three-page PDF carrying zugferd-invoice.xml for invoice RE-2024-0077
        Fixtures.ZugferdCarrierPdf(PdfTempBlob);

        // [WHEN] Importing that PDF
        EntryNo := EInvoicePdfImport.ImportFromPdf(PdfTempBlob);

        // [THEN] All seven staged fields describe this document, not the Factur-X one
        GetStagedRecord(EntryNo, EInvoiceStaging);
        Assert.AreEqual('RE-2024-0077', Format(EInvoiceStaging."Invoice No."),
            'Expected "Invoice No." to be read from this document''s rsm:ExchangedDocument/ram:ID');
        Assert.AreEqual(DMY2Date(3, 11, 2024), EInvoiceStaging."Invoice Date",
            'Expected "Invoice Date" to be udt:DateTimeString 20241103 read as a date (YYYYMMDD)');
        Assert.AreEqual('Contoso Buerobedarf AG', EInvoiceStaging."Vendor Name",
            'Expected "Vendor Name" to be this document''s ram:SellerTradeParty/ram:Name');
        Assert.AreEqual('USD', Format(EInvoiceStaging."Currency Code"),
            'Expected "Currency Code" to be this document''s ram:InvoiceCurrencyCode');
        Assert.AreEqual(87.5, EInvoiceStaging."Total Amount",
            'Expected "Total Amount" to be this document''s ram:GrandTotalAmount');
        Assert.AreEqual('zugferd-invoice.xml', EInvoiceStaging."Attachment Name",
            'Expected "Attachment Name" to be the name this PDF stores its attachment under');
        Assert.AreEqual(3, EInvoiceStaging."Page Count",
            'Expected "Page Count" to be the number of pages of this carrier PDF');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsThePageCountOfTheCarrierPdf()
    var
        EInvoiceStaging: Record "E-Invoice Staging";
        Fixtures: Codeunit "E-Invoice PDF Fixtures";
        EInvoicePdfImport: Codeunit "E-Invoice PDF Import";
        PdfTempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        EntryNo: Integer;
    begin
        // [SCENARIO] The staged page count is the carrier PDF's own page count
        // [GIVEN] A carrier PDF of two pages
        Fixtures.FacturXCarrierPdf(PdfTempBlob);

        // [WHEN] Importing that PDF
        EntryNo := EInvoicePdfImport.ImportFromPdf(PdfTempBlob);

        // [THEN] "Page Count" is 2
        GetStagedRecord(EntryNo, EInvoiceStaging);
        Assert.AreEqual(2, EInvoiceStaging."Page Count",
            'Expected "Page Count" to be the number of pages of the carrier PDF itself');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StagesTheNameOfTheEmbeddedAttachment()
    var
        EInvoiceStaging: Record "E-Invoice Staging";
        Fixtures: Codeunit "E-Invoice PDF Fixtures";
        EInvoicePdfImport: Codeunit "E-Invoice PDF Import";
        PdfTempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        EntryNo: Integer;
    begin
        // [SCENARIO] The file name the PDF stores its e-invoice under is staged
        // [GIVEN] A carrier PDF whose embedded file is named factur-x.xml
        Fixtures.FacturXCarrierPdf(PdfTempBlob);

        // [WHEN] Importing that PDF
        EntryNo := EInvoicePdfImport.ImportFromPdf(PdfTempBlob);

        // [THEN] "Attachment Name" is that file name, character for character
        GetStagedRecord(EntryNo, EInvoiceStaging);
        Assert.AreEqual('factur-x.xml', EInvoiceStaging."Attachment Name",
            'Expected "Attachment Name" to be the name the PDF records for its embedded file');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddsExactlyOneStagingRecordPerImportedPdf()
    var
        EInvoiceStaging: Record "E-Invoice Staging";
        Fixtures: Codeunit "E-Invoice PDF Fixtures";
        EInvoicePdfImport: Codeunit "E-Invoice PDF Import";
        PdfTempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        CountBefore: Integer;
    begin
        // [SCENARIO] One imported PDF becomes one staging record, whatever it contains
        // [GIVEN] A carrier PDF of two pages with one embedded e-invoice
        Fixtures.FacturXCarrierPdf(PdfTempBlob);
        CountBefore := EInvoiceStaging.Count();

        // [WHEN] Importing that PDF once
        EInvoicePdfImport.ImportFromPdf(PdfTempBlob);

        // [THEN] Exactly one record was added
        Assert.AreEqual(CountBefore + 1, EInvoiceStaging.Count(),
            'Expected one import to add exactly one "E-Invoice Staging" record - not one per page or per attachment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FailsWhenThePdfCarriesNoEInvoiceAttachment()
    var
        Fixtures: Codeunit "E-Invoice PDF Fixtures";
        EInvoicePdfImport: Codeunit "E-Invoice PDF Import";
        PdfTempBlob: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        EntryNo: Integer;
    begin
        // [SCENARIO] A plain PDF without an embedded e-invoice is refused with a clear error
        // [GIVEN] A one-page PDF that embeds no file at all
        Fixtures.PlainScanPdf(PdfTempBlob);

        // [WHEN] Importing that PDF
        asserterror EntryNo := EInvoicePdfImport.ImportFromPdf(PdfTempBlob);

        // [THEN] The error says the document has no e-invoice attachment
        Assert.ExpectedError('has no e-invoice attachment');
    end;

    local procedure GetStagedRecord(EntryNo: Integer; var EInvoiceStaging: Record "E-Invoice Staging")
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(EInvoiceStaging.Get(EntryNo),
            StrSubstNo('Expected ImportFromPdf to insert an "E-Invoice Staging" record and return its "Entry No.", got %1 with no such record', EntryNo));
    end;
}
