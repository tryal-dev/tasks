enum 50100 Carrier implements "IShipping Carrier"
{
    Extensible = true;

    value(0; "Ground Post")
    {
        Caption = 'Ground Post';
        Implementation = "IShipping Carrier" = "Ground Post Shipping";
    }
    value(1; "Express Air")
    {
        Caption = 'Express Air';
        Implementation = "IShipping Carrier" = "Express Air Shipping";
    }
}
