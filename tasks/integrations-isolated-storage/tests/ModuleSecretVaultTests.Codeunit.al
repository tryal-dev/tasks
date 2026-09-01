codeunit 50900 "Module Secret Vault Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetThenGetRoundTripsAGeneratedValue()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretValue: Text;
    begin
        // [SCENARIO] A stored secret comes back exactly as it went in
        SecretValue := Any.AlphanumericText(50);

        Vault.SetSecret('TRYAL-VAULT-ROUNDTRIP', SecretValue);

        Assert.AreEqual(SecretValue, Vault.GetSecret('TRYAL-VAULT-ROUNDTRIP'),
            'Expected GetSecret to return exactly the value SetSecret stored under the same key');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetStoresTheSecretInModuleScopeStorage()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
        StoredValue: Text;
    begin
        // [SCENARIO] The vault writes to real Isolated Storage at DataScope::Module, not to a variable of its own
        Vault.SetSecret('TRYAL-VAULT-SCOPE', 'scope-check-value');

        Assert.IsTrue(IsolatedStorage.Contains('TRYAL-VAULT-SCOPE', DataScope::Module),
            'Expected SetSecret to place the entry in Isolated Storage at DataScope::Module — a direct read of that storage found nothing under the key');
        IsolatedStorage.Get('TRYAL-VAULT-SCOPE', DataScope::Module, StoredValue);
        Assert.AreEqual('scope-check-value', StoredValue,
            'Expected the exact value to sit in Module-scope Isolated Storage under the key');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetReadsASecretSeededDirectlyIntoModuleStorage()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A secret written to Module-scope storage by someone else is visible through the vault
        IsolatedStorage.Set('TRYAL-VAULT-SEEDED', 'seeded-by-test', DataScope::Module);

        Assert.AreEqual('seeded-by-test', Vault.GetSecret('TRYAL-VAULT-SEEDED'),
            'Expected GetSecret to read the real Module-scope Isolated Storage — the test seeded this entry directly, bypassing the vault');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetOverwritesAnExistingSecret()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Setting a key that already holds a value replaces it
        Vault.SetSecret('TRYAL-VAULT-OVERWRITE', 'first value');

        Vault.SetSecret('TRYAL-VAULT-OVERWRITE', 'second value');

        Assert.AreEqual('second value', Vault.GetSecret('TRYAL-VAULT-OVERWRITE'),
            'Expected the second SetSecret on the same key to replace the first value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetWithEmptyValueRaisesAnErrorNamingTheKey()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] An empty secret value is rejected with an error that contains the key
        asserterror Vault.SetSecret('TRYAL-VAULT-EMPTY', '');

        Assert.ExpectedError('TRYAL-VAULT-EMPTY');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RejectedEmptyValueKeepsTheExistingSecret()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A rejected set leaves the previously stored value untouched
        Vault.SetSecret('TRYAL-VAULT-KEEP', 'survivor');
        // Isolated Storage writes are transactional: the refused set rolls the database back to
        // the last commit, which would take the stored value with it.
        Commit();

        asserterror Vault.SetSecret('TRYAL-VAULT-KEEP', '');

        Assert.ExpectedError('TRYAL-VAULT-KEEP');
        Assert.AreEqual('survivor', Vault.GetSecret('TRYAL-VAULT-KEEP'),
            'Expected a rejected empty-value set to leave the previously stored secret untouched — validate before touching the storage');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetMissingSecretRaisesAnErrorNamingTheKey()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Reading a key that was never set fails with an error that contains the key
        asserterror Vault.GetSecret('TRYAL-VAULT-MISSING');

        Assert.ExpectedError('TRYAL-VAULT-MISSING');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryGetReturnsTrueAndTheValueForAStoredSecret()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedValue: Text;
        SecretValue: Text;
    begin
        // [SCENARIO] TryGetSecret finds a stored secret and hands the value back
        ExpectedValue := Any.AlphanumericText(40);
        Vault.SetSecret('TRYAL-VAULT-TRYHIT', ExpectedValue);

        Assert.IsTrue(Vault.TryGetSecret('TRYAL-VAULT-TRYHIT', SecretValue),
            'Expected TryGetSecret to return true for a key that holds a secret');
        Assert.AreEqual(ExpectedValue, SecretValue,
            'Expected TryGetSecret to fill SecretValue with the stored value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryGetReturnsFalseAndClearsTheValueForAMissingKey()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
        SecretValue: Text;
    begin
        // [SCENARIO] TryGetSecret misses without erroring and leaves no stale value behind
        SecretValue := 'stale caller junk';

        Assert.IsFalse(Vault.TryGetSecret('TRYAL-VAULT-TRYMISS', SecretValue),
            StrSubstNo('Expected TryGetSecret to return false for a key that was never set, got value %1', SecretValue));
        Assert.AreEqual('', SecretValue,
            'Expected TryGetSecret to leave SecretValue empty on a miss — even when the caller passed the var parameter in dirty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasSecretIsTrueForAStoredSecret()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] HasSecret sees a secret the vault stored
        Vault.SetSecret('TRYAL-VAULT-HAS', 'present');

        Assert.IsTrue(Vault.HasSecret('TRYAL-VAULT-HAS'),
            'Expected HasSecret to return true right after SetSecret stored a value under the key');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasSecretIsFalseForAKeyNeverSet()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] HasSecret reports absence without erroring
        Assert.IsFalse(Vault.HasSecret('TRYAL-VAULT-NEVER'),
            'Expected HasSecret to return false for a key that was never set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteRemovesTheSecretFromModuleStorage()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A deleted secret is gone from the underlying Module-scope storage
        Vault.SetSecret('TRYAL-VAULT-DELETE', 'to be removed');

        Vault.DeleteSecret('TRYAL-VAULT-DELETE');

        Assert.IsFalse(IsolatedStorage.Contains('TRYAL-VAULT-DELETE', DataScope::Module),
            'Expected DeleteSecret to remove the entry from Module-scope Isolated Storage — a direct read still finds it');
        Assert.IsFalse(Vault.HasSecret('TRYAL-VAULT-DELETE'),
            'Expected HasSecret to return false after the secret was deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingAKeyNeverSetDoesNotRaiseAnError()
    var
        Vault: Codeunit "Module Secret Vault";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Deleting a missing key is a silent no-op
        Vault.DeleteSecret('TRYAL-VAULT-GHOST');

        Assert.IsFalse(Vault.HasSecret('TRYAL-VAULT-GHOST'),
            'Expected the key to remain absent after deleting it while it never existed');
    end;
}
