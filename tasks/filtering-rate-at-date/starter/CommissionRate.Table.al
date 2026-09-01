table 50100 "Commission Rate"
{
    Caption = 'Commission Rate';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(3; "Rate %"; Decimal)
        {
            Caption = 'Rate %';
        }
    }

    keys
    {
        key(PK; "Salesperson Code", "Starting Date")
        {
            Clustered = true;
        }
    }
}
