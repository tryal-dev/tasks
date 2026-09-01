namespace TryAL.Dispatch;

table 50900 DispatchProbeTicket
{
    Caption = 'Dispatch Probe Ticket';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ticket No."; Code[20])
        {
            Caption = 'Ticket No.';
        }
        field(2; Status; Text[50])
        {
            Caption = 'Status';
        }
        field(3; Corrupted; Boolean)
        {
            Caption = 'Corrupted';
        }
    }

    keys
    {
        key(PK; "Ticket No.")
        {
            Clustered = true;
        }
    }
}
