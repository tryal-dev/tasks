// Provided as-is: the grading tests read this table by name.
table 50100 "Import Staging Line"
{
    Caption = 'Import Staging Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Item Code"; Code[20])
        {
            Caption = 'Item Code';
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(4; Processed; Boolean)
        {
            Caption = 'Processed';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
