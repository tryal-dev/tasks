codeunit 50100 "Credential Resolver"
{
    procedure SetProviders(NewPrimaryProvider: Interface "Secret Provider v2"; NewFallbackProvider: Interface "Secret Provider v2")
    begin
        // TODO: remember both providers — every later lookup must go through them.
    end;

    procedure Resolve(SecretName: Text): SecretText
    begin
        // TODO: return the resolved secret, or raise the missing-secret error.
    end;

    procedure TryResolve(SecretName: Text; var SecretValue: SecretText): Boolean
    begin
        // TODO: report whether a provider could supply the secret, without ever erroring.
    end;
}
