tableextension 50101 "Customer Phone Audit Ext" extends Customer
{
    fields
    {
        field(50100; "Phone Review Needed"; Boolean)
        {
            Caption = 'Phone Review Needed';
            DataClassification = CustomerContent;
        }
    }
}
