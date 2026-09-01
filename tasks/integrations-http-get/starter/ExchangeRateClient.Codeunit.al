codeunit 50100 "Exchange Rate Client"
{
    procedure GetRate(CurrencyCode: Text; HttpClientHandler: Interface "Http Client Handler"; var Rate: Decimal): Boolean
    begin
        // TODO: send one GET request through HttpClientHandler to
        // https://rates.example.com/v1/latest?symbol=<CurrencyCode>,
        // then honor the status and parsing contract from the statement.
    end;
}
