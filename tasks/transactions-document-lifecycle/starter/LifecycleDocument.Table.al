table 50101 "Lifecycle Document"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
        field(3; Amount; Decimal) { }
        field(4; Status; Enum "Lifecycle Document Status") { }
        field(5; "Posted On"; Date) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
