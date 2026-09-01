codeunit 50900 "Credential Resolver Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolvesTheSecretFromThePrimaryProvider()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
        Resolved: SecretText;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(12);
        PrimaryProviderSpy.SetSecret(SecretName, Any.AlphabeticText(24));
        CredentialResolver.SetProviders(PrimaryProviderSpy, FallbackProviderSpy);

        Resolved := CredentialResolver.Resolve(SecretName);

        Assert.IsFalse(Resolved.IsEmpty(),
            StrSubstNo('Expected Resolve to hand back the secret the primary provider holds for %1, but the returned SecretText was empty', SecretName));
        Assert.AreEqual(1, PrimaryProviderSpy.TimesConsulted(),
            'Expected Resolve to consult the primary provider exactly once for one lookup');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoesNotConsultTheFallbackWhenThePrimaryAnswers()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        InMemorySecretProvider: Codeunit "In Memory Secret Provider";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(12);
        InMemorySecretProvider.AddSecret(SecretName, Any.AlphabeticText(24));
        CredentialResolver.SetProviders(InMemorySecretProvider, FallbackProviderSpy);

        CredentialResolver.Resolve(SecretName);

        Assert.AreEqual(0, FallbackProviderSpy.TimesConsulted(),
            'Expected the fallback provider to be left untouched when the primary provider already supplied the secret');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FallsBackToTheSecondProviderWhenThePrimaryHasNothing()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        InMemorySecretProvider: Codeunit "In Memory Secret Provider";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
        Resolved: SecretText;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(12);
        InMemorySecretProvider.AddSecret(SecretName, Any.AlphabeticText(24));
        CredentialResolver.SetProviders(PrimaryProviderSpy, InMemorySecretProvider);

        Resolved := CredentialResolver.Resolve(SecretName);

        Assert.IsFalse(Resolved.IsEmpty(),
            StrSubstNo('Expected Resolve to fall through to the fallback provider for %1 when the primary provider has no such secret', SecretName));
        Assert.AreEqual(1, PrimaryProviderSpy.TimesConsulted(),
            'Expected the primary provider to be asked first - the fallback is only for what the primary could not supply');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AsksTheProvidersForTheExactSecretName()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(15);
        PrimaryProviderSpy.SetSecret(SecretName, Any.AlphabeticText(24));
        CredentialResolver.SetProviders(PrimaryProviderSpy, FallbackProviderSpy);

        CredentialResolver.Resolve(SecretName);

        Assert.AreEqual(SecretName, PrimaryProviderSpy.LastRequestedSecretName(),
            'Expected the secret name to reach the provider exactly as it was passed to Resolve, unprefixed and untransformed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NeverAsksTheProvidersForAPlainTextSecret()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(12);
        FallbackProviderSpy.SetSecret(SecretName, Any.AlphabeticText(24));
        CredentialResolver.SetProviders(PrimaryProviderSpy, FallbackProviderSpy);

        CredentialResolver.Resolve(SecretName);

        Assert.AreEqual(0, PrimaryProviderSpy.TimesAskedForPlainText(),
            'Expected the primary provider to be asked through the SecretText overload of GetSecret - the plain Text overload must never be called');
        Assert.AreEqual(0, FallbackProviderSpy.TimesAskedForPlainText(),
            'Expected the fallback provider to be asked through the SecretText overload of GetSecret - the plain Text overload must never be called');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TreatsAnEmptyProviderAnswerAsAMiss()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        InMemorySecretProvider: Codeunit "In Memory Secret Provider";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
        Resolved: SecretText;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(12);
        PrimaryProviderSpy.AnswerEveryLookupWithAnEmptySecret();
        InMemorySecretProvider.AddSecret(SecretName, Any.AlphabeticText(24));
        CredentialResolver.SetProviders(PrimaryProviderSpy, InMemorySecretProvider);

        Resolved := CredentialResolver.Resolve(SecretName);

        Assert.IsFalse(Resolved.IsEmpty(),
            'Expected a provider that answers true with an empty secret to count as a miss, so the fallback provider still gets its turn');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RaisesAnErrorNamingTheSecretWhenNoProviderHasIt()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(12);
        CredentialResolver.SetProviders(PrimaryProviderSpy, FallbackProviderSpy);

        asserterror CredentialResolver.Resolve(SecretName);

        Assert.IsTrue(StrPos(GetLastErrorText(), SecretName) > 0,
            StrSubstNo('Expected the error raised for a secret no provider has to name the key %1, got: %2', SecretName, GetLastErrorText()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheMissingSecretErrorRevealsNoSecretValue()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StoredSecretValue: Text;
        MissingSecretName: Text;
        ErrorText: Text;
    begin
        Initialize();
        StoredSecretValue := Any.AlphabeticText(24);
        PrimaryProviderSpy.SetSecret('tryal-held-' + Any.AlphabeticText(8), StoredSecretValue);
        MissingSecretName := 'tryal-missing-' + Any.AlphabeticText(8);
        CredentialResolver.SetProviders(PrimaryProviderSpy, FallbackProviderSpy);

        asserterror CredentialResolver.Resolve(MissingSecretName);

        ErrorText := GetLastErrorText();
        Assert.AreEqual(0, StrPos(ErrorText, StoredSecretValue),
            StrSubstNo('Expected the missing-secret error to name the key but never a secret value, got: %1', ErrorText));
        Assert.AreEqual(0, StrPos(ErrorText, PrimaryProviderSpy.PlainTextPoison()),
            StrSubstNo('Expected the missing-secret error to carry nothing a provider handed out, got: %1', ErrorText));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryResolveReturnsTheSecretWhenAProviderHasIt()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        InMemorySecretProvider: Codeunit "In Memory Secret Provider";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
        Resolved: SecretText;
        Found: Boolean;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(12);
        InMemorySecretProvider.AddSecret(SecretName, Any.AlphabeticText(24));
        CredentialResolver.SetProviders(InMemorySecretProvider, FallbackProviderSpy);

        Found := CredentialResolver.TryResolve(SecretName, Resolved);

        Assert.IsTrue(Found,
            StrSubstNo('Expected TryResolve to report true for %1, which the primary provider holds', SecretName));
        Assert.IsFalse(Resolved.IsEmpty(),
            'Expected TryResolve to fill its var parameter with the secret it found');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryResolveReturnsFalseWhenNoProviderHasTheSecret()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Resolved: SecretText;
        Found: Boolean;
    begin
        Initialize();
        CredentialResolver.SetProviders(PrimaryProviderSpy, FallbackProviderSpy);

        Found := CredentialResolver.TryResolve(Any.AlphabeticText(12), Resolved);

        Assert.IsFalse(Found,
            'Expected TryResolve to report false - and to raise no error at all - when no provider holds the secret');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryResolveClearsTheSecretItCannotResolve()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LeftoverValue: Text;
        Resolved: SecretText;
    begin
        Initialize();
        LeftoverValue := Any.AlphabeticText(24);
        Resolved := LeftoverValue;
        CredentialResolver.SetProviders(PrimaryProviderSpy, FallbackProviderSpy);

        CredentialResolver.TryResolve(Any.AlphabeticText(12), Resolved);

        Assert.IsTrue(Resolved.IsEmpty(),
            'Expected a failed TryResolve to hand back an empty secret, even when the caller passed a var parameter that already held a value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UsesTheProvidersFromTheLatestSetProvidersCall()
    var
        CredentialResolver: Codeunit "Credential Resolver";
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
        InMemorySecretProvider: Codeunit "In Memory Secret Provider";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecretName: Text;
    begin
        Initialize();
        SecretName := Any.AlphabeticText(12);
        PrimaryProviderSpy.SetSecret(SecretName, Any.AlphabeticText(24));
        FallbackProviderSpy.SetSecret(SecretName, Any.AlphabeticText(24));
        InMemorySecretProvider.AddSecret(SecretName, Any.AlphabeticText(24));
        CredentialResolver.SetProviders(PrimaryProviderSpy, FallbackProviderSpy);
        CredentialResolver.SetProviders(InMemorySecretProvider, InMemorySecretProvider);

        CredentialResolver.Resolve(SecretName);

        Assert.AreEqual(0, PrimaryProviderSpy.TimesConsulted(),
            'Expected the second SetProviders call to replace the pair - the primary provider of the first call must never be consulted again');
        Assert.AreEqual(0, FallbackProviderSpy.TimesConsulted(),
            'Expected the second SetProviders call to replace the pair - the fallback provider of the first call must never be consulted again');
    end;

    local procedure Initialize()
    var
        PrimaryProviderSpy: Codeunit "Primary Provider Spy";
        FallbackProviderSpy: Codeunit "Fallback Provider Spy";
    begin
        // Both spies are SingleInstance, so these local variables address the very
        // instances the submission is handed - which is also why their counters
        // have to be cleared between tests.
        PrimaryProviderSpy.Reset();
        FallbackProviderSpy.Reset();
    end;
}
