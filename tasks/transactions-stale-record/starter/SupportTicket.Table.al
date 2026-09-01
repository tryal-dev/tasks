table 50100 "Support Ticket"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ticket No."; Code[20]) { }
        field(2; Description; Text[100]) { }
        field(3; Priority; Integer) { }
        field(4; Resolved; Boolean) { }
        field(5; "Resolution Note"; Text[100]) { }
    }

    keys
    {
        key(PK; "Ticket No.") { Clustered = true; }
    }
}
