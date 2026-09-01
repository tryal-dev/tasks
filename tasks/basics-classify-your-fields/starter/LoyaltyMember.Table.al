table 50100 "Loyalty Member"
{
    Caption = 'Loyalty Member';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Member No."; Code[20])
        {
            Caption = 'Member No.';
            DataClassification = CustomerContent;
        }
        field(2; "Full Name"; Text[100])
        {
            Caption = 'Full Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "E-Mail"; Text[80])
        {
            Caption = 'E-Mail';
            DataClassification = EndUserIdentifiableInformation;
            ExtendedDatatype = EMail;
        }
        field(4; "Health Notes"; Text[250])
        {
            Caption = 'Health Notes';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Loyalty Discount"; Decimal)
        {
            Caption = 'Loyalty Discount';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
        }
        field(10; "Visit Count"; Integer)
        {
            Caption = 'Visit Count';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Loyalty Visit" where("Member No." = field("Member No.")));
        }
    }

    keys
    {
        key(PK; "Member No.")
        {
            Clustered = true;
        }
    }
}
