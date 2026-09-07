tableextension 50100 "Customer Welcome Ext" extends Customer
{
    fields
    {
        field(50100; "Welcome Note"; Text[250])
        {
            Caption = 'Welcome Note';
            DataClassification = CustomerContent;
        }
    }
}
