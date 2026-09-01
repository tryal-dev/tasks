table 50102 "Vault Delete Log"
{
    Caption = 'Vault Delete Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(3; "Document Code"; Code[20])
        {
            Caption = 'Document Code';
        }
        field(4; Title; Text[100])
        {
            Caption = 'Title';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Document; "Document Code")
        {
        }
    }
}
