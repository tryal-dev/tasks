table 50101 "Customer Score Buffer"
{
    Caption = 'Customer Score Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(2; Score; Decimal)
        {
            Caption = 'Score';
        }
    }

    keys
    {
        key(PK; "Customer No.")
        {
            Clustered = true;
        }
        // TODO: add the secondary key the ranking is read in.
    }
}
