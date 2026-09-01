table 50100 "Workshop Order"
{
    Caption = 'Workshop Order';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        // TODO: when "No." is blank, draw the next number from the WORKSHOP
        // series and stamp "No. Series". A pre-set "No." must be kept.
    end;

    procedure PeekNextOrderNo(): Code[20]
    begin
        // TODO: return the upcoming WORKSHOP number without consuming it.
    end;
}
