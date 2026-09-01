namespace TryAL.Dispatch;

table 50901 DispatchProbeMeter
{
    Caption = 'Dispatch Probe Meter';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Meter No."; Integer)
        {
            Caption = 'Meter No.';
        }
        field(2; Reading; Decimal)
        {
            Caption = 'Reading';
        }
    }

    keys
    {
        key(PK; "Meter No.")
        {
            Clustered = true;
        }
    }
}
