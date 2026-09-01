enumextension 50901 "Carrier Status Test Ext" extends "Carrier Status"
{
    value(75; Returned)
    {
        // The caption deliberately differs from the name: a ToWireName built
        // on Format() returns this caption instead of 'Returned' and fails.
        // The ordinal is not graded literally — the tests read it back by name.
        Caption = 'Sent back to sender';
    }
}
