table 50100 "Order Import Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Customer No."; Code[20]) { }
        field(4; Quantity; Decimal) { }
        field(5; Status; Enum "Order Import Status") { }
    }

    keys
    {
        key(PK; "Batch Code", "Line No.") { Clustered = true; }
    }
}
