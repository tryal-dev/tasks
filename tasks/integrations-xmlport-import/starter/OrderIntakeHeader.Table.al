// Given object — submit it unchanged alongside your XMLport.
table 50100 "Order Intake Header"
{
    Caption = 'Order Intake Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                if "Customer No." = '' then begin
                    "Customer Name" := '';
                    exit;
                end;

                Customer.Get("Customer No.");
                "Customer Name" := Customer.Name;
            end;
        }
        field(3; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            Editable = false;
        }
        field(4; "Batch Id"; Code[20])
        {
            Caption = 'Batch Id';
        }
    }

    keys
    {
        key(PK; "Order No.")
        {
            Clustered = true;
        }
    }
}
