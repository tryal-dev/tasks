tableextension 50100 "Customer Follow-Up" extends Customer
{
    fields
    {
        field(50100; "Follow-Up Required"; Boolean)
        {
            Caption = 'Follow-Up Required';
            DataClassification = CustomerContent;
        }
    }
}
