table 50100 "Web Order Header"
{
    Caption = 'Web Order Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(2; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(3; "Customer E-Mail"; Text[80])
        {
            Caption = 'Customer E-Mail';
        }
        field(4; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
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
