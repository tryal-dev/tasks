table 50100 "Loyalty Member"
{
    Caption = 'Loyalty Member';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Member No."; Code[20])
        {
            Caption = 'Member No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Enrolled On"; Date)
        {
            Caption = 'Enrolled On';
        }
        field(4; "Last Updated On"; Date)
        {
            Caption = 'Last Updated On';
        }
    }

    keys
    {
        key(PK; "Member No.")
        {
            Clustered = true;
        }
    }

    // TODO: add the OnInsert and OnModify triggers that stamp the audit dates.
}
