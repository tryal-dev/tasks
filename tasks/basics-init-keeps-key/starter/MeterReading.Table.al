table 50101 "Meter Reading"
{
    Caption = 'Meter Reading';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Reading Value"; Decimal)
        {
            Caption = 'Reading Value';
        }
        field(3; Status; Enum "Meter Reading Status")
        {
            Caption = 'Status';
            // TODO: a freshly initialized row must already be Pending.
        }
        field(4; Remark; Text[50])
        {
            Caption = 'Remark';
        }
        field(5; "Read On"; Date)
        {
            Caption = 'Read On';
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
