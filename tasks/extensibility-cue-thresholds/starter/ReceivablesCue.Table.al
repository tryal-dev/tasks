table 50100 "Receivables Cue"
{
    Caption = 'Receivables Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        // TODO: add the "Overdue Amount" field.
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
