page 50100 "TryAL Agent Customer API"
{
    PageType = API;
    APIPublisher = 'tryal';
    APIGroup = 'agent';
    APIVersion = 'v2.0';
    EntityName = 'agentCustomer';
    EntitySetName = 'agentCustomers';
    EntityCaption = 'Agent Customer';
    EntitySetCaption = 'Agent Customers';
    SourceTable = Customer;
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
                field(phoneNumber; Rec."Phone No.")
                {
                    Caption = 'Phone Number';
                }
            }
        }
    }
}
