table 50100 "Shelf Movement Entry"
{
    Caption = 'Shelf Movement Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Shelf Code"; Code[20])
        {
            Caption = 'Shelf Code';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
    }

    keys
    {
        // TODO: the primary key is the only key this table has — nothing here
        // keeps a total ready for the shelf inquiry, so every lookup re-reads rows.
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
