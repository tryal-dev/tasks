table 50100 "Follow-up Task"
{
    Caption = 'Follow-up Task';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(4; "Assigned To"; Text[50])
        {
            Caption = 'Assigned To';
        }
        field(5; "Created At"; DateTime)
        {
            Caption = 'Created At';
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
