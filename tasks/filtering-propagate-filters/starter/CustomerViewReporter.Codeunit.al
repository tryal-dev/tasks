codeunit 50100 "Customer View Reporter"
{
    procedure CountInView(var FilteredCustomer: Record Customer): Integer
    begin
        exit(FilteredCustomer.Count());
    end;

    procedure CountBlockedInView(var FilteredCustomer: Record Customer): Integer
    begin
        // TODO: the count is right, but this narrows the CALLER's own view
        // and never restores it — the support ticket from the statement.
        FilteredCustomer.SetFilter(Blocked, '<>%1', FilteredCustomer.Blocked::" ");
        exit(FilteredCustomer.Count());
    end;

    procedure DescribeView(var FilteredCustomer: Record Customer): Text
    begin
        // TODO: report the view actually applied to the caller's record.
        exit('');
    end;
}
