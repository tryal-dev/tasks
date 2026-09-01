table 50100 "Estimate Line"
{
    Caption = 'Estimate Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
            // TODO: when Type is validated with a different value than the line
            // already carries, blank "No." and Description.
        }
        field(11; "No."; Code[20])
        {
            Caption = 'No.';
            // TODO: relate "No." to Item, Resource or "G/L Account" — whichever
            // one the current Type stands for — and default Description from the
            // record it points at.
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(30; "Catalog Ref."; Code[20])
        {
            Caption = 'Catalog Ref.';
            // TODO: relate to Item for the lookup, but let any code through.
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
