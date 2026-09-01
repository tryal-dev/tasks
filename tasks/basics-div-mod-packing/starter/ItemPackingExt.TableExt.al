tableextension 50100 "Item Packing Ext" extends Item
{
    fields
    {
        field(50100; "Units per Box"; Integer)
        {
            Caption = 'Units per Box';
        }
        field(50101; "Boxes per Pallet"; Integer)
        {
            Caption = 'Boxes per Pallet';
        }
    }
}
