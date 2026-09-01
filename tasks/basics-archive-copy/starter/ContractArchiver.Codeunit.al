codeunit 50103 "Contract Archiver"
{
    procedure Archive(ContractNo: Code[20]; ArchivedOn: Date)
    begin
        // TODO: copy the contract into "Rental Contract Archive", snapshot the
        // calculated total, stamp ArchivedOn, then delete the original.
    end;
}
