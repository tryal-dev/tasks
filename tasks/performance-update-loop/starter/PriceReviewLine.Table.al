table 50100 "Price Review Line"
{
    Caption = 'Price Review Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
        }
        field(3; "Markup %"; Decimal)
        {
            Caption = 'Markup %';
        }
        field(4; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
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
