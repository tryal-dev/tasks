// Provided as-is: the grading tests read this table by name.
table 50100 "Legacy Amount Entry"
{
    Caption = 'Legacy Amount Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry Code"; Code[20])
        {
            Caption = 'Entry Code';
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(PK; "Entry Code")
        {
            Clustered = true;
        }
    }
}
