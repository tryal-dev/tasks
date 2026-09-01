table 50100 "Dimension Precheck Violation"
{
    Caption = 'Dimension Precheck Violation';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
        }
        field(3; "Value Posting"; Enum "Default Dimension Value Posting Type")
        {
            Caption = 'Value Posting';
        }
    }

    keys
    {
        key(PK; "Line No.", "Dimension Code")
        {
            Clustered = true;
        }
    }
}
