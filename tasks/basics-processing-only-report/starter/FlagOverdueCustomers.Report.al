report 50100 "Flag Overdue Customers"
{
    Caption = 'Flag Overdue Customers';
    // TODO: make this a processing-only report that runs without a request page.

    dataset
    {
        dataitem(Customer; Customer)
        {
            trigger OnPreDataItem()
            begin
                // TODO: narrow the caller's selection to customers that are not blocked.
            end;

            trigger OnAfterGetRecord()
            begin
                // TODO: calculate "Balance Due (LCY)"; skip the customer when nothing is due,
                // otherwise set "Follow-Up Required" and save the record.
            end;
        }
    }

    procedure GetFlaggedCount(): Integer
    begin
        // TODO: return how many customers the last run flagged.
    end;
}
