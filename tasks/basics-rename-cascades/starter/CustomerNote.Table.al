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
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            // TODO: this field must move with the customer when it is renamed.
            // Declare the relation that makes the platform treat it as a reference.
        }
        field(3; "Legacy Customer No."; Code[20])
        {
            Caption = 'Legacy Customer No.';
            // Deliberately no relation: the number the note was filed under must never change.
        }
        field(4; Note; Text[250])
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
        key(CustomerNo; "Customer No.")
        {
        }
    }
}
