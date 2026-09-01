table 50102 "Rental Contract Archive"
{
    Caption = 'Rental Contract Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        // TODO: add the fields the archive must carry.
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
