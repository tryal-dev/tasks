table 50101 "Dispatch Run Log"
{
    Caption = 'Dispatch Run Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Job Code"; Code[20])
        {
            Caption = 'Job Code';
        }
        field(3; "Target Record ID"; RecordId)
        {
            Caption = 'Target Record ID';
        }
        field(4; Succeeded; Boolean)
        {
            Caption = 'Succeeded';
        }
        field(5; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
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
