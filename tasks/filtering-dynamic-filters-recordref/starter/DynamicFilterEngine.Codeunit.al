codeunit 50102 "Dynamic Filter Engine"
{
    procedure CountWithConfiguredFilters(TableId: Integer; var AppliedFilters: Text): Integer
    begin
        // TODO: open the table behind TableId, turn every "Dynamic Filter Line"
        // row configured for it into a real filter, report the applied filters
        // through AppliedFilters and return how many records are left.
        AppliedFilters := '';
        exit(0);
    end;
}
