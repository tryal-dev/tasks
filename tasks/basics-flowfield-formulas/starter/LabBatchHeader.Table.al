table 50100 "Lab Batch Header"
{
    Caption = 'Lab Batch Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        // TODO: add the "Date Filter" flow filter and the eight calculated
        // fields listed in the task statement.
    }

    keys
    {
        key(PK; "Batch No.")
        {
            Clustered = true;
        }
    }
}
