table 50101 "Bank Return Line"
{
    Caption = 'Bank Return Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reference No."; Code[20])
        {
            Caption = 'Reference No.';
        }
        field(2; "Payer Name"; Text[50])
        {
            Caption = 'Payer Name';
        }
        field(3; "Amount (Cents)"; Integer)
        {
            Caption = 'Amount (Cents)';
        }
        field(4; "Status Code"; Code[10])
        {
            Caption = 'Status Code';
        }
        field(5; "Bank Message"; Text[50])
        {
            Caption = 'Bank Message';
        }
    }

    keys
    {
        key(PK; "Reference No.")
        {
            Clustered = true;
        }
    }
}
