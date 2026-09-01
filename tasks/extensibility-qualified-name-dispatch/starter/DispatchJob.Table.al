table 50100 "Dispatch Job"
{
    Caption = 'Dispatch Job';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; "Target Table Name"; Text[250])
        {
            Caption = 'Target Table Name';
        }
        field(3; "Handler Name"; Text[250])
        {
            Caption = 'Handler Name';
        }
        field(4; "Current Record ID"; RecordId)
        {
            Caption = 'Current Record ID';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
