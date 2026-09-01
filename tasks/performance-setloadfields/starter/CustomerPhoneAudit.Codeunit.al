codeunit 50100 "Customer Phone Audit"
{
    procedure BuildDirectory(var Customer: Record Customer): List of [Text]
    var
        Directory: List of [Text];
    begin
        // TODO: the lines below are right — the load shape is not. Every full
        // record fetched here drags all of Customer's wide row (and the table
        // extension's companion table) across the wire to read three fields.
        if Customer.FindSet() then
            repeat
                Directory.Add(StrSubstNo('%1|%2|%3', Customer."No.", Customer.Name, Customer."Phone No."));
            until Customer.Next() = 0;
        exit(Directory);
    end;

    procedure BuildContactSheet(var Customer: Record Customer): List of [Text]
    var
        Sheet: List of [Text];
    begin
        // TODO: the lines below are right — the cost is not. This pass hauls the
        // full row too, and grading also counts the SQL statements one call may
        // spend, however many phones turn out to be blank.
        if Customer.FindSet() then
            repeat
                if Customer."Phone No." <> '' then
                    Sheet.Add(StrSubstNo('%1|%2|%3', Customer."No.", Customer.Name, Customer."Phone No."))
                else
                    Sheet.Add(StrSubstNo('%1|%2|%3', Customer."No.", Customer.Name, Customer."E-Mail"));
            until Customer.Next() = 0;
        exit(Sheet);
    end;
}
