table 50102 "NI Contribution Band"
{
    Caption = 'NI Contribution Band';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; Threshold; Decimal)
        {
            Caption = 'Threshold';
        }
        field(3; "Rate %"; Decimal)
        {
            Caption = 'Rate %';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
        key(ByThreshold; Threshold)
        {
        }
    }
}
