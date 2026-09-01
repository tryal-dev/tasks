# A Module Secret Vault

Your extension talks to an external service, and the API key has to live somewhere better than a setup table — setup tables are readable by anyone with table permissions and travel along in configuration exports. Business Central ships Isolated Storage for exactly this: a key/value store that other extensions cannot read. You are building the small vault codeunit the rest of your extension will go through, so nobody else ever touches the storage API directly.

## Requirements

Create a **codeunit** named `"Module Secret Vault"` with five public procedures:

```al
procedure SetSecret(SecretKey: Text; SecretValue: Text)
procedure GetSecret(SecretKey: Text): Text
procedure TryGetSecret(SecretKey: Text; var SecretValue: Text): Boolean
procedure HasSecret(SecretKey: Text): Boolean
procedure DeleteSecret(SecretKey: Text)
```

Rules:

1. `SetSecret` stores `SecretValue` under `SecretKey` in Isolated Storage at `DataScope::Module`. The tests read that exact storage and scope directly — the value must genuinely land there, not in a variable of your codeunit.
2. Setting a key that already holds a value replaces it: the next read returns the new value.
3. An empty `SecretValue` is rejected with an error, and the error message must contain the offending `SecretKey`. A rejected set must leave whatever was stored under that key beforehand untouched — validate before you touch the storage.
4. `GetSecret` returns the value stored under `SecretKey`; when nothing is stored there, it raises an error with a message that contains the requested `SecretKey`.
5. `TryGetSecret` never raises an error: it returns `true` and fills `SecretValue` when the key exists, and returns `false` with an empty `SecretValue` when it does not — even if the caller passed in a var parameter that already held a value.
6. `HasSecret` returns whether a value is currently stored under `SecretKey`.
7. `DeleteSecret` removes the entry so the key no longer exists in the storage. Deleting a key that was never set is a no-op, never an error.
8. Graded keys are short non-empty texts — you do not need to validate `SecretKey` itself.

Recommended hygiene (only its side effects are graded): remove an existing entry before writing the new one. A key that switches between encrypted and plain storage can otherwise misbehave — the habit costs one line. What the tests can observe is the contract above: overwrites succeed, and a rejected set never destroys the old value.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

The grading tests round-trip a randomly generated value through `SetSecret`/`GetSecret`, verify with a direct Isolated Storage read that the value really sits at `DataScope::Module`, and seed an entry into that storage behind your codeunit's back expecting `GetSecret` to find it. They overwrite a key and expect the second value, attempt an empty-value set with `asserterror` expecting the message to contain the key and the previously stored value to survive, and read a missing key expecting an error naming it. `TryGetSecret` is checked in both directions — including that a var parameter holding an old value comes back empty on a miss. `HasSecret` is checked before and after storing, and `DeleteSecret` must make the entry vanish from Module-scope storage, while deleting a never-set key must pass without any error.

## Learn More

- [Isolated Storage](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-isolated-storage) — what the store is, how extensions are isolated, and the operations it supports.
- [IsolatedStorage data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type) — the full method list with signatures and return values.
- [DataScope option type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datascope/datascope-option) — the four scopes and what each isolates by.
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling) — raising errors and writing messages users can act on.
