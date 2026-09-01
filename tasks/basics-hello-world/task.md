# Hello, World!

Every AL journey starts with a codeunit. Write one that greets the world — and anyone else who introduces themselves.

## Requirements

Create a **codeunit** named `"Hello World"` with a public procedure:

```al
procedure Greet(Name: Text): Text
```

Rules:

- When `Name` is empty (`''`), return exactly `Hello, World!`.
- Otherwise return `Hello, <Name>!` — for example, `Greet('Taylor')` returns `Hello, Taylor!`.

## What the tests check

The grading tests call `Greet` with an empty string, a fixed name, and a randomly generated name, and compare the result exactly — note the comma, the space, and the exclamation mark.

## Learn More

- [Codeunit object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object)
- [Working with AL methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods)
- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)
- [Programming in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-programming-in-al)
- [Get started with AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started)
