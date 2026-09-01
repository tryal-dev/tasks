table 50100 "Archived Document"
{
    Caption = 'Archived Document';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Department Code"; Code[20])
        {
            Caption = 'Department Code';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Recorded Size"; Integer)
        {
            Caption = 'Recorded Size';
        }
        field(5; Content; Blob)
        {
            Caption = 'Content';
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
