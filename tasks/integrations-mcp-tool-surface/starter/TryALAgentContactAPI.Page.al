page 50102 "TryAL Agent Contact API"
{
    PageType = API;
    APIPublisher = 'tryal';
    APIGroup = 'agent';
    APIVersion = 'v2.0';
    EntityName = 'agentContact';
    EntitySetName = 'agentContacts';
    EntityCaption = 'Agent Contact';
    EntitySetCaption = 'Agent Contacts';
    SourceTable = Contact;
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(displayName; Rec.Name)
                {
                    Caption = 'Display Name';
                }
                field(email; Rec."E-Mail")
                {
                    Caption = 'Email';
                }
                field(phoneNumber; Rec."Phone No.")
                {
                    Caption = 'Phone Number';
                }
            }
        }
    }
}
