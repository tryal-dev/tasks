codeunit 50100 "Endpoint Url Builder"
{
    procedure ItemSearchUrl(SearchTerm: Text; PageSize: Integer): Text
    begin
        // TODO: compose https://api.nordwind.example/v1/items?search=...&pageSize=...&includeArchived
    end;

    procedure ItemCardUrl(ItemNo: Text): Text
    begin
        // TODO: compose https://api.nordwind.example/v1/items/<item number as one encoded path segment>
    end;

    procedure ExportUrl(BaseUrl: Text; FileFormat: Text): Text
    begin
        // TODO: return BaseUrl with the format query parameter set to FileFormat, replacing any existing one
    end;
}
