table 50100 "Item Change Entry"
{
    Caption = 'Item Change Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(3; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
        field(4; "Old Value"; Text[100])
        {
            Caption = 'Old Value';
        }
        field(5; "New Value"; Text[100])
        {
            Caption = 'New Value';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Item; "Item No.", "Field Name")
        {
        }
    }
}
