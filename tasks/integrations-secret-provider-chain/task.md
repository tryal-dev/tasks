# Credentials Behind an Interface

An integration codeunit that reaches into a key vault — or a setup table, or Isolated Storage — on its own is a codeunit you cannot test offline and cannot repoint later. Business Central's Secrets module already publishes the abstraction to depend on instead: `Interface "Secret Provider v2"`, implemented by the app key vault provider, by an in-memory provider, and by anything you care to write yourself. You are building the small resolver that every integration in your extension will ask for its credentials: it is handed a primary provider and a fallback provider, and it never learns where either of them keeps its secrets.

## Requirements

Create a **codeunit** named `"Credential Resolver"` with three public procedures:

```al
procedure SetProviders(NewPrimaryProvider: Interface "Secret Provider v2"; NewFallbackProvider: Interface "Secret Provider v2")
procedure Resolve(SecretName: Text): SecretText
procedure TryResolve(SecretName: Text; var SecretValue: SecretText): Boolean
```

Rules:

1. `SetProviders` hands the resolver the two providers every later lookup must go through. Calling it a second time replaces both: the pair from an earlier call must never be consulted again. The tests always call it before asking for a secret, so you do not have to handle a resolver that was never given any providers.
2. A lookup asks the primary provider first, and asks the fallback provider only for what the primary could not supply. Each provider is asked at most once per lookup, and when the primary answers, the fallback is not touched at all.
3. A provider fails to supply a secret when it reports failure — and also when it reports success but hands back a secret with no content at all. Both cases move on down the chain.
4. `Resolve` returns the resolved secret. When neither provider can supply it, `Resolve` raises an error with a message that contains the requested `SecretName` and no secret value of any kind.
5. `TryResolve` answers the same question without ever raising an error: `true` with the secret in `SecretValue` when the chain found it, `false` when it did not — and on `false`, `SecretValue` comes back empty even when the caller passed in a variable that already held something.
6. The credential must never leave the `SecretText` world. `Interface "Secret Provider v2"` declares two `GetSecret` overloads that differ only in the type of their `var` parameter, and the plain-`Text` one is off limits here: the providers the tests inject count every call to it, and one graded test fails unless that count is zero. That overload is also deliberately poisoned — it reports success for every name and hands back a marker value instead of a real secret — so a submission that takes the plain-`Text` route fails more than one test.
7. The name you are given is the name the providers get asked for — no prefixing, no case folding, no trimming. Graded secret names are short non-empty texts, so you do not need to validate `SecretName` itself.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

The grading tests hand your resolver two task-owned `Interface "Secret Provider v2"` implementations that record how they were consulted, plus Microsoft's own `Codeunit "In Memory Secret Provider"` where the value has to come from something you cannot special-case. They resolve a randomly generated name that the primary provider holds and expect a non-empty secret back after exactly one consultation; they check that a primary hit leaves the fallback at zero consultations, that a primary miss falls through to the fallback, that the name reaches the provider character for character, and that a provider answering success-with-nothing counts as a miss so the fallback still gets its turn. Neither provider may ever see a call to the plain-`Text` overload of `GetSecret`. For a name no provider holds, `asserterror` expects an error whose `GetLastErrorText` contains that name — while a second test, with a different secret loaded into the provider, expects the message to contain neither that secret's value nor the marker value the plain-`Text` overload hands out. `TryResolve` is checked in both directions, including that a miss empties a var parameter the test deliberately passed in dirty, and a last test calls `SetProviders` twice and expects the first pair never to be consulted again.

## Learn More

- [Interfaces in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al) — declaring variables of an interface type and passing an implementation where an interface is expected.
- [Using key vault secrets in Business Central extensions](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-key-vault) — the Secrets module this interface belongs to, and why it matters who you hand a secret provider to.
- [Protecting sensitive values with the SecretText data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-secret-text) — what a `SecretText` accepts, what it refuses to hand back, and why the plain-`Text` route is the one to avoid.
- [SecretText data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/secrettext/secrettext-data-type) — the very short method list of the type your resolver returns.
