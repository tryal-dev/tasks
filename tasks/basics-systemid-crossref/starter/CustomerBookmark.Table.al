table 50100 "Customer Bookmark"
{
    Caption = 'Customer Bookmark';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        // TODO: add "Customer SystemId" (Guid) — the reference that survives a rename.
        // Leave "Customer No." as a plain snapshot: no table relation.
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
