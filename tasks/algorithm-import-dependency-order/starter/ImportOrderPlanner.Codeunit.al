codeunit 50100 "Import Order Planner"
{
    procedure AddTable(TableID: Integer)
    begin
        // TODO: stage the table for import; staging the same ID again has no further effect
    end;

    procedure AddDependency(TableID: Integer; DependsOnTableID: Integer)
    begin
        // TODO: record that TableID's records reference DependsOnTableID, so it must be imported first
    end;

    procedure GetImportOrder(var ImportOrder: List of [Integer])
    begin
        // TODO: empty ImportOrder, then fill it with every staged table in a valid, deterministic import order
    end;
}
