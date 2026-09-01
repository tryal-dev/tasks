table 50100 "Sensor Reading"
{
    Caption = 'Sensor Reading';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Device Code"; Code[20])
        {
            Caption = 'Device Code';
        }
        field(3; "Value"; Decimal)
        {
            Caption = 'Value';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DeviceCode; "Device Code")
        {
        }
    }
}
