tableextension 50102 "Customer Region" extends Customer
{
    fields
    {
        field(50100; "Region Code"; Code[10])
        {
            Caption = 'Region Code';
            DataClassification = CustomerContent;
            // TODO: relate to "Sales Region", but only to the regions that are
            // not blocked.
        }
    }
}
