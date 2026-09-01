# Classify Your Fields

Every ISV shipping to AppSource does this chore by hand: after declaring `DataClassification` on each field, someone still has to record what each field means for *privacy* — Normal, Personal, Sensitive or Company Confidential — so that a customer's admin can answer a data-subject request without guessing. Business Central keeps those answers in the **Data Sensitivity** table, one row per company, table and field, and the **Data Classification Worksheet** is where an admin reads them.

Your extension ships two tables. Automate the chore for them.

## What you start with

The starter holds three files, and your submission must contain all three: the two tables and the codeunit you fill in.

Table `"Loyalty Member"`:

| Field | `DataClassification` | Data sensitivity your code must record |
|---|---|---|
| `"Member No."` | `CustomerContent` | Normal |
| `"Full Name"` | `EndUserIdentifiableInformation` | Personal |
| `"E-Mail"` | `EndUserIdentifiableInformation` | Personal |
| `"Health Notes"` | `EndUserIdentifiableInformation` | Sensitive |
| `"Loyalty Discount"` | `CustomerContent` | Company Confidential |
| `"Visit Count"` (FlowField) | — | no row at all |

Table `"Loyalty Visit"`:

| Field | `DataClassification` | Data sensitivity your code must record |
|---|---|---|
| `"Entry No."` | `CustomerContent` | Normal |
| `"Member No."` | `CustomerContent` | Normal |
| `"Visit Date"` | `CustomerContent` | Normal |
| `Amount` | `CustomerContent` | Company Confidential |
| `"Device Id"` | `EndUserPseudonymousIdentifiers` | Personal |
| `"Partner Store Code"` | `OrganizationIdentifiableInformation` | Company Confidential |

Leave both tables exactly as they are: the grading tests look every field up by name, and the classifications above are what the exercise turns on — one test reads the shipped `DataClassification` values and the `"Visit Count"` FlowField back out of the metadata and fails if you changed them.

## Requirements

Create a **codeunit** named `"Loyalty Data Classification"` with two public procedures:

```al
procedure ClassifyTable(TableNo: Integer): Boolean
procedure ClassifyField(TableNo: Integer; FieldNo: Integer; Sensitivity: Text)
```

Rules:

1. `ClassifyTable` records the sensitivities listed above for every field of the given table and returns `true`. That is the whole chore for one table: put every stored field of your own on the plain Normal baseline first, then override the fields that deserve more than Normal.
2. `ClassifyTable` returns `false` and records nothing when the table number is not a supported table — a number no table object uses — and also when it belongs to a table your extension does not own. `Customer` is not yours to classify.
3. `ClassifyField` records `Sensitivity` for a single field. The tests pass exactly one of `'Normal'`, `'Sensitive'`, `'Personal'` and `'Company Confidential'`, and expect the field to end up with that sensitivity whether or not it already had a row.
4. `ClassifyField` raises an error when the table has no field with that number. The message must contain `Field <field number> does not exist in table <table number>`, with the two numbers rendered the way `%1` and `%2` render an Integer.
5. Running `ClassifyTable` a second time on a table it already classified must not fail, and must leave the same sensitivities behind. This chore gets re-run after every release.
6. The `"Visit Count"` FlowField and the platform's own system fields (`SystemId` and friends) must end up with **no** Data Sensitivity row. A FlowField stores nothing, and the system fields are the platform's, not yours to classify.

Two things that cost time when nobody says them out loud:

- The `Data Sensitivity` table is `Scope = OnPrem`, so an extension cannot declare `Record "Data Sensitivity"` at all — it does not compile. Everything you need is on `Codeunit "Data Classification Mgt."` in the System Application.
- That codeunit's `SetTableFieldsToNormal` looks like the baseline you want, but it is not: the system fields carry the table-level `DataClassification` (`CustomerContent` on both tables), so the routine puts `SystemId` and friends on Normal along with everything else — and nothing in the codeunit deletes a row again. Build the baseline yourself from `Record "Field"`: `RecordRef.SystemIdNo()` is the first system field number, so every field below it is yours. The per-field `SetFieldTo...` procedures update an existing row and insert a missing one, which makes them both the baseline and the override — `"Partner Store Code"` is `OrganizationIdentifiableInformation`, and it still has to come out as Company Confidential.

Pick object IDs in the range 50100–50199, and reference every object **by name**, never by a literal ID.

## What the tests check

The grading tests call `ClassifyTable` for each table — expecting `true` from both — and read the resulting rows back through the **Data Classification Worksheet** page, asserting the sensitivity of every field in the two tables above one by one, including that the FlowField and `SystemId` produce no row, and that no row of either table is left Unclassified. Two tests read the two tables' own metadata and expect the shipped `DataClassification` values and the `"Visit Count"` FlowField to be untouched. One test classifies the same table twice and expects the second run to succeed with the same result. One passes a table number that no object uses and expects `false`; one passes `Customer` and expects `false` plus an unchanged Customer classification. `ClassifyField` is exercised once per sensitivity name on the same field, once on a field that already carries a sensitivity, and once with a field number that does not exist, where the error message is matched as a substring. Captions and tooltips are not graded.

## Learn More

- [Classifying data sensitivity fields](https://learn.microsoft.com/en-us/dynamics365/business-central/admin-classifying-data-sensitivity) — what Normal, Personal, Sensitive and Confidential actually mean to the admin reading your rows.
- [Business Central privacy for AL developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/security/privacy-developers) — why an extension is expected to classify its own data model.
- [AppSourceCop Error AS0016](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0016) — the AppSource rule behind the chore, and the reason FlowFields are always SystemMetadata.
- [System fields](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields) — the fields the platform adds to every table, the ones your classification must leave alone.
