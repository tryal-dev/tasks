// Given object — submit it unchanged alongside your codeunit.
table 50100 "Shipment Note"
{
    Caption = 'Shipment Note';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(3; "Delivery Instructions"; Blob)
        {
            Caption = 'Delivery Instructions';
            Subtype = Memo;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
