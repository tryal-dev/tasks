// Given object — submit it unchanged alongside your archiver.
table 50100 "Freight Charge"
{
    Caption = 'Freight Charge';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(11; "Unit Freight Cost"; Decimal)
        {
            Caption = 'Unit Freight Cost';
        }
        field(12; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(30; "Carrier Code"; Code[10])
        {
            Caption = 'Carrier Code';
        }
        field(90; Archived; Boolean)
        {
            Caption = 'Archived';
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
