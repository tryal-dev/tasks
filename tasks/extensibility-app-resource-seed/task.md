# Setup Data Ships in the App

Your extension needs its reference data — sales regions with their tax rates — available the moment it is installed, in every company, with no manual entry. Since Business Central 2024 release wave 2, the idiomatic answer is to ship that data inside the app itself: declare `resourceFolders` in `app.json`, put a JSON fixture in the folder, and read it at runtime with `NavApp.ListResources` and `NavApp.GetResourceAsJson`. The seeding routine must be idempotent — installs, reruns, and upgrades may call it any number of times without duplicating rows or overwriting values an administrator changed.

One platform note: submissions here consist of `.al` files only and the platform generates `app.json` for you, so a real resource file cannot ship with your app. The provided `"App Resource Store"` codeunit therefore stands in for the NavApp API with the same shapes — `ListResources(): List of [Text]` and `GetResourceAsJson(ResourceName: Text): JsonObject`. Write your code against it exactly as you would against `NavApp`.

## Requirements

The starter ships three objects. Do not change the `"Region Setup"` table or the `"App Resource Store"` codeunit — the tests rely on both exactly as given. Your work is the body of the codeunit named `"Setup Seeder"` with this public procedure:

```al
procedure SeedFromResource(ResourceName: Text): Integer
```

Rules:

1. If `ResourceName` is not one of the resources the store ships, raise an error **before writing anything**. The error message must contain the requested name and the name of every shipped resource, so whoever hits it can see what is available.
2. Otherwise load the resource as JSON. Every fixture is an object with a `regions` array; each element carries `code`, `description`, and `taxRate`.
3. For every region not yet in `"Region Setup"`, insert a record: `code` fills `"Code"`, `description` fills `Description`, `taxRate` fills `"Tax Rate"`.
4. Regions that already exist are left completely untouched — a rerun must never overwrite a description or tax rate an administrator edited after the first seeding, and must never duplicate a row.
5. Return the number of records actually inserted — the full fixture count on a first run, `0` on an identical rerun, and exactly the number of missing regions on a partial one.

## What the tests check

The tests seed each shipped fixture by name and compare the resulting `"Region Setup"` rows field by field against the fixture contents — exact descriptions and tax rates included. They run the seeder twice (expecting `0` and no duplicates), edit a record and reseed (expecting the edits to survive), delete a record and reseed (expecting only that one back, return value `1`), seed both fixtures into one table, and call the seeder with a name that never shipped (expecting an error that contains the requested name and both shipped names, with the table left empty). Pick object IDs in 50100–50199 and reference other objects by name, never by ID.

## Learn More

- [Adding and accessing resources in Business Central extensions](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-resources) — the real-world pattern this task practices: `resourceFolders` plus the NavApp resource methods.
- [NavApp.GetResourceAsJson method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-getresourceasjson-method) — the production counterpart of the store's `GetResourceAsJson`.
- [NavApp.ListResources method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-listresources-method) — the production counterpart of the store's `ListResources`.
- [JsonObject data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type) — the container `GetResourceAsJson` hands you.
