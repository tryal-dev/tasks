codeunit 50102 "Loyalty Data Classification"
{
    procedure ClassifyTable(TableNo: Integer): Boolean
    begin
        // TODO: refuse tables that are not supported and tables the extension does not
        // own, then set the whole table to the Normal baseline and apply the per-field
        // sensitivities listed in the task statement.
    end;

    procedure ClassifyField(TableNo: Integer; FieldNo: Integer; Sensitivity: Text)
    begin
        // TODO: reject a field number the table does not have, then record the
        // sensitivity for that one field.
    end;
}
