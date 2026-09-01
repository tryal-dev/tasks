// Given object — submit it unchanged alongside your archive table and archiver.
table 50100 "Rental Contract"
{
    Caption = 'Rental Contract';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(3; "Monthly Fee"; Decimal)
        {
            Caption = 'Monthly Fee';

            trigger OnValidate()
            begin
                if "Monthly Fee" < 0 then
                    Error(NegativeFeeErr);
            end;
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(20; "Total Charges"; Decimal)
        {
            Caption = 'Total Charges';
            FieldClass = FlowField;
            CalcFormula = sum("Rental Charge".Amount where("Contract No." = field("No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    var
        NegativeFeeErr: Label 'Monthly Fee must not be negative.';
}
