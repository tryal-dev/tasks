table 50100 "Draft Journal Line"
{
    Caption = 'Draft Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch Name"; Code[10])
        {
            Caption = 'Batch Name';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(PK; "Batch Name", "Line No.")
        {
            Clustered = true;
        }
    }
}
