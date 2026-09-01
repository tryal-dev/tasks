codeunit 50102 "Setup Seeder"
{
    procedure SeedFromResource(ResourceName: Text): Integer
    begin
        // TODO: If ResourceName is not among the shipped resources, raise an error that
        // names it AND lists every available resource — before writing anything.
        // Otherwise load the fixture, insert every region that is not already in
        // "Region Setup" (never touch existing records), and return how many
        // records you inserted.
    end;
}
