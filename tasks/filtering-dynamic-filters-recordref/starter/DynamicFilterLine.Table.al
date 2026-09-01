table 50101 "Dynamic Filter Line"
{
    Caption = 'Dynamic Filter Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(4; Operator; Enum "Dynamic Filter Operator")
        {
            Caption = 'Operator';
        }
        field(5; "Filter Value"; Text[250])
        {
            Caption = 'Filter Value';
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
