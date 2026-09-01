codeunit 50100 "MCP Tool Surface"
{
    procedure EnsureConfiguration(): Guid
    begin
        // TODO: create the "TryAL Agent Surface" configuration if it is not there yet,
        // expose the three API pages as tools with the agreed permissions, activate it,
        // and return the configuration id — a second call must reuse the existing one.
    end;

    procedure RepairConfiguration(ConfigId: Guid): Integer
    begin
        // TODO: apply the recommended action to every warning Business Central reports
        // for this configuration and return how many were applied.
    end;
}
