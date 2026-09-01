// Given object — submit it unchanged alongside your statement builder.
table 50100 "Wallet Transaction"
{
    Caption = 'Wallet Transaction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Statement; "Account No.", "Posting Date", "Entry No.")
        {
        }
    }
}
