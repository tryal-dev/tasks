table 50100 "Import Order Line"
{
    Caption = 'Import Order Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch Code"; Code[20])
        {
            Caption = 'Batch Code';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(5; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
        }
    }

    keys
    {
        key(PK; "Batch Code", "Line No.")
        {
            Clustered = true;
        }
    }
}
