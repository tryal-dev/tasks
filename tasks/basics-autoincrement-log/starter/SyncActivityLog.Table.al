table 50100 "Sync Activity Log"
{
    Caption = 'Sync Activity Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            // TODO: let the database number this field.
        }
        field(2; Message; Text[250])
        {
            Caption = 'Message';
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
