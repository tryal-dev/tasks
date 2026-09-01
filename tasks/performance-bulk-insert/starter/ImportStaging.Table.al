table 50100 "Import Staging"
{
    Caption = 'Import Staging';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "External No."; Code[20])
        {
            Caption = 'External No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
    }

    keys
    {
        key(PK; "External No.")
        {
            Clustered = true;
        }
    }
}
