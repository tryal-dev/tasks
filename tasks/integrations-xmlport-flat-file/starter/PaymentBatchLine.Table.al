table 50100 "Payment Batch Line"
{
    Caption = 'Payment Batch Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Recipient No."; Code[10])
        {
            Caption = 'Recipient No.';
        }
        field(3; "Recipient Name"; Text[30])
        {
            Caption = 'Recipient Name';
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(5; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
