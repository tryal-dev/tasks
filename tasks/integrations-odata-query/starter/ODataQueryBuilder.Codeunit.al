codeunit 50100 "OData Query Builder"
{
    procedure OrdersByCustomerUrl(CustomerName: Text; FromDate: Date; ToDate: Date): Text
    begin
        // TODO: return the endpoint with $filter=(CustomerName eq <name>) and (OrderDate ge <from>) and (OrderDate le <to>)
    end;

    procedure OpenOrderSearchUrl(SearchText: Text; MaxRows: Integer): Text
    begin
        // TODO: return the endpoint with the open-orders search $filter, then $top=<MaxRows>
    end;

    procedure RecentOrdersUrl(RowCount: Integer): Text
    begin
        // TODO: return the endpoint with $select, then $orderby, then $top=<RowCount>
    end;

    procedure Fetch(RequestUri: Text; HttpClientHandler: Interface "Http Client Handler"; var ResponseBody: Text): Boolean
    begin
        // TODO: GET RequestUri through the handler and report whether the service answered with a success status
    end;
}
