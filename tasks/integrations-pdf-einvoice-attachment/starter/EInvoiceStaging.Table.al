// Given object — submit it unchanged alongside your codeunit.
table 50100 "E-Invoice Staging"
{
    Caption = 'E-Invoice Staging';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
        }
        field(3; "Invoice Date"; Date)
        {
            Caption = 'Invoice Date';
        }
        field(4; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(6; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
        }
        field(7; "Attachment Name"; Text[250])
        {
            Caption = 'Attachment Name';
        }
        field(8; "Page Count"; Integer)
        {
            Caption = 'Page Count';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
