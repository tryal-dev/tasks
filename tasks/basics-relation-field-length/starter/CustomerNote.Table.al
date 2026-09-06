table 50100 "Customer Note"
{
    Caption = 'Customer Note';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Customer No."; Code[10])
        {
            Caption = 'Customer No.';
            // TODO: this field points at Customer."No.", which is Code[20]. A customer
            // numbered CUST-2024-000123 does not fit, and AddNote dies with a
            // string-overflow error. Make the field match the key it relates to.
            TableRelation = Customer;
        }
        field(3; Note; Text[250])
        {
            Caption = 'Note';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
