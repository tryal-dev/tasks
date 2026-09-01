codeunit 50101 "Receivables Cue Style"
{
    procedure RegisterThresholds(LowerThreshold: Decimal; UpperThreshold: Decimal): Boolean
    begin
        // TODO: record a company-wide indicator setup for the "Overdue Amount"
        // cue field: Favorable below LowerThreshold, Ambiguous in the middle,
        // Unfavorable above UpperThreshold. Return whether it was recorded.
    end;

    procedure StyleFor(Amount: Decimal): Enum "Cues And KPIs Style"
    begin
        // TODO: resolve the style the recorded setup assigns to Amount
        // (None when nothing has been registered).
    end;
}
