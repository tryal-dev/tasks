table 50101 "Loyalty Visit"
{
    Caption = 'Loyalty Visit';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(2; "Member No."; Code[20])
        {
            Caption = 'Member No.';
            DataClassification = CustomerContent;
            TableRelation = "Loyalty Member"."Member No.";
        }
        field(3; "Visit Date"; Date)
        {
            Caption = 'Visit Date';
            DataClassification = CustomerContent;
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = CustomerContent;
        }
        field(5; "Device Id"; Text[50])
        {
            Caption = 'Device Id';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(6; "Partner Store Code"; Code[20])
        {
            Caption = 'Partner Store Code';
            DataClassification = OrganizationIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
