codeunit 50100 "Vat Registry Client"
{
    procedure CheckVat(CountryCode: Text; VatNumber: Text; HttpClientHandler: Interface "Http Client Handler"; var TraderName: Text; var FaultReason: Text): Boolean
    begin
        // TODO: build the SOAP 1.1 CheckVatRequest envelope, POST it through
        // HttpClientHandler with the Content-Type and SOAPAction headers from
        // the statement, then parse the namespaced response — trader name,
        // fault, or infrastructure junk.
    end;
}
