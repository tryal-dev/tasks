# Parse XML That Has Namespaces

Your company just went live with the FreightEx carrier network, and their gateway pushes a shipment status message — an XML document — after every package scan.

The previous developer's parser worked perfectly against the sandbox samples; then production traffic arrived and every field started coming back empty: no errors, no crashes, just nothing found. The difference is one attribute at the top of the message — the sandbox samples carried no namespace declarations, production messages do, and the FreightEx spec says they are entirely within their rights to.

## The message

A typical production message:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ShipmentStatus xmlns="urn:tryal:freight:shipping:v2">
  <Header>
    <ShipmentNo>SHP-10412</ShipmentNo>
  </Header>
  <Packages>
    <Package>
      <trk:TrackingNo xmlns:trk="urn:tryal:freight:tracking:v1">1Z-00443-7</trk:TrackingNo>
      <Weight unit="kg">12.5</Weight>
    </Package>
    <Package>
      <trk:TrackingNo xmlns:trk="urn:tryal:freight:tracking:v1">1Z-00443-8</trk:TrackingNo>
      <Weight unit="kg">3.25</Weight>
    </Package>
  </Packages>
</ShipmentStatus>
```

What the FreightEx spec guarantees — and nothing more:

- The elements `ShipmentStatus`, `Header`, `ShipmentNo`, `Packages`, `Package` and `Weight` belong to the namespace `urn:tryal:freight:shipping:v2`.
- The element `TrackingNo` belongs to the namespace `urn:tryal:freight:tracking:v1`.
- Namespace **prefixes are the sender's choice** and change between messages: either namespace may appear under any prefix, or as a default (`xmlns="..."`) declaration, on any element. Only the two URIs above carry stable identity.
- The `unit` attribute on `Weight` never carries a prefix.
- Messages may also carry elements from **other partners' namespaces** — sometimes with the very same local names (`ShipmentNo`, `Package`, `TrackingNo`) — anywhere in the document, including inside `Packages`. They are not yours and must be ignored.
- Shipping-namespace `Package` elements appear only inside `Packages`; `Header` and `Packages` each appear at most once, directly under the root.
- Every message is well-formed XML, and element content is plain text.

## Requirements

Create a **codeunit** named `"Shipment Status Parser"` with four public procedures:

```al
procedure GetShipmentNo(XmlPayload: Text): Text
procedure CountPackages(XmlPayload: Text): Integer
procedure GetTrackingNumbers(XmlPayload: Text): List of [Text]
procedure GetWeightUnit(XmlPayload: Text): Text
```

Rules:

1. `GetShipmentNo` returns the text content of the shipping-namespace `ShipmentNo` element inside `Header`; `''` if the message has none.
2. `CountPackages` returns how many shipping-namespace `Package` elements the message contains; `0` for an empty shipment.
3. `GetTrackingNumbers` returns the text content of every tracking-namespace `TrackingNo` element, in document order; an empty list when there are none.
4. `GetWeightUnit` returns the value of the first `unit` attribute found on a shipping-namespace `Weight` element, in document order; `''` when no `Weight` carries one (or there is no `Weight` at all).
5. Elements with the right local name but the wrong namespace never count, are never returned, and never mask the real ones.
6. None of the procedures may raise an error on a message that satisfies the spec above.

## What the tests check

The grading tests feed your parser generated messages: with the shipping namespace declared as default and declared under a prefix, with the tracking namespace under changing prefixes (including a default declaration placed directly on `TrackingNo`), with foreign-namespace `ShipmentNo`/`Package`/`TrackingNo`/`Weight` decoys under the root and inside `Packages` (including a foreign `Weight` carrying its own `unit` attribute ahead of the real one), with a unit-less shipping `Weight` placed before one that carries the `unit`, and with shipment numbers, counts, tracking numbers and units randomized so pattern-matching the sample above cannot pass. Comparisons and counts are exact — over-matching a decoy fails just as hard as finding nothing. The empty cases are graded too: a missing `ShipmentNo`, an empty shipment, tracking-free packages and a `Weight` without a `unit` must come back as `''`, `0` or an empty list — never as an error.

## Learn More

- [XmlNamespaceManager data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnamespacemanager/xmlnamespacemanager-data-type)
- [XmlDocument.ReadFrom(Text, var XmlDocument) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-readfrom-string-xmldocument-method)
- [XmlDocument.SelectNodes(Text, XmlNamespaceManager, var XmlNodeList) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-selectnodes-string-xmlnamespacemanager-xmlnodelist-method)
- [XmlElement.SelectNodes(Text, XmlNamespaceManager, var XmlNodeList) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-selectnodes-string-xmlnamespacemanager-xmlnodelist-method)
- [XmlNode data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnode/xmlnode-data-type)
