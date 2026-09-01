table 50100 "Payslip Setup"
{
    Caption = 'Payslip Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Personal Allowance"; Decimal)
        {
            Caption = 'Personal Allowance';
        }
        field(3; "Taper Threshold"; Decimal)
        {
            Caption = 'Taper Threshold';
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
