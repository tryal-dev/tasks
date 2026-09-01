codeunit 50101 "E-Invoice PDF Import"
{
    procedure ImportFromPdf(var PdfTempBlob: Codeunit "Temp Blob"): Integer
    begin
        // TODO: Report the carrier PDF's page count and the name of the file embedded in
        // it, take that embedded e-invoice XML out of the PDF, map the invoice header
        // onto one new "E-Invoice Staging" record and return its "Entry No.".
        // A PDF without an embedded e-invoice stages nothing and raises an error whose
        // message contains 'has no e-invoice attachment'.
    end;
}
