// Given object — submit it unchanged alongside your archive table and archiver.
table 50101 "Rental Charge"
{
    Caption = 'Rental Charge';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(PK; "Contract No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
    }
}
