// Given object — submit it unchanged alongside your statement builder.
table 50101 "Wallet Statement Line"
{
    Caption = 'Wallet Statement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Running Balance"; Decimal)
        {
            Caption = 'Running Balance';
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
