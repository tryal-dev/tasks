codeunit 50100 "Module Secret Vault"
{
    procedure SetSecret(SecretKey: Text; SecretValue: Text)
    begin
        // TODO: reject an empty SecretValue with an error naming SecretKey, then store the value at DataScope::Module.
    end;

    procedure GetSecret(SecretKey: Text): Text
    begin
        // TODO: return the stored value, or raise an error naming SecretKey when nothing is stored under it.
    end;

    procedure TryGetSecret(SecretKey: Text; var SecretValue: Text): Boolean
    begin
        // TODO: return true and fill SecretValue when the key exists; false and an empty SecretValue otherwise.
    end;

    procedure HasSecret(SecretKey: Text): Boolean
    begin
        // TODO: return whether a secret is currently stored under SecretKey.
    end;

    procedure DeleteSecret(SecretKey: Text)
    begin
        // TODO: remove the secret; deleting a key that was never set is a no-op.
    end;
}
