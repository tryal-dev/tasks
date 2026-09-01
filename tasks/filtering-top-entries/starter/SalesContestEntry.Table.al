table 50100 "Sales Contest Entry"
{
    Caption = 'Sales Contest Entry';
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
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(AmountKey; Amount)
        {
        }
    }
}
