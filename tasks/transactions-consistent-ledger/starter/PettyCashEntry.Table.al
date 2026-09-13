table 50100 "Petty Cash Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Document No."; Code[20]) { }
        field(3; "Account No."; Code[20]) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Account; "Account No.") { SumIndexFields = Amount; }
    }
}
