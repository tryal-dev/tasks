tableextension 50100 CustomerOnboardingExt extends Customer
{
    fields
    {
        field(50100; "First Registered On"; Date)
        {
            Caption = 'First Registered On';
        }
        field(50101; "Review Status"; Code[10])
        {
            Caption = 'Review Status';
        }
    }

    // TODO: add an OnBeforeInsert trigger that stamps the defaults.
}
