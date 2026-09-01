# Range, List and Not-Blank Lookups

Your team's sales dashboard needs three small lookups over the `Customer` table: how many customers live in a city, how many live in either of two cities, and how many in a city can actually be emailed. Each one is a single filtered count — the exercise is choosing the right filter for each question.

## Requirements

Create a **codeunit** named `"Customer Lookup"` with three public procedures:

```al
procedure CountInCity(CityName: Text): Integer
procedure CountInEitherCity(FirstCity: Text; SecondCity: Text): Integer
procedure CountWithEmailInCity(CityName: Text): Integer
```

Rules:

1. `CountInCity` returns how many `Customer` records have a `City` equal to `CityName` — the whole value, exactly. A city that merely starts with the searched text (searching `North` must not count a customer in `Northport`) does not count.
2. `CountInEitherCity` returns how many customers have a `City` equal to `FirstCity` **or** equal to `SecondCity`. Each customer counts once — calling it with the same city in both parameters returns that city's count, not double.
3. `CountWithEmailInCity` returns how many customers have a `City` equal to `CityName` (same exact-city rule as above) **and** a non-blank `"E-Mail"` field.
4. The city names and emails the tests pass and seed are plain letters, digits and spaces — no filter-syntax characters to worry about in this task.
5. A lookup that finds nothing returns 0; none of the procedures may raise an error.

## What the tests check

The grading tests seed customers into freshly invented city names (some generated at run time, so the counts can't be hardcoded), always next to decoy customers in other cities, and assert **exact counts**. Every procedure is tested next to a decoy city that merely starts with a searched name (Northport next to North), so the exact-city rule is graded in all three lookups. `CountInEitherCity` additionally faces a decoy whose city name sorts between the two searched names, is called once with the two cities swapped, and once with the same city in both parameters. The email tests mix blank and filled `"E-Mail"` values inside one city and plant emailable decoys in other cities. The tests run in a real company that already contains customers — the seeded city names carry unique markers, and your counts must be driven purely by the rules above.

## Learn More

- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method)
- [Record.SetFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method)
- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods)
- [Record.Count Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-count-method)
