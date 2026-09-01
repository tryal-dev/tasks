table 50100 "Gilded Item"
{
    Caption = 'Gilded Item';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Category; Enum "Gilded Item Category")
        {
            Caption = 'Category';
        }
        field(3; "Sell In"; Integer)
        {
            Caption = 'Sell In';
        }
        field(4; Quality; Integer)
        {
            Caption = 'Quality';
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
