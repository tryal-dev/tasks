table 50101 "Stock Count Line"
{
    Caption = 'Stock Count Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            // TODO: when "Item No." is validated with a different item than the
            // line already carries, blank "Variant Code".
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            // TODO: relate to the Code of "Item Variant", but only to the
            // variants of the line's own item.
        }
        field(20; "Counted Quantity"; Decimal)
        {
            Caption = 'Counted Quantity';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
