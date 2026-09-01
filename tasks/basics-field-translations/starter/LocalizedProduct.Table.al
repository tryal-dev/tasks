table 50100 "Localized Product"
{
    Caption = 'Localized Product';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        // TODO: remove every translation stored for this record — and only this record's.
    end;
}
