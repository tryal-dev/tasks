codeunit 50101 "Customer Welcome"
{
    // TODO: tie the codeunit to the Customer table so OnRun receives the
    // caller's record as Rec.

    trigger OnRun()
    begin
        // TODO: hand the record you were run with to Apply.
    end;

    procedure Apply(var Customer: Record Customer)
    begin
        // TODO: stamp the welcome note and default the payment terms.
    end;
}
