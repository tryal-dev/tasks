page 50101 "TryAL Agent Item API"
{
    PageType = API;
    APIPublisher = 'tryal';
    APIGroup = 'agent';
    APIVersion = 'v2.0';
    EntityName = 'agentItem';
    EntitySetName = 'agentItems';
    EntityCaption = 'Agent Item';
    EntitySetCaption = 'Agent Items';
    SourceTable = Item;
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
                field(displayName; Rec.Description)
                {
                    Caption = 'Display Name';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
            }
        }
    }
}
