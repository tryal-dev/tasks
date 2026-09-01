enum 50100 "Shipping Fee Method" implements "Shipping Fee Calculator"
{
    Extensible = true;
    DefaultImplementation = "Shipping Fee Calculator" = "Shipping Fee Placeholder";

    // TODO: wire each value to its own calculator codeunit with
    // Implementation = "Shipping Fee Calculator" = <Your Codeunit Name>;
    // until then it falls back to the placeholder, which only raises an error.

    value(0; "Flat Rate")
    {
        Caption = 'Flat Rate';
    }
    value(1; "By Weight")
    {
        Caption = 'By Weight';
    }
    value(2; "Free Over Threshold")
    {
        Caption = 'Free Over Threshold';
    }
}

// TODO: add three calculator codeunits implementing "Shipping Fee Calculator"
// (their names are your choice), one per enum value, with the fee rules from
// the task statement. Once every value is wired, the placeholder may go.
