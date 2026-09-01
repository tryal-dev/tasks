// Given object — submit it unchanged alongside your XMLport.
table 50101 "Order Intake Line"
{
    Caption = 'Order Intake Line';
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
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Item No." = '' then begin
                    Description := '';
                    "Unit Price" := 0;
                end else begin
                    Item.Get("Item No.");
                    Description := Item.Description;
                    "Unit Price" := Item."Unit Price";
                end;

                UpdateAmount();
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                UpdateAmount();
            end;
        }
        field(6; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            Editable = false;
        }
        field(7; Amount; Decimal)
        {
            Caption = 'Amount';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Order No.", "Line No.")
        {
            Clustered = true;
        }
    }

    local procedure UpdateAmount()
    begin
        Amount := Round(Quantity * "Unit Price", 0.01);
    end;
}
