table 50100 "Vault Folder"
{
    Caption = 'Vault Folder';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Folder Code"; Code[20])
        {
            Caption = 'Folder Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Folder Code")
        {
            Clustered = true;
        }
    }

    // TODO: add the OnDelete trigger that deletes every "Vault Document"
    // belonging to this folder.
}
