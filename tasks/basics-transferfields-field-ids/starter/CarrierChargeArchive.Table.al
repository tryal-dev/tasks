// Given object — the carrier integration vendor owns this table and picked
// its field numbers. Submit it unchanged: renumbering or retyping its fields
// is not your call, and the tests check that it still looks like this.
table 50101 "Carrier Charge Archive"
{
    Caption = 'Carrier Charge Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Discount Pct"; Decimal)
        {
            Caption = 'Discount Pct';

            trigger OnValidate()
            begin
                if ("Discount Pct" < 0) or ("Discount Pct" > 100) then
                    Error(DiscountOutOfRangeErr, "Discount Pct");
            end;
        }
        field(20; "Carrier Code"; Code[20])
        {
            Caption = 'Carrier Code';
        }
        field(35; "Charge Amount"; Decimal)
        {
            Caption = 'Charge Amount';
        }
        field(40; "Reference Text"; Text[30])
        {
            Caption = 'Reference Text';

            trigger OnValidate()
            begin
                "Reference Text" := UpperCase("Reference Text");
            end;
        }
        field(50; "Archived On"; Date)
        {
            Caption = 'Archived On';
        }
        field(60; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(70; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    var
        DiscountOutOfRangeErr: Label 'Discount Pct %1 is outside the range 0..100 allowed by the carrier archive.', Comment = '%1 = the rejected discount percentage';
}
