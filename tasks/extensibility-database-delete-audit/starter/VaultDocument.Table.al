table 50101 "Vault Document"
{
    Caption = 'Vault Document';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Code"; Code[20])
        {
            Caption = 'Document Code';
        }
        field(2; "Folder Code"; Code[20])
        {
            Caption = 'Folder Code';
            TableRelation = "Vault Folder"."Folder Code";
        }
        field(3; Title; Text[100])
        {
            Caption = 'Title';
        }
    }

    keys
    {
        key(PK; "Document Code")
        {
            Clustered = true;
        }
        key(Folder; "Folder Code")
        {
        }
    }
}
