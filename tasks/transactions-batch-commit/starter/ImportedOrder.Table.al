table 50101 "Imported Order"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Customer No."; Code[20]) { }
        field(4; Quantity; Decimal) { }
    }

    keys
    {
        key(PK; "Batch Code", "Line No.") { Clustered = true; }
    }
}
