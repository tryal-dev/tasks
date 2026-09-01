table 50100 "Reversible Ledger Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Document No."; Code[20]) { }
        field(3; "Posting Date"; Date) { }
        field(4; "Account No."; Code[20]) { }
        field(5; Description; Text[50]) { }
        field(6; Amount; Decimal) { }
        field(7; Quantity; Decimal) { }
        field(8; "Applied Amount"; Decimal) { }
        field(9; Reversed; Boolean) { }
        field(10; "Reversed by Entry No."; Integer) { }
        field(11; "Reversed Entry No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Document; "Document No.", "Reversed Entry No.") { }
    }
}
