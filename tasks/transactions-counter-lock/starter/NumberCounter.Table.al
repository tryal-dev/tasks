table 50100 "Number Counter"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Counter Code"; Code[20]) { }
        field(2; "Last Used No."; Integer) { }
    }

    keys
    {
        key(PK; "Counter Code") { Clustered = true; }
    }
}
