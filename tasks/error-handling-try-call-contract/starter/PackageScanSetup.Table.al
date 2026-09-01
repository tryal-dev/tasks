// Provided as-is: the grading tests read this table by name.
table 50100 "Package Scan Setup"
{
    Caption = 'Package Scan Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Code Length"; Integer)
        {
            Caption = 'Code Length';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
