codeunit 50101 "Staging Buffer"
{
    procedure AddLine(var StagingLine: Record "Import Staging Line"; ItemCode: Code[20]; Quantity: Decimal)
    begin
        // TODO: refuse a record variable that is not temporary with the error
        // described in the task statement, then append the next buffer line.
    end;

    procedure ProcessBuffer(var StagingLine: Record "Import Staging Line"): Decimal
    begin
        // TODO: refuse a record variable that is not temporary, mark every
        // buffer row Processed, and return the total Quantity.
    end;
}
