table 50100 "Dispatch Setup"
{
    Caption = 'Dispatch Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Default Carrier Code"; Code[20])
        {
            Caption = 'Default Carrier Code';
        }
        field(3; "Max Package Weight"; Decimal)
        {
            Caption = 'Max Package Weight';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
