tableextension 50100 ItemPricingExt extends Item
{
    fields
    {
        field(50100; "Markup %"; Decimal)
        {
            Caption = 'Markup %';
            // TODO: recalculate "Suggested Price" when this field is validated.
        }
        field(50101; "Suggested Price"; Decimal)
        {
            Caption = 'Suggested Price';
        }
    }
}
