table 50101 "Web Order Line"
{
    Caption = 'Web Order Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(6; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
        }
    }

    keys
    {
        key(PK; "Order No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
