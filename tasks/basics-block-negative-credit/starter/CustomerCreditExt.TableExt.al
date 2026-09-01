tableextension 50100 CustomerCreditExt extends Customer
{
    fields
    {
        field(50100; "Internal Credit Limit"; Decimal)
        {
            Caption = 'Internal Credit Limit';
            // TODO: reject negative values from an OnValidate trigger.
        }
    }
}
