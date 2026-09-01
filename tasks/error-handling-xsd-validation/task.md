# Validate Against the Schema

Your company receives order confirmations from a partner portal as XML. Last month a malformed message crashed the nightly import halfway through; last week a message that parsed fine but broke the agreed structure imported garbage instead. The new rule: every payload passes a gate before any import logic sees it — and when a message is rejected, support wants to read *why* in the log, not just "invalid".

## The contract

Inbound messages must obey this XSD (namespace `urn:tryal:orders`):

```xml
<?xml version="1.0" encoding="utf-8"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:tryal:orders" elementFormDefault="qualified">
  <xsd:element name="Order">
    <xsd:complexType>
      <xsd:sequence>
        <xsd:element name="OrderNo" type="xsd:string" />
        <xsd:element name="Quantity" type="xsd:int" />
      </xsd:sequence>
    </xsd:complexType>
  </xsd:element>
</xsd:schema>
```

A valid message looks like this — and the sender may just as well declare the namespace under a prefix (`<po:Order xmlns:po="urn:tryal:orders">…`) instead of as the default; both are the same document:

```xml
<Order xmlns="urn:tryal:orders"><OrderNo>SO-1001</OrderNo><Quantity>3</Quantity></Order>
```

The partner guarantees that whenever a message parses as XML at all, its root is an `Order` element in the namespace `urn:tryal:orders`. What still goes wrong — and what your gate must catch — is payloads that do not parse as XML at all, and parseable orders whose content breaks the schema: an element the schema does not allow, a missing required element, or a `Quantity` that is not an integer.

## Requirements

The starter ships two objects. Keep the enum `"Xml Verdict"` (values `Valid`, `NotWellFormed`, `SchemaInvalid`) and the given `SchemaText()` / `SchemaNamespace()` procedures exactly as they are — the tests bind to the enum by name, and rewriting the embedded schema changes what "valid" means.

Implement `Validate` in the **codeunit** named `"Inbound Xml Validation"`:

```al
procedure Validate(XmlPayload: Text; var Diagnostic: Text): Enum "Xml Verdict"
```

Rules:

1. If `XmlPayload` is not well-formed XML — plain text, an empty string, a mismatched closing tag — return `NotWellFormed` and leave `Diagnostic` empty.
2. If it is well-formed but breaks the schema, return `SchemaInvalid` and put the violation text into `Diagnostic`. That text must name the offending piece: the unexpected element's name, the missing element's name, or the rejected `Quantity` value. The message a schema validator produces does this on its own — you are not expected to compose these sentences yourself.
3. If it satisfies the schema, return `Valid` and leave `Diagnostic` empty.
4. `Validate` must never raise an error, whatever the payload contains.
5. `Diagnostic` describes only the current call: whatever the caller's variable held before the call — including the text of an earlier failed validation — must be gone afterwards.

## What the tests check

Randomized valid orders — with the namespace declared as default and under a prefix — must come back `Valid` with an empty `Diagnostic`. Generated plain text, an empty payload and a mismatched closing tag must come back `NotWellFormed` with an empty `Diagnostic`. Schema violations are graded with randomized offenders: an extra element with a generated name (`Diagnostic` must contain that name), an order missing `Quantity` (`Diagnostic` must contain `Quantity`), and a `Quantity` holding generated alphabetic text (`Diagnostic` must contain exactly that text). Two tests validate a broken order and then a second payload through the same `Diagnostic` variable — once a valid order, once plain text — and the stale text must not survive the second call in either. Verdicts are compared exactly, and an error raised by any `Validate` call fails that test.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## Learn More

- [XmlDocument.ReadFrom(Text, var XmlDocument) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-readfrom-string-xmldocument-method) — the polite way to find out whether text parses as XML at all.
- [Handling errors using try methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods) — how AL catches a raised error and reads its text afterwards.
- [XML schema (XSD) validation with XmlSchemaSet](https://learn.microsoft.com/en-us/dotnet/standard/data/xml/xml-schema-xsd-validation-with-xmlschemaset) — the validation semantics underneath: what a schema violation is and how validators report it.
- [Handle errors by using application language in Dynamics 365 Business Central](https://learn.microsoft.com/en-us/training/modules/handle-errors/) — training module covering the whole catch-and-report toolbox.
